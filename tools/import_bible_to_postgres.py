import argparse
import json
import os
from pathlib import Path

import psycopg


def _connect() -> psycopg.Connection:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise SystemExit(
            "DATABASE_URL env var is required (example: postgresql://bible:bible@localhost:5432/bible)"
        )
    # For psycopg v3 we want the 'postgresql://' form, not SQLAlchemy's '+psycopg'.
    if url.startswith("postgresql+"):
        url = url.replace("postgresql+psycopg://", "postgresql://")
    return psycopg.connect(url)


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Bible JSON array into Postgres (verses table).")
    parser.add_argument("translation", choices=["kjv", "web"], help="Translation code")
    parser.add_argument("input_json", help="Path to JSON file (array of verse items)")
    args = parser.parse_args()

    input_path = Path(args.input_json)
    data = json.loads(input_path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise SystemExit("Input JSON must be a list")

    rows = []
    for item in data:
        if not isinstance(item, dict):
            continue
        rows.append(
            (
                args.translation,
                str(item.get("bookId", "")).lower(),
                str(item.get("book", "")),
                int(item.get("chapter")),
                int(item.get("verse")),
                str(item.get("text", "")),
            )
        )

    if not rows:
        raise SystemExit("No verses found")

    with _connect() as conn:
        with conn.cursor() as cur:
            cur.executemany(
                """
                INSERT INTO verses (translation, book_id, book, chapter, verse, text)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (translation, book_id, chapter, verse)
                DO UPDATE SET text = EXCLUDED.text, book = EXCLUDED.book
                """,
                rows,
            )
        conn.commit()

    print(f"Imported {len(rows)} verses into translation={args.translation}")


if __name__ == "__main__":
    main()
