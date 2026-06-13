import json
import os
import sys
from collections import defaultdict

# Usage:
#   python tools/split_bible_json.py <input.json> <output_root>
#
# Input format: a JSON array of objects like:
#   {"bookId":"john","book":"John","chapter":3,"verse":16,"text":"..."}
#
# Output format (per chapter file):
#   assets/data/bibles/<translation>/<bookId>/<chapter>.json
#   {
#     "bookId":"john",
#     "book":"John",
#     "chapter":3,
#     "verses":[ {"verse":16,"text":"..."}, ...]
#   }


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python tools/split_bible_json.py <input.json> <output_root>")
        return 2

    in_path = sys.argv[1]
    out_root = sys.argv[2]

    with open(in_path, "r", encoding="utf-8") as f:
        items = json.load(f)

    if not isinstance(items, list):
        raise SystemExit("Input JSON must be a list")

    buckets: dict[tuple[str, int], list[dict]] = defaultdict(list)
    meta: dict[tuple[str, int], tuple[str, str]] = {}

    for it in items:
        book_id = str(it["bookId"]).lower()
        book = str(it["book"])
        chapter = int(it["chapter"])
        verse = int(it["verse"])
        text = str(it["text"])

        key = (book_id, chapter)
        buckets[key].append({"verse": verse, "text": text})
        meta[key] = (book_id, book)

    for (book_id, chapter), verses in buckets.items():
        verses.sort(key=lambda v: v["verse"])
        _, book_name = meta[(book_id, chapter)]

        out_dir = os.path.join(out_root, book_id)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{chapter}.json")

        payload = {
            "bookId": book_id,
            "book": book_name,
            "chapter": chapter,
            "verses": verses,
        }

        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)

    print(f"Wrote {len(buckets)} chapter files under {out_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
