from __future__ import annotations

import os
import sys

from sqlalchemy import create_engine, text


def _server_root() -> str:
    here = os.path.abspath(os.path.dirname(__file__))
    return os.path.normpath(os.path.join(here, "..", "server"))


def main() -> None:
    server_root = _server_root()
    app_path = os.path.join(server_root, "app")
    if app_path not in sys.path:
        sys.path.insert(0, app_path)

    try:
        from db import get_database_url  # noqa: WPS433 (local import by design)
    except ImportError as e:
        print(f"Failed to import 'db': {e}")
        sys.exit(1)

    url = get_database_url()
    engine = create_engine(url, pool_pre_ping=True)

    checks = [
        ("web", "romans", 8),
        ("web", "psalms", 23),
        ("kjv", "romans", 8),
        ("kjv", "psalms", 23),
    ]

    with engine.connect() as conn:
        total = conn.execute(text("select count(*) from verses")).scalar_one()
        by_translation = conn.execute(
            text(
                "select translation, count(*) as c from verses group by translation order by translation"
            )
        ).all()
        sample_book_ids_web = conn.execute(
            text(
                "select book_id, count(*) as c from verses where translation = 'web' group by book_id order by book_id limit 50"
            )
        ).all()

        print({"database_url": url})
        print({"verses_total": int(total)})
        print({"verses_by_translation": [(t, int(c)) for (t, c) in by_translation]})
        print({"web_book_ids_sample": sample_book_ids_web})

        for translation, book_id, chapter in checks:
            c = conn.execute(
                text(
                    "select count(*) from verses where translation = :t and book_id = :b and chapter = :c"
                ),
                {"t": translation, "b": book_id, "c": chapter},
            ).scalar_one()
            print({"check": {"translation": translation, "book_id": book_id, "chapter": chapter, "count": int(c)}})

            if c:
                row = conn.execute(
                    text(
                        "select translation, book_id, book, chapter, verse, left(text, 80) as text from verses "
                        "where translation = :t and book_id = :b and chapter = :c order by verse asc limit 1"
                    ),
                    {"t": translation, "b": book_id, "c": chapter},
                ).mappings().first()
                print({"first_verse": dict(row) if row else None})


if __name__ == "__main__":
    main()
