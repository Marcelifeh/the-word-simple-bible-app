import argparse
import json
import re
from pathlib import Path
from typing import Any


def _book_id_from_name(name: str) -> str:
    # Match the existing app's conventions: lowercase, strip punctuation/spaces.
    # Examples: "1 Samuel" -> "1samuel", "Song of Solomon" -> "songofsolomon".
    s = name.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "", s)
    return s


def _convert_thiagobodruk(data: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for book in data:
        name = str(book.get("name") or "").strip()
        if not name:
            # Some datasets might omit 'name', but thiagobodruk includes it.
            raise SystemExit("Missing book 'name' field in thiagobodruk-style JSON")

        chapters = book.get("chapters")
        if not isinstance(chapters, list):
            continue

        book_id = _book_id_from_name(name)

        for chapter_index, chapter in enumerate(chapters, start=1):
            if not isinstance(chapter, list):
                continue
            for verse_index, verse_text in enumerate(chapter, start=1):
                if verse_text is None:
                    verse_text = ""
                out.append(
                    {
                        "bookId": book_id,
                        "book": name,
                        "chapter": chapter_index,
                        "verse": verse_index,
                        "text": str(verse_text),
                    }
                )
    return out


def _convert_flat_verses(data: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for item in data:
        book = str(item.get("book") or "").strip()
        if not book:
            continue
        out.append(
            {
                "bookId": _book_id_from_name(book),
                "book": book,
                "chapter": int(item.get("chapter")),
                "verse": int(item.get("verse")),
                "text": str(item.get("text") or ""),
            }
        )
    return out


def _detect_format(data: Any) -> str:
    if not isinstance(data, list) or not data:
        raise SystemExit("Input JSON must be a non-empty list")

    first = data[0]
    if isinstance(first, dict) and "chapters" in first:
        return "thiagobodruk"
    if isinstance(first, dict) and {"book", "chapter", "verse", "text"}.issubset(first.keys()):
        return "flat"
    raise SystemExit(
        "Unrecognized JSON format. Expected either thiagobodruk-style [{name, chapters: [[...]]}] or flat verse list."
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Convert public Bible JSON formats into the app's flat verse-array format: "
            "[{bookId, book, chapter, verse, text}, ...]"
        )
    )
    parser.add_argument("input_json", help="Path to source JSON file")
    parser.add_argument("output_json", help="Path to write converted JSON")
    parser.add_argument(
        "--format",
        choices=["auto", "thiagobodruk", "flat"],
        default="auto",
        help="Input format (default: auto-detect)",
    )
    args = parser.parse_args()

    input_path = Path(args.input_json)
    output_path = Path(args.output_json)

    data = json.loads(input_path.read_text(encoding="utf-8"))
    fmt = args.format if args.format != "auto" else _detect_format(data)

    if fmt == "thiagobodruk":
        converted = _convert_thiagobodruk(data)
    elif fmt == "flat":
        converted = _convert_flat_verses(data)
    else:
        raise AssertionError(fmt)

    output_path.write_text(json.dumps(converted, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {len(converted)} verses to {output_path}")


if __name__ == "__main__":
    main()
