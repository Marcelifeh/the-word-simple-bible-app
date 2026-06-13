import argparse
import re
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


def _slug_book_id(name: str) -> str:
    s = name.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s


def _canonical_book_id(usfm_id: str, book_name: str) -> str:
    """Return a stable canonical book id that matches the Flutter app.

    Do NOT derive book IDs from \toc1 because some datasets use very long titles.
    Prefer USFM \id mapping.
    """

    # Most USFM ids map cleanly via our fallback name list.
    base_name = _USFM_BOOK_FALLBACK_NAMES.get(usfm_id, book_name)
    book_id = _slug_book_id(base_name)

    # Align with Flutter's BookCatalog ids.
    if usfm_id == "SNG":
        return "song_of_songs"
    if book_id == "song_of_solomon":
        return "song_of_songs"

    return book_id


@dataclass(frozen=True)
class VerseRef:
    book_usfm: str
    book_name: str
    chapter: int
    verse: int


_USFM_BOOK_FALLBACK_NAMES: dict[str, str] = {
    # OT
    "GEN": "Genesis",
    "EXO": "Exodus",
    "LEV": "Leviticus",
    "NUM": "Numbers",
    "DEU": "Deuteronomy",
    "JOS": "Joshua",
    "JDG": "Judges",
    "RUT": "Ruth",
    "1SA": "1 Samuel",
    "2SA": "2 Samuel",
    "1KI": "1 Kings",
    "2KI": "2 Kings",
    "1CH": "1 Chronicles",
    "2CH": "2 Chronicles",
    "EZR": "Ezra",
    "NEH": "Nehemiah",
    "EST": "Esther",
    "JOB": "Job",
    "PSA": "Psalms",
    "PRO": "Proverbs",
    "ECC": "Ecclesiastes",
    "SNG": "Song of Songs",
    "ISA": "Isaiah",
    "JER": "Jeremiah",
    "LAM": "Lamentations",
    "EZK": "Ezekiel",
    "DAN": "Daniel",
    "HOS": "Hosea",
    "JOL": "Joel",
    "AMO": "Amos",
    "OBA": "Obadiah",
    "JON": "Jonah",
    "MIC": "Micah",
    "NAM": "Nahum",
    "HAB": "Habakkuk",
    "ZEP": "Zephaniah",
    "HAG": "Haggai",
    "ZEC": "Zechariah",
    "MAL": "Malachi",
    # NT
    "MAT": "Matthew",
    "MRK": "Mark",
    "LUK": "Luke",
    "JHN": "John",
    "ACT": "Acts",
    "ROM": "Romans",
    "1CO": "1 Corinthians",
    "2CO": "2 Corinthians",
    "GAL": "Galatians",
    "EPH": "Ephesians",
    "PHP": "Philippians",
    "COL": "Colossians",
    "1TH": "1 Thessalonians",
    "2TH": "2 Thessalonians",
    "1TI": "1 Timothy",
    "2TI": "2 Timothy",
    "TIT": "Titus",
    "PHM": "Philemon",
    "HEB": "Hebrews",
    "JAS": "James",
    "1PE": "1 Peter",
    "2PE": "2 Peter",
    "1JN": "1 John",
    "2JN": "2 John",
    "3JN": "3 John",
    "JUD": "Jude",
    "REV": "Revelation",
}


_RE_USFM_TAG = re.compile(r"\\[+\-]?[a-zA-Z0-9*]+")
_RE_STRONG_PIPE = re.compile(r"\|strong=\"[^\"]*\"")
_RE_MULTISPACE = re.compile(r"\s+")


def _clean_usfm_text(s: str) -> str:
    # Remove footnotes and cross-refs blocks.
    s = re.sub(r"\\f\s+.*?\\f\*", " ", s, flags=re.DOTALL)
    s = re.sub(r"\\x\s+.*?\\x\*", " ", s, flags=re.DOTALL)

    # Remove inline character styles like \add, \bd, \it etc.
    s = _RE_USFM_TAG.sub(" ", s)

    # Strip Strong's-number annotations that some USFM exports embed inline.
    # Example: "There|strong=\"G1722\" is|strong=\"G3588\" ..."
    s = _RE_STRONG_PIPE.sub("", s)

    # Fix spacing around apostrophes caused by tag stripping.
    # Example: "don’ t" -> "don’t"
    s = re.sub(r"([\w])['\u2019]\s+([\w])", r"\1’\2", s)

    # Remove spaces before common punctuation.
    s = re.sub(r"\s+([,.;:!?])", r"\1", s)

    # Normalize whitespace.
    s = s.replace("\u00a0", " ")
    s = _RE_MULTISPACE.sub(" ", s)
    return s.strip()


def _iter_usfm_files_from_zip(zip_path: Path) -> Iterable[tuple[str, str]]:
    with zipfile.ZipFile(zip_path, "r") as zf:
        for info in zf.infolist():
            if info.is_dir():
                continue
            name = info.filename
            if not name.lower().endswith((".usfm", ".sfm", ".txt")):
                continue
            # Many USFM zips have a wrapper folder; keep only basename for debug.
            content = zf.read(info).decode("utf-8", errors="replace")
            yield name, content


def _extract_book_name(usfm_id: str, content: str) -> str:
    # Prefer \toc1 (long table-of-contents title), then \h.
    m = re.search(r"^\\toc1\s+(.+)$", content, flags=re.MULTILINE)
    if m:
        name = m.group(1).strip()
        # Some sources embed very long titles; keep DB-friendly canonical names.
        if len(name) <= 64:
            return name
    m = re.search(r"^\\h\s+(.+)$", content, flags=re.MULTILINE)
    if m:
        name = m.group(1).strip()
        if len(name) <= 64:
            return name
    return _USFM_BOOK_FALLBACK_NAMES.get(usfm_id, usfm_id)


def _extract_usfm_id(content: str) -> str:
    m = re.search(r"^\\id\s+([A-Z0-9]{3})\b", content, flags=re.MULTILINE)
    if not m:
        raise SystemExit("USFM file missing \\id line")
    return m.group(1)


def _parse_usfm_to_verses(content: str, usfm_id: str, book_name: str) -> list[dict]:
    # Parse \c and \v markers across the whole file (handles inline markers).
    # Verse text spans from a \v marker until the next \v or \c marker.
    text = content

    marker = re.compile(r"\\c\s+(\d+)|\\v\s+([0-9]+(?:-[0-9]+)?)")
    matches = list(marker.finditer(text))

    chapter = 0
    verse = 0
    out: list[dict] = []

    def to_int_verse(v: str) -> int:
        try:
            return int(v)
        except Exception:
            m = re.match(r"(\d+)", v)
            return int(m.group(1)) if m else 0

    for i, m in enumerate(matches):
        next_start = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        if m.group(1) is not None:
            # Chapter marker
            try:
                chapter = int(m.group(1))
            except Exception:
                chapter = 0
            verse = 0
            continue

        if m.group(2) is not None:
            verse = to_int_verse(m.group(2))
            if chapter <= 0 or verse <= 0:
                continue

            raw_segment = text[m.end() : next_start]
            cleaned = _clean_usfm_text(raw_segment)
            if not cleaned:
                continue
            out.append(
                {
                    "bookId": _canonical_book_id(usfm_id, book_name),
                    "book": book_name,
                    "chapter": chapter,
                    "verse": verse,
                    "text": cleaned,
                }
            )

    return out


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Convert a Bible USFM ZIP (WEB, KJV, etc) into a flat verse-array JSON: "
            "[{bookId, book, chapter, verse, text}, ...]"
        )
    )
    parser.add_argument("input_zip", help="Path to a USFM ZIP (download from ebible.org)")
    parser.add_argument("output_json", help="Path to write converted JSON")
    parser.add_argument(
        "--include-extra-books",
        action="store_true",
        help="Include non-66-book extras if present in the ZIP (default: skip unknown USFM book ids)",
    )
    args = parser.parse_args()

    zip_path = Path(args.input_zip)
    if not zip_path.exists():
        raise SystemExit(f"Not found: {zip_path}")

    verses: list[dict] = []
    for filename, content in _iter_usfm_files_from_zip(zip_path):
        try:
            usfm_id = _extract_usfm_id(content)
        except SystemExit:
            # Some zips include helper files; ignore those.
            continue

        if not args.include_extra_books and usfm_id not in _USFM_BOOK_FALLBACK_NAMES:
            # Skip apocrypha/extra materials by default.
            continue

        book_name = _extract_book_name(usfm_id, content)
        file_verses = _parse_usfm_to_verses(content, usfm_id, book_name)
        if file_verses:
            verses.extend(file_verses)

    if not verses:
        raise SystemExit("No verses parsed. Is this a valid USFM ZIP?")

    out_path = Path(args.output_json)
    out_path.write_text(json.dumps(verses, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {len(verses)} verses to {out_path}")


if __name__ == "__main__":
    import json

    main()
