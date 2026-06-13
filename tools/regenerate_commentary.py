from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import psycopg


def _load_env() -> None:
    try:
        from dotenv import load_dotenv  # type: ignore
    except Exception:
        return

    repo_root = Path(__file__).resolve().parents[1]
    env_path = repo_root / 'server' / 'app' / '.env'
    if env_path.exists():
        load_dotenv(dotenv_path=env_path, override=True)


def _db_url(explicit: str | None) -> str:
    _load_env()
    url = explicit or os.getenv('DATABASE_URL')
    if not url:
        raise SystemExit(
            'DATABASE_URL is required (set env var, create server/app/.env, or pass --database-url)'
        )
    if url.startswith('postgresql+psycopg://'):
        url = url.replace('postgresql+psycopg://', 'postgresql://', 1)
    return url


def _post_json(url: str, payload: dict[str, object], timeout: float = 120.0) -> tuple[int, str]:
    req = urllib.request.Request(
        url=url,
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
        method='POST',
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.status, resp.read().decode('utf-8', errors='replace')


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Regenerate only missing or stale premium commentary rows.'
    )
    parser.add_argument('--api', default='http://127.0.0.1:8000', help='API base URL')
    parser.add_argument(
        '--database-url',
        default=None,
        help='Override DATABASE_URL (otherwise uses env or server/app/.env)',
    )
    parser.add_argument('--translation', choices=['kjv', 'web'], required=True)
    parser.add_argument('--language', default='english')
    parser.add_argument('--style', default='insight_premium_v2')
    parser.add_argument('--book-id', default=None)
    parser.add_argument('--chapter', type=int, default=None)
    parser.add_argument('--limit', type=int, default=0, help='0 = no limit')
    parser.add_argument('--sleep', type=float, default=0.0, help='Seconds to sleep between requests')
    parser.add_argument(
        '--max-429-retries',
        type=int,
        default=8,
        help='Max retries for a single verse when API returns 429 (default: 8)',
    )
    parser.add_argument(
        '--retry-after-default',
        type=float,
        default=15.0,
        help='Seconds to wait when API 429 has no Retry-After header (default: 15)',
    )
    parser.add_argument(
        '--progress-every',
        type=int,
        default=25,
        help='Print progress every N verses (default: 25)',
    )

    args = parser.parse_args()

    if args.translation != 'kjv':
        print(
            f"Skipping {args.translation} backfill: all translations reuse KJV commentary.",
            flush=True,
        )
        return

    if args.chapter is not None and not args.book_id:
        raise SystemExit('--chapter requires --book-id')

    where = ['v.translation = %s']
    params: list[object] = [args.translation]

    if args.book_id:
      where.append('v.book_id = %s')
      params.append(args.book_id.strip().lower())

    if args.chapter is not None:
      where.append('v.chapter = %s')
      params.append(int(args.chapter))

    sql = f'''
        SELECT v.book_id, v.chapter, v.verse
        FROM verses v
        LEFT JOIN commentary c
          ON c.verse_id = v.id
         AND c.style = %s
         AND c.language = %s
        WHERE {' AND '.join(where)}
          AND (
            c.id IS NULL
            OR c.payload_json IS NULL
            OR BTRIM(c.payload_json) = ''
          )
        ORDER BY v.book_id, v.chapter, v.verse
    '''

    params = [args.style, args.language, *params]

    with psycopg.connect(_db_url(args.database_url)) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            refs = cur.fetchall()

    if args.limit and args.limit > 0:
        refs = refs[: args.limit]

    total = len(refs)
    print(f'Found {total} verse(s) missing structured premium commentary.', flush=True)
    if total == 0:
        return

    ok = 0
    started = time.time()

    for i, (book_id, chapter, verse) in enumerate(refs, start=1):
        if i == 1 or (args.progress_every > 0 and i % args.progress_every == 0):
            elapsed = time.time() - started
            rate = i / elapsed if elapsed > 0 else 0.0
            remaining = total - i
            eta = (remaining / rate) if rate > 0 else 0.0
            print(
                f'[{i}/{total}] ok={ok} elapsed={int(elapsed)}s rate={rate:.2f}/s eta={int(eta)}s',
                flush=True,
            )

        payload = {
            'translation': args.translation,
            'bookId': str(book_id),
            'chapter': int(chapter),
            'verse': int(verse),
            'style': args.style,
            'language': args.language,
            'overwrite': True,
        }

        ref = f'{args.translation} {book_id} {chapter}:{verse}'
        attempt_429 = 0
        while True:
            try:
                status, body = _post_json(f"{args.api.rstrip('/')}/commentary/ensure", payload)
                if 200 <= status < 300:
                    ok += 1
                else:
                    print(f'FAIL {ref} -> {status} {body[:300]}', flush=True)
                break
            except urllib.error.HTTPError as exc:
                body = exc.read().decode('utf-8', errors='replace')
                if exc.code == 429 and attempt_429 < args.max_429_retries:
                    attempt_429 += 1
                    retry_after = args.retry_after_default
                    header = exc.headers.get('Retry-After') if hasattr(exc, 'headers') else None
                    if header:
                        try:
                            retry_after = float(header)
                        except Exception:
                            retry_after = args.retry_after_default
                    print(
                        f'RATE LIMITED {ref} -> retrying in {retry_after:.1f}s '
                        f'(attempt {attempt_429}/{args.max_429_retries})',
                        flush=True,
                    )
                    time.sleep(retry_after)
                    continue

                print(f'FAIL {ref} -> {exc.code} {body[:300]}', flush=True)
                break
            except KeyboardInterrupt:
                print('\nInterrupted by user.', flush=True)
                raise
            except Exception as exc:
                print(f'FAIL {ref} -> {exc}', flush=True)
                break

        if args.sleep:
            time.sleep(args.sleep)

    print(f'Regenerated {ok}/{total} premium commentary entries', flush=True)


if __name__ == '__main__':
    main()