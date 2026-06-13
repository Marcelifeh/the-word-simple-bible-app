import argparse
import json
import os
from pathlib import Path

import psycopg


def _load_env() -> None:
    # Match other tools: load server/app/.env if present.
    try:
        from dotenv import load_dotenv  # type: ignore
    except Exception:
        return

    repo_root = Path(__file__).resolve().parents[1]
    env_path = repo_root / "server" / "app" / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path, override=True)


def _db_url(explicit: str | None) -> str:
    _load_env()
    url = explicit or os.getenv("DATABASE_URL")
    if not url:
        raise SystemExit(
            "DATABASE_URL is required (set env var, create server/app/.env, or pass --database-url)"
        )

    # Tools usually accept postgresql://; psycopg accepts both.
    if url.startswith("postgresql+psycopg://"):
        url = url.replace("postgresql+psycopg://", "postgresql://", 1)
    return url


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Export generated commentary from Postgres into per-chapter Flutter assets.\n"
            "Output layout: assets/data/commentary/<style>/<translation>/<bookId>/<chapter>.json"
        )
    )
    parser.add_argument(
        "--database-url",
        default=None,
        help="Override DATABASE_URL (otherwise uses env or server/app/.env)",
    )
    parser.add_argument(
        "--out-root",
        default="assets/data/commentary",
        help="Output root folder (default: assets/data/commentary)",
    )
    parser.add_argument(
        "--style",
        default="insight_premium_v2",
        help="Commentary style to export (default: insight_premium_v2)",
    )
    parser.add_argument(
        "--translation",
        action="append",
        choices=["kjv", "web"],
        help="Translation(s) to export. Repeatable. Default: export both.",
    )
    parser.add_argument(
        "--book-id",
        default=None,
        help="Only export a single book_id (example: romans, psalms, 1_samuel)",
    )
    parser.add_argument(
        "--limit-verses",
        type=int,
        default=0,
        help="Limit number of verses exported (0 = no limit). Useful for testing.",
    )

    args = parser.parse_args()

    translations = args.translation or ["kjv", "web"]
    style = (args.style or "insight_premium_v2").strip().lower()
    out_root = Path(args.out_root) / style

    url = _db_url(args.database_url)

    where = ["c.style = %s", "v.translation = ANY(%s)"]
    params: list[object] = [style, translations]

    if args.book_id:
        where.append("v.book_id = %s")
        params.append(args.book_id.strip().lower())

    limit_sql = ""
    if args.limit_verses and args.limit_verses > 0:
        limit_sql = " LIMIT %s"
        params.append(int(args.limit_verses))

    sql = (
        "SELECT v.translation, v.book_id, v.chapter, v.verse, c.text, c.payload_json "
        "FROM verses v "
        "JOIN commentary c ON c.verse_id = v.id "
        f"WHERE {' AND '.join(where)} "
        "ORDER BY v.translation, v.book_id, v.chapter, v.verse"
        + limit_sql
    )

    out_root.mkdir(parents=True, exist_ok=True)

    # Build and flush per-chapter files.
    current_key: tuple[str, str, int] | None = None
    current_map: dict[str, object] = {}

    def flush() -> None:
        nonlocal current_key, current_map
        if current_key is None:
            return
        translation, book_id, chapter = current_key
        book_dir = out_root / translation / book_id
        book_dir.mkdir(parents=True, exist_ok=True)
        out_path = book_dir / f"{chapter}.json"
        out_path.write_text(
            json.dumps(current_map, ensure_ascii=False, separators=(",", ":")),
            encoding="utf-8",
        )
        current_map = {}

    with psycopg.connect(url) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            for translation, book_id, chapter, verse, text, payload_json in cur.fetchall():
                key = (str(translation), str(book_id), int(chapter))
                if current_key is None:
                    current_key = key
                if key != current_key:
                    flush()
                    current_key = key

                if payload_json and str(payload_json).strip():
                    try:
                        current_map[str(int(verse))] = json.loads(str(payload_json))
                        continue
                    except Exception:
                        pass

                t = (text or "").strip()
                if not t:
                    continue
                current_map[str(int(verse))] = t

    flush()

    print(f"Exported commentary assets to: {out_root.as_posix()}")


if __name__ == "__main__":
    main()
