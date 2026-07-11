from __future__ import annotations

import re


# Conservative KJV-oriented fixes for common speech-to-text misses. Avoid broad
# replacements like every "has" -> "hath" because they damage normal sermon speech.
KJV_FIXES: tuple[tuple[str, str], ...] = (
    ("give it", "giveth"),
    ("say it", "saith"),
    ("sayeth", "saith"),
    ("see it", "seeth"),
    ("though art", "thou art"),
    ("though shalt", "thou shalt"),
    ("though hast", "thou hast"),
    ("though wilt", "thou wilt"),
)

BOOK_ALIASES: dict[str, str] = {
    "genesis": "Genesis",
    "exodus": "Exodus",
    "leviticus": "Leviticus",
    "numbers": "Numbers",
    "deuteronomy": "Deuteronomy",
    "joshua": "Joshua",
    "judges": "Judges",
    "ruth": "Ruth",
    "first samuel": "1 Samuel",
    "one samuel": "1 Samuel",
    "second samuel": "2 Samuel",
    "two samuel": "2 Samuel",
    "first kings": "1 Kings",
    "one kings": "1 Kings",
    "second kings": "2 Kings",
    "two kings": "2 Kings",
    "first chronicles": "1 Chronicles",
    "one chronicles": "1 Chronicles",
    "second chronicles": "2 Chronicles",
    "two chronicles": "2 Chronicles",
    "ezra": "Ezra",
    "nehemiah": "Nehemiah",
    "esther": "Esther",
    "job": "Job",
    "psalm": "Psalms",
    "psalms": "Psalms",
    "proverbs": "Proverbs",
    "ecclesiastes": "Ecclesiastes",
    "song of solomon": "Song of Solomon",
    "song of songs": "Song of Solomon",
    "isaiah": "Isaiah",
    "jeremiah": "Jeremiah",
    "lamentations": "Lamentations",
    "ezekiel": "Ezekiel",
    "daniel": "Daniel",
    "hosea": "Hosea",
    "joel": "Joel",
    "amos": "Amos",
    "obadiah": "Obadiah",
    "jonah": "Jonah",
    "micah": "Micah",
    "nahum": "Nahum",
    "habakkuk": "Habakkuk",
    "zephaniah": "Zephaniah",
    "haggai": "Haggai",
    "zechariah": "Zechariah",
    "malachi": "Malachi",
    "matthew": "Matthew",
    "mark": "Mark",
    "luke": "Luke",
    "john": "John",
    "acts": "Acts",
    "romans": "Romans",
    "first corinthians": "1 Corinthians",
    "one corinthians": "1 Corinthians",
    "second corinthians": "2 Corinthians",
    "two corinthians": "2 Corinthians",
    "galatians": "Galatians",
    "ephesians": "Ephesians",
    "philippians": "Philippians",
    "colossians": "Colossians",
    "first thessalonians": "1 Thessalonians",
    "one thessalonians": "1 Thessalonians",
    "second thessalonians": "2 Thessalonians",
    "two thessalonians": "2 Thessalonians",
    "first timothy": "1 Timothy",
    "one timothy": "1 Timothy",
    "second timothy": "2 Timothy",
    "two timothy": "2 Timothy",
    "titus": "Titus",
    "philemon": "Philemon",
    "hebrews": "Hebrews",
    "james": "James",
    "first peter": "1 Peter",
    "one peter": "1 Peter",
    "second peter": "2 Peter",
    "two peter": "2 Peter",
    "first john": "1 John",
    "one john": "1 John",
    "second john": "2 John",
    "two john": "2 John",
    "third john": "3 John",
    "three john": "3 John",
    "jude": "Jude",
    "revelation": "Revelation",
}

UNITS: dict[str, int] = {
    "zero": 0,
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
    "six": 6,
    "seven": 7,
    "eight": 8,
    "nine": 9,
    "ten": 10,
    "eleven": 11,
    "twelve": 12,
    "thirteen": 13,
    "fourteen": 14,
    "fifteen": 15,
    "sixteen": 16,
    "seventeen": 17,
    "eighteen": 18,
    "nineteen": 19,
}

TENS: dict[str, int] = {
    "twenty": 20,
    "thirty": 30,
    "forty": 40,
    "fifty": 50,
    "sixty": 60,
    "seventy": 70,
    "eighty": 80,
    "ninety": 90,
}

BOOK_PATTERN = "|".join(
    re.escape(book) for book in sorted(BOOK_ALIASES, key=len, reverse=True)
)
NUMBER_WORD_PATTERN = r"(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|thirty|forty|fifty|sixty|seventy|eighty|ninety|hundred)"
NUMBER_PATTERN = rf"(?:\d{{1,3}}|{NUMBER_WORD_PATTERN}(?:[ -]+(?:and[ -]+)?{NUMBER_WORD_PATTERN})*)"
NUMBER_TOKEN_PATTERN = rf"(?:\d{{1,3}}|{NUMBER_WORD_PATTERN})"

BOOK_MAX_CHAPTERS: dict[str, int] = {
    "Genesis": 50,
    "Exodus": 40,
    "Leviticus": 27,
    "Numbers": 36,
    "Deuteronomy": 34,
    "Joshua": 24,
    "Judges": 21,
    "Ruth": 4,
    "1 Samuel": 31,
    "2 Samuel": 24,
    "1 Kings": 22,
    "2 Kings": 25,
    "1 Chronicles": 29,
    "2 Chronicles": 36,
    "Ezra": 10,
    "Nehemiah": 13,
    "Esther": 10,
    "Job": 42,
    "Psalms": 150,
    "Proverbs": 31,
    "Ecclesiastes": 12,
    "Song of Solomon": 8,
    "Isaiah": 66,
    "Jeremiah": 52,
    "Lamentations": 5,
    "Ezekiel": 48,
    "Daniel": 12,
    "Hosea": 14,
    "Joel": 3,
    "Amos": 9,
    "Obadiah": 1,
    "Jonah": 4,
    "Micah": 7,
    "Nahum": 3,
    "Habakkuk": 3,
    "Zephaniah": 3,
    "Haggai": 2,
    "Zechariah": 14,
    "Malachi": 4,
    "Matthew": 28,
    "Mark": 16,
    "Luke": 24,
    "John": 21,
    "Acts": 28,
    "Romans": 16,
    "1 Corinthians": 16,
    "2 Corinthians": 13,
    "Galatians": 6,
    "Ephesians": 6,
    "Philippians": 4,
    "Colossians": 4,
    "1 Thessalonians": 5,
    "2 Thessalonians": 3,
    "1 Timothy": 6,
    "2 Timothy": 4,
    "Titus": 3,
    "Philemon": 1,
    "Hebrews": 13,
    "James": 5,
    "1 Peter": 5,
    "2 Peter": 3,
    "1 John": 5,
    "2 John": 1,
    "3 John": 1,
    "Jude": 1,
    "Revelation": 22,
}


def clean_kjv_language(text: str) -> str:
    output = text or ""
    for wrong, right in KJV_FIXES:
        output = re.sub(
            rf"\b{re.escape(wrong)}\b",
            right,
            output,
            flags=re.IGNORECASE,
        )
    return output


def normalize_spoken_references(text: str) -> str:
    output = text or ""
    output = _normalize_chapter_verse_phrases(output)
    output = _normalize_compact_reference_phrases(output)
    return _restore_book_capitalization(output)


def clean_sermon_transcript(text: str) -> str:
    output = clean_kjv_language(text)
    output = normalize_spoken_references(output)
    output = re.sub(r"\s+([,.;:!?])", r"\1", output)
    output = re.sub(r"\s+", " ", output)
    return output.strip()


def _normalize_chapter_verse_phrases(text: str) -> str:
    pattern = re.compile(
        rf"\b(?P<book>{BOOK_PATTERN})\s+chapter\s+(?P<chapter>{NUMBER_PATTERN})(?:\s+verse\s+(?P<verse>{NUMBER_PATTERN})(?:\s*(?:through|to|-)\s*(?P<end>{NUMBER_PATTERN}))?)?\b",
        re.IGNORECASE,
    )

    def replace(match: re.Match[str]) -> str:
        book = _canonical_book(match.group("book"))
        chapter = _number_value(match.group("chapter"))
        verse_text = match.group("verse")
        if book is None or chapter is None:
            return match.group(0)
        if not verse_text:
            return f"{book} {chapter}"
        verse = _number_value(verse_text)
        if verse is None:
            return match.group(0)
        end_text = match.group("end")
        end = _number_value(end_text) if end_text else None
        suffix = f"-{end}" if end is not None else ""
        return f"{book} {chapter}:{verse}{suffix}"

    return pattern.sub(replace, text)


def _normalize_compact_reference_phrases(text: str) -> str:
    pattern = re.compile(
        rf"\b(?P<book>{BOOK_PATTERN})\s+(?P<numbers>{NUMBER_TOKEN_PATTERN}(?:[ -]+(?:and[ -]+)?{NUMBER_TOKEN_PATTERN}){{0,5}})\b",
        re.IGNORECASE,
    )

    def replace(match: re.Match[str]) -> str:
        book = _canonical_book(match.group("book"))
        numbers = _reference_numbers(book, match.group("numbers"))
        if book is None or numbers is None:
            return match.group(0)
        chapter, verse, end = numbers
        if verse is None:
            return f"{book} {chapter}"
        suffix = f"-{end}" if end is not None else ""
        return f"{book} {chapter}:{verse}{suffix}"

    return pattern.sub(replace, text)


def _reference_numbers(book: str | None, value: str) -> tuple[int, int | None, int | None] | None:
    if book is None:
        return None

    normalized = value.lower().replace("-", " ").strip()
    tokens = [token for token in normalized.split() if token != "and"]
    if not tokens:
        return None

    max_chapter = BOOK_MAX_CHAPTERS.get(book, 150)
    whole_value = _number_value(" ".join(tokens))
    if whole_value is not None and whole_value <= max_chapter:
        if len(tokens) == 1 or book == "Psalms" or _looks_like_compound_chapter(tokens):
            return whole_value, None, None

    for first_split in range(1, len(tokens)):
        chapter = _number_value(" ".join(tokens[:first_split]))
        if chapter is None or chapter < 1 or chapter > max_chapter:
            continue
        for second_split in range(first_split + 1, len(tokens) + 1):
            verse = _number_value(" ".join(tokens[first_split:second_split]))
            if verse is None or verse < 1 or verse > 176:
                continue
            end = None
            if second_split < len(tokens):
                end = _number_value(" ".join(tokens[second_split:]))
                if end is None or end < verse or end > 176:
                    continue
            return chapter, verse, end

    if whole_value is not None and 1 <= whole_value <= max_chapter:
        return whole_value, None, None
    return None


def _looks_like_compound_chapter(tokens: list[str]) -> bool:
    return len(tokens) == 2 and tokens[0] in TENS and tokens[1] in UNITS

def _restore_book_capitalization(text: str) -> str:
    output = text
    canonical_books = sorted(set(BOOK_ALIASES.values()), key=len, reverse=True)
    for book in canonical_books:
        output = re.sub(
            rf"\b{re.escape(book)}\b",
            book,
            output,
            flags=re.IGNORECASE,
        )
    return output


def _canonical_book(value: str | None) -> str | None:
    if value is None:
        return None
    key = re.sub(r"\s+", " ", value.lower()).strip()
    return BOOK_ALIASES.get(key)


def _number_value(value: str | None) -> int | None:
    if value is None:
        return None
    normalized = value.lower().replace("-", " ").strip()
    if normalized.isdigit():
        return int(normalized)

    tokens = [token for token in normalized.split() if token != "and"]
    if not tokens:
        return None

    total = 0
    current = 0
    for token in tokens:
        if token in UNITS:
            current += UNITS[token]
        elif token in TENS:
            current += TENS[token]
        elif token == "hundred":
            current = max(current, 1) * 100
        else:
            return None
    total += current
    return total if total > 0 else None
