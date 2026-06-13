import argparse
import os
import subprocess
import sys
import time
import json
import urllib.request
import urllib.error
from urllib.parse import urlparse
from pathlib import Path
from datetime import timedelta

import psycopg


def _load_env() -> None:
    # Prefer local dev convenience: load server/app/.env if present.
    # This keeps secrets out of code while avoiding manual $env:... setup.
    try:
        from dotenv import load_dotenv  # type: ignore
    except Exception:
        return

    repo_root = Path(__file__).resolve().parents[1]
    env_path = repo_root / "server" / "app" / ".env"
    if env_path.exists():
        load_dotenv(dotenv_path=env_path, override=True)


def _db_url() -> str:
    _load_env()
    url = os.getenv("DATABASE_URL")
    if not url:
        raise SystemExit(
            "DATABASE_URL env var is required (example: postgresql://bible:bible@localhost:5433/bible)"
        )
    if url.startswith("postgresql+"):
        url = url.replace("postgresql+psycopg://", "postgresql://")
    return url


def _spawn_api_if_requested(api_base_url: str, enabled: bool) -> subprocess.Popen[str] | None:
    if not enabled:
        return None

    parsed = urlparse(api_base_url)
    scheme = parsed.scheme or "http"
    host = parsed.hostname or "127.0.0.1"
    port = parsed.port or (443 if scheme == "https" else 80)

    if host not in {"127.0.0.1", "localhost"}:
        raise SystemExit("--spawn-api only supports api hosts of 127.0.0.1/localhost")

    repo_root = Path(__file__).resolve().parents[1]
    app_dir = repo_root / "server"

    # Use the same interpreter that is running this script.
    cmd = [
        sys.executable,
        "-m",
        "uvicorn",
        "app.main:app",
        "--app-dir",
        str(app_dir),
        "--host",
        host,
        "--port",
        str(port),
        "--log-level",
        "warning",
    ]

    return subprocess.Popen(
        cmd,
        cwd=str(app_dir),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        text=True,
    )


def _wait_for_health(api_base_url: str, timeout_seconds: float = 30.0) -> None:
    start = time.time()
    url = f"{api_base_url.rstrip('/')}/health"
    last_error: str | None = None

    while True:
        try:
            with urllib.request.urlopen(url, timeout=5) as resp:
                if 200 <= resp.status < 300:
                    return
        except Exception as e:  # noqa: BLE001
            last_error = str(e)

        if time.time() - start >= timeout_seconds:
            raise SystemExit(f"API did not become healthy at {url} within {timeout_seconds}s. Last error: {last_error}")

        time.sleep(0.25)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate structured premium commentary verse-by-verse via the API and store into Postgres."
    )
    parser.add_argument("--api", default="http://localhost:8000", help="API base URL")
    parser.add_argument(
        "--spawn-api",
        action="store_true",
        help="Start the API (uvicorn) automatically for the duration of this command",
    )
    parser.add_argument("--translation", choices=["kjv", "web"], required=True)
    parser.add_argument("--style", default="insight_premium_v2")
    parser.add_argument("--limit", type=int, default=0, help="0 = no limit")
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Regenerate and overwrite existing commentary rows (default: false)",
    )
    parser.add_argument(
        "--book-id",
        default=None,
        help="Only generate for a single book_id (example: psalms, romans, 1_samuel)",
    )
    parser.add_argument(
        "--chapter",
        type=int,
        default=None,
        help="Only generate for a single chapter (requires --book-id)",
    )
    parser.add_argument("--sleep", type=float, default=0.0, help="Seconds to sleep between requests")
    parser.add_argument(
        "--progress-every",
        type=int,
        default=25,
        help="Print progress every N verses (default: 25)",
    )
    parser.add_argument(
        "--max-429-retries",
        type=int,
        default=8,
        help="Max retries for a single verse when API returns 429 (default: 8)",
    )
    parser.add_argument(
        "--retry-after-default",
        type=float,
        default=10.0,
        help="Seconds to wait when API 429 has no Retry-After header (default: 10)",
    )

    args = parser.parse_args()

    def fmt_eta(seconds: float) -> str:
        if seconds <= 0:
            return "0s"
        return str(timedelta(seconds=int(seconds)))

    api_proc: subprocess.Popen[str] | None = None
    try:
        api_proc = _spawn_api_if_requested(args.api, args.spawn_api)
        if api_proc is not None:
            _wait_for_health(args.api, timeout_seconds=30.0)

        url = _db_url()
        with psycopg.connect(url) as conn:
            with conn.cursor() as cur:
                if args.book_id and args.chapter is not None:
                    cur.execute(
                        """
                        SELECT v.book_id, v.chapter, v.verse
                        FROM verses v
                        WHERE v.translation = %s AND v.book_id = %s AND v.chapter = %s
                        ORDER BY v.book_id, v.chapter, v.verse
                        """,
                        (args.translation, args.book_id, args.chapter),
                    )
                elif args.book_id:
                    cur.execute(
                        """
                        SELECT v.book_id, v.chapter, v.verse
                        FROM verses v
                        WHERE v.translation = %s AND v.book_id = %s
                        ORDER BY v.book_id, v.chapter, v.verse
                        """,
                        (args.translation, args.book_id),
                    )
                else:
                    cur.execute(
                        """
                        SELECT v.book_id, v.chapter, v.verse
                        FROM verses v
                        WHERE v.translation = %s
                        ORDER BY v.book_id, v.chapter, v.verse
                        """,
                        (args.translation,),
                    )
                refs = cur.fetchall()

        scope = f"translation={args.translation}"
        if args.book_id:
            scope += f" book_id={args.book_id}"
        if args.chapter is not None:
            scope += f" chapter={args.chapter}"
        print(f"Loaded {len(refs)} verse refs for {scope}", flush=True)

        if args.chapter is not None and not args.book_id:
            raise SystemExit("--chapter requires --book-id")

        if args.limit and args.limit > 0:
            refs = refs[: args.limit]

        total = len(refs)
        ok = 0
        started = time.time()

        if total == 0:
            print("No verses found for this translation in Postgres. Did you import it?", flush=True)
            print("Generated/ensured 0/0 commentary entries", flush=True)
            return

        print(f"Generating commentary via {args.api.rstrip('/')}/commentary/ensure", flush=True)

        for i, (book_id, chapter, verse) in enumerate(refs, start=1):
            if i == 1 or (args.progress_every > 0 and i % args.progress_every == 0):
                elapsed = time.time() - started
                rate = i / elapsed if elapsed > 0 else 0.0
                remaining = total - i
                eta = (remaining / rate) if rate > 0 else 0.0
                print(
                    f"[{i}/{total}] ok={ok} elapsed={fmt_eta(elapsed)} rate={rate:.2f}/s eta={fmt_eta(eta)}",
                    flush=True,
                )

            payload = json.dumps(
                {
                    "translation": args.translation,
                    "bookId": book_id,
                    "chapter": chapter,
                    "verse": verse,
                    "style": args.style,
                    "overwrite": bool(args.overwrite),
                }
            ).encode("utf-8")

            req = urllib.request.Request(
                url=f"{args.api.rstrip('/')}/commentary/ensure",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )

            attempt_429 = 0
            while True:
                try:
                    with urllib.request.urlopen(req, timeout=60) as resp:
                        if 200 <= resp.status < 300:
                            ok += 1
                        else:
                            body = resp.read().decode("utf-8", errors="replace")
                            print(
                                f"[{i}/{total}] FAIL {book_id} {chapter}:{verse} -> {resp.status} {body}",
                                flush=True,
                            )
                        break
                except urllib.error.HTTPError as e:
                    body = e.read().decode("utf-8", errors="replace")
                    if e.code == 429 and attempt_429 < args.max_429_retries:
                        attempt_429 += 1
                        retry_after = args.retry_after_default
                        ra = e.headers.get("Retry-After") if hasattr(e, "headers") else None
                        if ra:
                            try:
                                retry_after = float(ra)
                            except Exception:
                                retry_after = args.retry_after_default
                        print(
                            f"[{i}/{total}] 429 rate-limited; retrying in {retry_after:.1f}s (attempt {attempt_429}/{args.max_429_retries})",
                            flush=True,
                        )
                        time.sleep(retry_after)
                        continue

                    print(f"[{i}/{total}] FAIL {book_id} {chapter}:{verse} -> {e.code} {body}", flush=True)
                    break
                except KeyboardInterrupt:
                    print("\nInterrupted by user.", flush=True)
                    raise
                except Exception as e:
                    print(f"[{i}/{total}] FAIL {book_id} {chapter}:{verse} -> {e}", flush=True)
                    break

            if args.sleep:
                time.sleep(args.sleep)

        print(f"Generated/ensured {ok}/{total} commentary entries", flush=True)

    finally:
        if api_proc is not None and api_proc.poll() is None:
            api_proc.terminate()
            try:
                api_proc.wait(timeout=10)
            except Exception:  # noqa: BLE001
                api_proc.kill()


if __name__ == "__main__":
    main()
