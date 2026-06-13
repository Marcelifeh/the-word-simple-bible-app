import argparse
import json
import os
import subprocess
import sys
import urllib.request
from urllib.parse import urlparse
from pathlib import Path

import psycopg


REPO_ROOT = Path(__file__).resolve().parents[1]
SERVER_DIR = REPO_ROOT / "server"
SCHEMA_SQL = SERVER_DIR / "schema.sql"
CONVERTER = REPO_ROOT / "tools" / "convert_web_usfm_zip.py"  # works for any USFM ZIP
IMPORTER = REPO_ROOT / "tools" / "import_bible_to_postgres.py"


DEFAULT_WEB_URL = "https://ebible.org/Scriptures/eng-web_usfm.zip"
DEFAULT_KJV_URL = "https://ebible.org/Scriptures/eng-kjv_usfm.zip"


def _load_env_fallback() -> None:
    """Load server/app/.env if present (dev convenience)."""
    try:
        from dotenv import load_dotenv  # type: ignore
    except Exception:
        return

    env_path = REPO_ROOT / "server" / "app" / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path, override=True)


def _db_url(cli_url: str | None) -> str:
    _load_env_fallback()
    url = (cli_url or os.getenv("DATABASE_URL") or "").strip()
    if not url:
        raise SystemExit(
            "DATABASE_URL is required. Example:\n"
            "  postgresql://postgres:YOUR_PASSWORD@localhost:5432/bible\n"
            "You can pass --database-url or set it in server/app/.env"
        )

    # psycopg v3 uses postgresql://
    if url.startswith("postgresql+psycopg://"):
        url = url.replace("postgresql+psycopg://", "postgresql://", 1)
    return url


def _download(url: str, out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"Downloading {url} -> {out_path}", flush=True)
    urllib.request.urlretrieve(url, out_path)  # noqa: S310


def _run(cmd: list[str], cwd: Path | None = None) -> None:
    printable = " ".join(cmd)
    print(f"> {printable}", flush=True)
    res = subprocess.run(cmd, cwd=str(cwd) if cwd else None)  # noqa: S603
    if res.returncode != 0:
        raise SystemExit(f"Command failed ({res.returncode}): {printable}")


def _reset_schema(url: str) -> None:
    if not SCHEMA_SQL.exists():
        raise SystemExit(f"Missing schema file: {SCHEMA_SQL}")

    sql = SCHEMA_SQL.read_text(encoding="utf-8")

    # Ensure the database exists (nice UX for local installs).
    parsed = urlparse(url)
    db_name = (parsed.path or "").lstrip("/")
    if not db_name:
        raise SystemExit("DATABASE_URL must include a database name (e.g., .../bible)")

    def try_connect(target_url: str) -> psycopg.Connection:
        return psycopg.connect(target_url)

    try:
        conn = try_connect(url)
    except Exception as e:
        msg = str(e)
        if "does not exist" in msg and "database" in msg:
            # Connect to default 'postgres' DB and create the target DB.
            admin_path = "/postgres"
            admin_url = parsed._replace(path=admin_path).geturl()
            with try_connect(admin_url) as admin:
                admin.autocommit = True
                with admin.cursor() as cur:
                    cur.execute(f'CREATE DATABASE "{db_name}"')
            conn = try_connect(url)
        else:
            raise

    with conn:
        with conn.cursor() as cur:
            # Drop in correct order because commentary references verses.
            cur.execute("DROP TABLE IF EXISTS commentary")
            cur.execute("DROP TABLE IF EXISTS verses")
            # Recreate
            cur.execute(sql)
        conn.commit()


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Reset the local Postgres schema, re-download WEB+KJV USFM zips, convert to flat JSON, and import into Postgres."
        )
    )
    parser.add_argument(
        "--database-url",
        default=None,
        help=(
            "Postgres URL (psycopg style). Example: postgresql://postgres:PASS@localhost:5432/bible. "
            "If omitted, uses DATABASE_URL (server/app/.env supported)."
        ),
    )
    parser.add_argument("--downloads-dir", default=str(REPO_ROOT / "downloads"), help="Where to store downloaded zips/json")

    parser.add_argument("--web-url", default=DEFAULT_WEB_URL, help="WEB USFM ZIP URL")
    parser.add_argument("--kjv-url", default=DEFAULT_KJV_URL, help="KJV USFM ZIP URL")

    parser.add_argument("--skip-download", action="store_true", help="Use existing zip files in downloads dir")
    parser.add_argument("--skip-web", action="store_true", help="Skip WEB import")
    parser.add_argument("--skip-kjv", action="store_true", help="Skip KJV import")

    args = parser.parse_args()

    db_url = _db_url(args.database_url)
    downloads = Path(args.downloads_dir)
    downloads.mkdir(parents=True, exist_ok=True)

    web_zip = downloads / "eng-web_usfm.zip"
    kjv_zip = downloads / "eng-kjv_usfm.zip"

    web_json = downloads / "web_flat.json"
    kjv_json = downloads / "kjv_flat.json"

    print("\n[1/4] Resetting schema...", flush=True)
    _reset_schema(db_url)
    print("Schema reset complete.", flush=True)

    if not args.skip_download:
        print("\n[2/4] Downloading sources...", flush=True)
        if not args.skip_web:
            _download(args.web_url, web_zip)
        if not args.skip_kjv:
            _download(args.kjv_url, kjv_zip)
    else:
        print("\n[2/4] Skipping download (using existing files).", flush=True)

    print("\n[3/4] Converting USFM -> flat JSON...", flush=True)
    if not args.skip_web:
        if not web_zip.exists():
            raise SystemExit(f"Missing {web_zip}. Remove --skip-download or place the file there.")
        _run([sys.executable, str(CONVERTER), str(web_zip), str(web_json)])
    if not args.skip_kjv:
        if not kjv_zip.exists():
            raise SystemExit(f"Missing {kjv_zip}. Remove --skip-download or place the file there.")
        _run([sys.executable, str(CONVERTER), str(kjv_zip), str(kjv_json)])

    print("\n[4/4] Importing into Postgres...", flush=True)

    # Ensure importer uses our DB URL.
    os.environ["DATABASE_URL"] = db_url

    if not args.skip_web:
        _run([sys.executable, str(REPO_ROOT / "tools" / "import_bible_to_postgres.py"), "web", str(web_json)])
    if not args.skip_kjv:
        _run([sys.executable, str(REPO_ROOT / "tools" / "import_bible_to_postgres.py"), "kjv", str(kjv_json)])

    # Quick sanity check
    with psycopg.connect(db_url) as conn:
        with conn.cursor() as cur:
            cur.execute("select translation, count(*) from verses group by translation order by translation")
            rows = cur.fetchall()
    print("\nImported verse counts:", rows, flush=True)

    print("\nDone. Next: start the API and run commentary generation.", flush=True)


if __name__ == "__main__":
    main()
