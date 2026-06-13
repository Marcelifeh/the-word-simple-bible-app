"""
convert_hausa_readaloud.py
===========================
Parses the eBible "readaloud" zip (per-chapter .txt files with numbered paragraphs)
into the app's chapter-split JSON format.

File naming convention inside the zip:
  hauulb_070_MAT_01_read.txt  →  Matthew chapter 1
  hauulb_010_GEN_01_read.txt  →  Genesis chapter 1

Text format inside each file:
  BookName.
  1.
  Verse text for verse 1 (may span multiple lines).
  2.
  Verse text for verse 2.
  ...

Usage (from project root):
  python tools/convert_hausa_readaloud.py ^
      "C:/Users/hp/Downloads/hauulb_readaloud.zip" ^
      assets/data/bibles/hausa
"""

import json
import re
import sys
import zipfile
from collections import defaultdict
from pathlib import Path

# USFM 3-letter code → (canonical_id, display_name)
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

# filename pattern: hauulb_010_GEN_01_read.txt
_RE_FILENAME = re.compile(r"_([A-Z0-9]{3})_(\d+)_read\.txt$", re.IGNORECASE)

# verse number line: "1." or "12."
_RE_VERSE_NUM = re.compile(r"^(\d+)\.\s*$")


def _parse_chapter_txt(content: str) -> list[tuple[int, str]]:
    """Return list of (verse_number, text) from one readaloud .txt file."""
    lines = content.splitlines()
    verses: list[tuple[int, str]] = []
    current_verse: int | None = None
    buffer: list[str] = []

    def flush():
        if current_verse is not None and buffer:
            text = " ".join(" ".join(b.split()) for b in buffer if b.strip())
            text = text.strip()
            if text:
                verses.append((current_verse, text))

    for line in lines:
        stripped = line.strip()
        # Skip book title line (first non-empty line ending with ".")
        # and other header-style lines
        m = _RE_VERSE_NUM.match(stripped)
        if m:
            flush()
            buffer = []
            current_verse = int(m.group(1))
        elif current_verse is not None and stripped:
            buffer.append(stripped)

    flush()
    return verses


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: python tools/convert_hausa_readaloud.py <zip_path> <output_root>")
        return 2

    zip_path = Path(sys.argv[1])
    out_root = Path(sys.argv[2])

    if not zip_path.exists():
        print(f"ERROR: File not found: {zip_path}", file=sys.stderr)
        return 1

    written = 0
    skipped_files = []

    with zipfile.ZipFile(zip_path, "r") as zf:
        for info in zf.infolist():
            m = _RE_FILENAME.search(info.filename)
            if not m:
                continue

            usfm_code = m.group(1).upper()
            chapter_num = int(m.group(2))

            if usfm_code not in _BOOK_MAP:
                skipped_files.append(info.filename)
                continue

            book_id, book_name = _BOOK_MAP[usfm_code]

            content = zf.read(info).decode("utf-8-sig", errors="replace")
            verses = _parse_chapter_txt(content)

            if not verses:
                skipped_files.append(info.filename)
                continue

            out_dir = out_root / book_id
            out_dir.mkdir(parents=True, exist_ok=True)
            out_path = out_dir / f"{chapter_num}.json"

            payload = {
                "bookId": book_id,
                "book": book_name,
                "chapter": chapter_num,
                "verses": [{"verse": v, "text": t} for v, t in sorted(verses)],
            }

            with open(out_path, "w", encoding="utf-8") as fh:
                json.dump(payload, fh, ensure_ascii=False, indent=2)

            written += 1

    print(f"✅  Hausa: wrote {written} chapter files → {out_root}")
    if skipped_files:
        print(f"    Skipped {len(skipped_files)} non-verse files (intro, copr, etc.)")
    print()
    print("👉  Run next:  python tools/generate_pubspec_assets.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
