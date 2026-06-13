"""
convert_plain_text_bible.py
============================
Converts a plain-text Bible download (eBible.org UTF-8 format) into
the chapter-split JSON structure used by The Word app.

Supported input formats (auto-detected):
  1. "Genesis 1:1  Text here..."     ← eBible plain-text
  2. "GEN 1:1 Text here..."          ← Abbreviation prefix
  3. "1:1 Text here..."              ← Verse-only (when --book is given)
  4. TSV: "GEN\t1\t1\tText here..."  ← Tab-separated values

Output structure (per chapter):
  assets/data/bibles/<lang>/<book_id>/<chapter>.json
  {
    "bookId": "genesis",
    "book": "Genesis",
    "chapter": 1,
    "verses": [{"verse": 1, "text": "In the beginning..."}, ...]
  }

Usage examples:
  # Full Bible file (all books in one file):
  python tools/convert_plain_text_bible.py hausa.txt hausa

  # Per-book files (pass --book or let the script infer from the filename):
  python tools/convert_plain_text_bible.py Genesis.txt hausa --book genesis

  # After running, register new assets:
  python tools/generate_pubspec_assets.py
"""

import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Canonical book catalogue (matches BookCatalog.dart)
# Maps every common name / abbreviation → (canonical_id, display_name)
# ---------------------------------------------------------------------------
_BOOK_MAP: dict[str, tuple[str, str]] = {}

_BOOKS_RAW = [
    # OT
    ("genesis",          "Genesis",          ["gen", "gn", "genesis"]),
    ("exodus",           "Exodus",           ["exo", "ex", "exodus"]),
    ("leviticus",        "Leviticus",        ["lev", "lv", "leviticus"]),
    ("numbers",          "Numbers",          ["num", "nm", "numbers"]),
    ("deuteronomy",      "Deuteronomy",      ["deu", "dt", "deuteronomy", "deut"]),
    ("joshua",           "Joshua",           ["jos", "josh", "joshua"]),
    ("judges",           "Judges",           ["jdg", "judg", "judges"]),
    ("ruth",             "Ruth",             ["rut", "ruth"]),
    ("1_samuel",         "1 Samuel",         ["1sa", "1sam", "1samuel", "1 samuel"]),
    ("2_samuel",         "2 Samuel",         ["2sa", "2sam", "2samuel", "2 samuel"]),
    ("1_kings",          "1 Kings",          ["1ki", "1kgs", "1kings", "1 kings"]),
    ("2_kings",          "2 Kings",          ["2ki", "2kgs", "2kings", "2 kings"]),
    ("1_chronicles",     "1 Chronicles",     ["1ch", "1chr", "1chron", "1chronicles", "1 chronicles"]),
    ("2_chronicles",     "2 Chronicles",     ["2ch", "2chr", "2chron", "2chronicles", "2 chronicles"]),
    ("ezra",             "Ezra",             ["ezr", "ezra"]),
    ("nehemiah",         "Nehemiah",         ["neh", "nehemiah"]),
    ("esther",           "Esther",           ["est", "esth", "esther"]),
    ("job",              "Job",              ["job"]),
    ("psalms",           "Psalms",           ["psa", "ps", "psalm", "psalms"]),
    ("proverbs",         "Proverbs",         ["pro", "prov", "proverbs"]),
    ("ecclesiastes",     "Ecclesiastes",     ["ecc", "eccl", "ecclesiastes", "qoh"]),
    ("song_of_songs",    "Song of Songs",    ["sng", "sos", "song", "songofsolomon", "songofsongs", "song of songs", "song of solomon", "sg"]),
    ("isaiah",           "Isaiah",           ["isa", "isaiah"]),
    ("jeremiah",         "Jeremiah",         ["jer", "jeremiah"]),
    ("lamentations",     "Lamentations",     ["lam", "lamentations"]),
    ("ezekiel",          "Ezekiel",          ["ezk", "ezek", "ezekiel"]),
    ("daniel",           "Daniel",           ["dan", "daniel"]),
    ("hosea",            "Hosea",            ["hos", "hosea"]),
    ("joel",             "Joel",             ["jol", "joel"]),
    ("amos",             "Amos",             ["amo", "amos"]),
    ("obadiah",          "Obadiah",          ["oba", "obad", "obadiah"]),
    ("jonah",            "Jonah",            ["jon", "jonah"]),
    ("micah",            "Micah",            ["mic", "micah"]),
    ("nahum",            "Nahum",            ["nam", "nah", "nahum"]),
    ("habakkuk",         "Habakkuk",         ["hab", "habakkuk"]),
    ("zephaniah",        "Zephaniah",        ["zep", "zeph", "zephaniah"]),
    ("haggai",           "Haggai",           ["hag", "haggai"]),
    ("zechariah",        "Zechariah",        ["zec", "zech", "zechariah"]),
    ("malachi",          "Malachi",          ["mal", "malachi"]),
    # NT
    ("matthew",          "Matthew",          ["mat", "matt", "matthew"]),
    ("mark",             "Mark",             ["mrk", "mar", "mark"]),
    ("luke",             "Luke",             ["luk", "luke"]),
    ("john",             "John",             ["jhn", "jn", "john"]),
    ("acts",             "Acts",             ["act", "acts"]),
    ("romans",           "Romans",           ["rom", "romans"]),
    ("1_corinthians",    "1 Corinthians",    ["1co", "1cor", "1corinthians", "1 corinthians"]),
    ("2_corinthians",    "2 Corinthians",    ["2co", "2cor", "2corinthians", "2 corinthians"]),
    ("galatians",        "Galatians",        ["gal", "galatians"]),
    ("ephesians",        "Ephesians",        ["eph", "ephesians"]),
    ("philippians",      "Philippians",      ["php", "phil", "philippians"]),
    ("colossians",       "Colossians",       ["col", "colossians"]),
    ("1_thessalonians",  "1 Thessalonians",  ["1th", "1thes", "1thessalonians", "1 thessalonians"]),
    ("2_thessalonians",  "2 Thessalonians",  ["2th", "2thes", "2thessalonians", "2 thessalonians"]),
    ("1_timothy",        "1 Timothy",        ["1ti", "1tim", "1timothy", "1 timothy"]),
    ("2_timothy",        "2 Timothy",        ["2ti", "2tim", "2timothy", "2 timothy"]),
    ("titus",            "Titus",            ["tit", "titus"]),
    ("philemon",         "Philemon",         ["phm", "phlm", "philemon"]),
    ("hebrews",          "Hebrews",          ["heb", "hebrews"]),
    ("james",            "James",            ["jas", "james"]),
    ("1_peter",          "1 Peter",          ["1pe", "1pet", "1peter", "1 peter"]),
    ("2_peter",          "2 Peter",          ["2pe", "2pet", "2peter", "2 peter"]),
    ("1_john",           "1 John",           ["1jn", "1jo", "1john", "1 john"]),
    ("2_john",           "2 John",           ["2jn", "2jo", "2john", "2 john"]),
    ("3_john",           "3 John",           ["3jn", "3jo", "3john", "3 john"]),
    ("jude",             "Jude",             ["jud", "jude"]),
    ("revelation",       "Revelation",       ["rev", "revelation", "revelations", "apoc"]),
]

for _book_id, _display, _aliases in _BOOKS_RAW:
    for _alias in _aliases:
        _BOOK_MAP[_alias.lower().replace(" ", "").replace("_", "")] = (_book_id, _display)
    # also register the canonical id itself
    _BOOK_MAP[_book_id.lower().replace("_", "")] = (_book_id, _display)


def _lookup_book(raw: str) -> tuple[str, str] | None:
    """Return (canonical_id, display_name) or None if not found."""
    key = raw.lower().strip().replace(" ", "").replace("_", "").replace(".", "")
    return _BOOK_MAP.get(key)


# ---------------------------------------------------------------------------
# Line parsers (tried in order)
# ---------------------------------------------------------------------------

# Format 1: "Genesis 1:1  Text..."  or  "1 Samuel 3:4  Text..."
_RE_FULL_NAME = re.compile(
    r"^(\d?\s?[A-Za-z][A-Za-z ]+?)\s+(\d+):(\d+)\s+(.*)", re.UNICODE
)

# Format 2: "GEN 1:1 Text..."  or  "GEN\t1\t1\tText..."
_RE_ABBREV = re.compile(
    r"^([A-Z1-3]{2,5})\s+(\d+)[:\s](\d+)\s+(.*)", re.UNICODE
)

# Format 3: TSV  "GEN\t1\t1\tText"
_RE_TSV = re.compile(r"^([^\t]+)\t(\d+)\t(\d+)\t(.*)")

# Format 4: bare "1:1 Text..." (requires --book hint)
_RE_BARE = re.compile(r"^(\d+):(\d+)\s+(.*)")


def _parse_line(line: str, book_hint: tuple[str, str] | None):
    """Parse a single line. Returns (book_id, book_name, chapter, verse, text) or None."""
    line = line.strip()
    if not line or line.startswith("#"):
        return None

    # TSV
    m = _RE_TSV.match(line)
    if m:
        book_raw, ch, vs, text = m.group(1), m.group(2), m.group(3), m.group(4)
        bk = _lookup_book(book_raw)
        if bk:
            return (*bk, int(ch), int(vs), text.strip())

    # Full name: "Genesis 1:1"
    m = _RE_FULL_NAME.match(line)
    if m:
        book_raw, ch, vs, text = m.group(1), m.group(2), m.group(3), m.group(4)
        bk = _lookup_book(book_raw.strip())
        if bk:
            return (*bk, int(ch), int(vs), text.strip())

    # Abbreviation: "GEN 1:1"
    m = _RE_ABBREV.match(line)
    if m:
        book_raw, ch, vs, text = m.group(1), m.group(2), m.group(3), m.group(4)
        bk = _lookup_book(book_raw)
        if bk:
            return (*bk, int(ch), int(vs), text.strip())

    # Bare "1:1 Text" (needs book_hint)
    if book_hint:
        m = _RE_BARE.match(line)
        if m:
            ch, vs, text = m.group(1), m.group(2), m.group(3)
            return (*book_hint, int(ch), int(vs), text.strip())

    return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(
        description="Convert a plain-text Bible (eBible.org) into chapter-split JSON for The Word app."
    )
    parser.add_argument("input", help="Path to the plain-text Bible file (.txt)")
    parser.add_argument(
        "language",
        help="Output language folder name, e.g. hausa, igbo, yoruba",
    )
    parser.add_argument(
        "--book",
        default=None,
        help="Force a single book ID (e.g. genesis) — use when file contains one book only",
    )
    parser.add_argument(
        "--output-root",
        default="assets/data/bibles",
        help="Root of the Bible assets directory (default: assets/data/bibles)",
    )
    parser.add_argument(
        "--encoding",
        default="utf-8",
        help="File encoding (default: utf-8). Try utf-8-sig if the file has a BOM.",
    )

    args = parser.parse_args()

    book_hint: tuple[str, str] | None = None
    if args.book:
        book_hint = _lookup_book(args.book)
        if book_hint is None:
            print(f"ERROR: Unknown book '{args.book}'. Check spelling.", file=sys.stderr)
            return 1

    out_root = Path(args.output_root) / args.language

    # Read file
    try:
        with open(args.input, "r", encoding=args.encoding, errors="replace") as fh:
            lines = fh.readlines()
    except FileNotFoundError:
        print(f"ERROR: File not found: {args.input}", file=sys.stderr)
        return 1

    # Parse all lines
    buckets: dict[tuple[str, int], list[dict]] = defaultdict(list)
    meta: dict[tuple[str, int], tuple[str, str]] = {}
    skipped = 0

    for i, line in enumerate(lines, 1):
        result = _parse_line(line, book_hint)
        if result is None:
            skipped += 1
            continue
        book_id, book_name, chapter, verse, text = result
        if not text:
            continue
        key = (book_id, chapter)
        buckets[key].append({"verse": verse, "text": text})
        meta[key] = (book_id, book_name)

    if not buckets:
        print(
            "ERROR: No verses parsed. Check the file format and encoding.\n"
            "       Try --encoding utf-8-sig if the file starts with a BOM.\n"
            "       Use --book <name> if the file contains only one book.",
            file=sys.stderr,
        )
        return 1

    # Write chapter files
    written = 0
    for (book_id, chapter), verses in buckets.items():
        verses.sort(key=lambda v: v["verse"])
        _, book_name = meta[(book_id, chapter)]

        out_dir = out_root / book_id
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{chapter}.json"

        payload = {
            "bookId": book_id,
            "book": book_name,
            "chapter": chapter,
            "verses": verses,
        }

        with open(out_path, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, ensure_ascii=False, indent=2)

        written += 1

    print(f"✅  Written {written} chapter files → {out_root}")
    print(f"    Skipped {skipped} unrecognised lines (headers, blanks, etc.)")
    print()
    print("👉  Next: register assets in pubspec.yaml:")
    print("    python tools/generate_pubspec_assets.py")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
