"""
convert_yoruba_usfx.py
=======================
Parses the eBible USFX XML format (one large XML file) into the app's
chapter-split JSON format.

XML structure (key elements):
  <v id="1" bcv="GEN.1.1" />  ← verse start marker with book.chapter.verse
  Text of the verse here.
  <ve />                        ← verse end marker

Usage (from project root):
  python tools/convert_yoruba_usfx.py ^
      "C:/Users/hp/Downloads/yor_usfx.zip" ^
      assets/data/bibles/yoruba
"""

import json
import re
import sys
import zipfile
from collections import defaultdict
from pathlib import Path
import xml.etree.ElementTree as ET

# USFM code → (canonical_id, display_name)
_BOOK_MAP: dict[str, tuple[str, str]] = {
    "GEN": ("genesis", "Genesis"), "EXO": ("exodus", "Exodus"),
    "LEV": ("leviticus", "Leviticus"), "NUM": ("numbers", "Numbers"),
    "DEU": ("deuteronomy", "Deuteronomy"), "JOS": ("joshua", "Joshua"),
    "JDG": ("judges", "Judges"), "RUT": ("ruth", "Ruth"),
    "1SA": ("1_samuel", "1 Samuel"), "2SA": ("2_samuel", "2 Samuel"),
    "1KI": ("1_kings", "1 Kings"), "2KI": ("2_kings", "2 Kings"),
    "1CH": ("1_chronicles", "1 Chronicles"), "2CH": ("2_chronicles", "2 Chronicles"),
    "EZR": ("ezra", "Ezra"), "NEH": ("nehemiah", "Nehemiah"),
    "EST": ("esther", "Esther"), "JOB": ("job", "Job"),
    "PSA": ("psalms", "Psalms"), "PRO": ("proverbs", "Proverbs"),
    "ECC": ("ecclesiastes", "Ecclesiastes"), "SNG": ("song_of_songs", "Song of Songs"),
    "ISA": ("isaiah", "Isaiah"), "JER": ("jeremiah", "Jeremiah"),
    "LAM": ("lamentations", "Lamentations"), "EZK": ("ezekiel", "Ezekiel"),
    "DAN": ("daniel", "Daniel"), "HOS": ("hosea", "Hosea"),
    "JOL": ("joel", "Joel"), "AMO": ("amos", "Amos"),
    "OBA": ("obadiah", "Obadiah"), "JON": ("jonah", "Jonah"),
    "MIC": ("micah", "Micah"), "NAM": ("nahum", "Nahum"),
    "HAB": ("habakkuk", "Habakkuk"), "ZEP": ("zephaniah", "Zephaniah"),
    "HAG": ("haggai", "Haggai"), "ZEC": ("zechariah", "Zechariah"),
    "MAL": ("malachi", "Malachi"), "MAT": ("matthew", "Matthew"),
    "MRK": ("mark", "Mark"), "LUK": ("luke", "Luke"),
    "JHN": ("john", "John"), "ACT": ("acts", "Acts"),
    "ROM": ("romans", "Romans"), "1CO": ("1_corinthians", "1 Corinthians"),
    "2CO": ("2_corinthians", "2 Corinthians"), "GAL": ("galatians", "Galatians"),
    "EPH": ("ephesians", "Ephesians"), "PHP": ("philippians", "Philippians"),
    "COL": ("colossians", "Colossians"), "1TH": ("1_thessalonians", "1 Thessalonians"),
    "2TH": ("2_thessalonians", "2 Thessalonians"), "1TI": ("1_timothy", "1 Timothy"),
    "2TI": ("2_timothy", "2 Timothy"), "TIT": ("titus", "Titus"),
    "PHM": ("philemon", "Philemon"), "HEB": ("hebrews", "Hebrews"),
    "JAS": ("james", "James"), "1PE": ("1_peter", "1 Peter"),
    "2PE": ("2_peter", "2 Peter"), "1JN": ("1_john", "1 John"),
    "2JN": ("2_john", "2 John"), "3JN": ("3_john", "3 John"),
    "JUD": ("jude", "Jude"), "REV": ("revelation", "Revelation"),
}

_RE_BCV = re.compile(r"^([A-Z0-9]{3})\.(\d+)\.(\d+)$")
_RE_WHITESPACE = re.compile(r"\s+")


def _clean(text: str) -> str:
    return _RE_WHITESPACE.sub(" ", text).strip()


def _parse_usfx(xml_content: str) -> list[dict]:
    """
    Parse USFX XML by scanning for <v bcv="X.Y.Z"/> ... <ve/> pairs
    using regex on raw text (faster and tolerates malformed XML better).
    """
    # Find all verse spans: from <v ... bcv="GEN.1.1" ...> to <ve
    _RE_VERSE_TAG = re.compile(
        r'<v\b[^>]*\bbcv="([A-Z0-9]+\.\d+\.\d+)"[^>]*/?>(.+?)(?=<v\b|<\/book>|$)',
        re.DOTALL,
    )
    _RE_XML_TAG = re.compile(r"<[^>]+>")

    verses: list[dict] = []

    for m in _RE_VERSE_TAG.finditer(xml_content):
        bcv_raw = m.group(1)
        raw_text_block = m.group(2)

        bcv_m = _RE_BCV.match(bcv_raw)
        if not bcv_m:
            continue

        usfm_code = bcv_m.group(1)
        chapter = int(bcv_m.group(2))
        verse = int(bcv_m.group(3))

        if usfm_code not in _BOOK_MAP:
            continue

        book_id, book_name = _BOOK_MAP[usfm_code]

        # Strip everything after <ve (verse end) if present
        ve_pos = raw_text_block.find("<ve")
        if ve_pos != -1:
            raw_text_block = raw_text_block[:ve_pos]

        # Remove all XML tags and clean whitespace
        text = _RE_XML_TAG.sub(" ", raw_text_block)
        text = _clean(text)

        if not text:
            continue

        verses.append({
            "bookId": book_id,
            "book": book_name,
            "chapter": chapter,
            "verse": verse,
            "text": text,
        })

    return verses


def _group_to_chapters(verses: list[dict]) -> dict[tuple[str, int], list[dict]]:
    buckets: dict[tuple[str, int], list[dict]] = defaultdict(list)
    for v in verses:
        key = (v["bookId"], v["chapter"])
        buckets[key].append({"verse": v["verse"], "text": v["text"]})
    return buckets


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: python tools/convert_yoruba_usfx.py <zip_path> <output_root>")
        return 2

    zip_path = Path(sys.argv[1])
    out_root = Path(sys.argv[2])

    if not zip_path.exists():
        print(f"ERROR: File not found: {zip_path}", file=sys.stderr)
        return 1

    # Find the USFX XML file inside the zip
    with zipfile.ZipFile(zip_path, "r") as zf:
        usfx_names = [n for n in zf.namelist() if n.endswith("_usfx.xml") or "usfx" in n.lower()]
        if not usfx_names:
            print("ERROR: No USFX XML file found in zip.", file=sys.stderr)
            return 1
        xml_content = zf.read(usfx_names[0]).decode("utf-8", errors="replace")
        print(f"  Parsing: {usfx_names[0]} ({len(xml_content):,} bytes)")

    verses = _parse_usfx(xml_content)
    if not verses:
        print("ERROR: No verses parsed from USFX XML.", file=sys.stderr)
        return 1

    print(f"  Parsed {len(verses):,} verses")

    buckets = _group_to_chapters(verses)
    written = 0

    # Get book names from the first verse in each chapter
    book_names: dict[str, str] = {}
    for v in verses:
        book_names.setdefault(v["bookId"], v["book"])

    for (book_id, chapter), chapter_verses in buckets.items():
        chapter_verses.sort(key=lambda v: v["verse"])

        out_dir = out_root / book_id
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / f"{chapter}.json"

        payload = {
            "bookId": book_id,
            "book": book_names.get(book_id, book_id),
            "chapter": chapter,
            "verses": chapter_verses,
        }

        with open(out_path, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, ensure_ascii=False, indent=2)

        written += 1

    print(f"✅  Yoruba: wrote {written} chapter files → {out_root}")
    print()
    print("👉  Run next:  python tools/generate_pubspec_assets.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
