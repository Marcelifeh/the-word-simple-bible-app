#!/usr/bin/env python3
"""Copy devotional paragraph breaks from devotionals.txt into the Dart catalog.

The source text file already has the intended paragraph boundaries: each
non-empty content line is one paragraph. This script matches entries by
devotional title and section heading, then rewrites:

* DevotionalSection.body
* DevotionalModel.prayer

Run without ``--write`` for a dry run. Run with ``--write`` to update
``lib/features/devotional/data/devotional_topics.dart``.
"""

from __future__ import annotations

import argparse
import difflib
import re
from dataclasses import dataclass
from pathlib import Path


DEFAULT_TARGET = Path("lib/features/devotional/data/devotional_topics.dart")
DEFAULT_SOURCE = Path("lib/features/devotional/devotionals.txt")
TITLE_PREFIX = "🌿 Daily Devotional:"
SECTION_RE = re.compile(r"^\S+\s+\d+\.\s+(.+?)\s*$")
STOP_RE = re.compile(
    r"^(?:📖\s+Scripture Focus|✨\s+Final Revelation|🌅\s+Closing Reflection|🙏\s+Prayer)\s*$"
)


@dataclass(frozen=True)
class ParsedStringExpression:
    start: int
    end: int
    text: str
    literal_indent: int


@dataclass
class SourceDevotional:
    title: str
    sections: dict[str, str]
    prayer: str | None = None


def canonical(text: str) -> str:
    replacements = {
        "’": "'",
        "‘": "'",
        "“": '"',
        "”": '"',
        "—": "-",
        "–": "-",
        "\uFE0F": "",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    text = re.sub(r"\s+", " ", text)
    return text.strip().lower()


def is_separator(line: str) -> bool:
    return line.strip() in {"---", "—", "–", "-"}


def clean_content_lines(lines: list[str]) -> str:
    paragraphs = [
        re.sub(r"\s+", " ", line).strip()
        for line in lines
        if line.strip() and not is_separator(line)
    ]
    return "\n".join(paragraphs)


def normalize_paragraph_newlines(text: str) -> str:
    """Remove spaces around paragraph newline markers without changing words."""
    return "\n".join(part.strip() for part in text.split("\n"))


def parse_source_devotionals(source: Path) -> dict[str, SourceDevotional]:
    content = source.read_text(encoding="utf-8").replace("\r\n", "\n")
    blocks = re.split(rf"(?=^{re.escape(TITLE_PREFIX)})", content, flags=re.MULTILINE)
    devotionals: dict[str, SourceDevotional] = {}

    for block in blocks:
        lines = block.splitlines()
        if not lines or not lines[0].startswith(TITLE_PREFIX):
            continue

        title = lines[0].split(TITLE_PREFIX, 1)[1].strip()
        current_section: str | None = None
        current_lines: list[str] = []
        in_prayer = False
        prayer_lines: list[str] = []
        devotional = SourceDevotional(title=title, sections={})

        def flush_section() -> None:
            nonlocal current_section, current_lines
            if current_section is not None:
                body = clean_content_lines(current_lines)
                if body:
                    devotional.sections[canonical(current_section)] = body
            current_section = None
            current_lines = []

        for line in lines[1:]:
            section_match = SECTION_RE.match(line)
            if section_match:
                flush_section()
                in_prayer = False
                current_section = section_match.group(1).strip()
                current_lines = []
                continue

            if line.strip() == "🙏 Prayer":
                flush_section()
                in_prayer = True
                prayer_lines = []
                continue

            if STOP_RE.match(line):
                flush_section()
                in_prayer = False
                continue

            if line.startswith(TITLE_PREFIX):
                break

            if in_prayer:
                prayer_lines.append(line)
            elif current_section is not None:
                current_lines.append(line)

        flush_section()
        prayer = clean_content_lines(prayer_lines)
        if prayer:
            devotional.prayer = prayer
        devotionals[canonical(title)] = devotional

    return devotionals


def decode_dart_single_quoted(literal: str) -> str:
    result: list[str] = []
    i = 0
    while i < len(literal):
        char = literal[i]
        if char != "\\" or i + 1 >= len(literal):
            result.append(char)
            i += 1
            continue

        nxt = literal[i + 1]
        if nxt == "n":
            result.append("\n")
        elif nxt == "r":
            result.append("\r")
        elif nxt == "t":
            result.append("\t")
        elif nxt in {"\\", "'"}:
            result.append(nxt)
        else:
            result.append("\\" + nxt)
        i += 2

    return "".join(result)


def escape_dart_single_quoted(text: str) -> str:
    return text.replace("\\", "\\\\").replace("'", "\\'")


def line_column(text: str, index: int) -> int:
    line_start = text.rfind("\n", 0, index) + 1
    return index - line_start


def skip_ws(text: str, index: int) -> int:
    while index < len(text) and text[index].isspace():
        index += 1
    return index


def parse_string_expression(text: str, index: int) -> ParsedStringExpression | None:
    index = skip_ws(text, index)
    if index >= len(text) or text[index] != "'":
        return None

    start = index
    literal_indent = line_column(text, index)
    chunks: list[str] = []

    while True:
        index = skip_ws(text, index)
        if index >= len(text) or text[index] != "'":
            break

        index += 1
        literal_start = index
        escaped = False
        while index < len(text):
            char = text[index]
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == "'":
                break
            index += 1

        if index >= len(text):
            raise ValueError("Unterminated Dart string literal")

        chunks.append(decode_dart_single_quoted(text[literal_start:index]))
        index += 1
        after_literal = skip_ws(text, index)
        if after_literal >= len(text) or text[after_literal] != "'":
            index = after_literal
            break
        index = after_literal

    return ParsedStringExpression(
        start=start,
        end=index,
        text="".join(chunks),
        literal_indent=literal_indent,
    )


def wrap_dart_string(text: str, indent: int, width: int = 72) -> str:
    paragraphs = [part.strip() for part in text.split("\n")]
    lines: list[str] = []

    for paragraph_index, paragraph in enumerate(paragraphs):
        words = paragraph.split()
        wrapped: list[str] = []
        current: list[str] = []
        current_len = 0

        for word in words:
            next_len = len(word) if not current else current_len + 1 + len(word)
            if current and next_len > width:
                wrapped.append(" ".join(current))
                current = [word]
                current_len = len(word)
            else:
                current.append(word)
                current_len = next_len

        wrapped.append(" ".join(current))
        for line_index, line in enumerate(wrapped):
            is_last_wrapped_line = line_index == len(wrapped) - 1
            is_last_paragraph = paragraph_index == len(paragraphs) - 1
            suffix = ""
            if not is_last_wrapped_line:
                suffix = " "
            elif not is_last_paragraph:
                suffix = "\\n"
            lines.append(f"{' ' * indent}'{escape_dart_single_quoted(line)}{suffix}'")

    return "\n".join(lines)


def scan_matching_paren(text: str, open_index: int) -> int:
    depth = 0
    in_string = False
    escaped = False
    i = open_index

    while i < len(text):
        char = text[i]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == "'":
                in_string = False
        else:
            if char == "'":
                in_string = True
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1

    raise ValueError("Could not find matching closing parenthesis")


def find_invocation_blocks(text: str, name: str, start: int = 0, end: int | None = None):
    end = len(text) if end is None else end
    pattern = re.compile(rf"\b{re.escape(name)}\s*\(")
    for match in pattern.finditer(text, start, end):
        open_index = text.find("(", match.start(), match.end())
        close_index = scan_matching_paren(text, open_index)
        yield match.start(), close_index + 1


def parse_named_string(block: str, field: str) -> tuple[ParsedStringExpression, str] | None:
    match = re.search(rf"\b{re.escape(field)}\s*:", block)
    if not match:
        return None
    parsed = parse_string_expression(block, match.end())
    if parsed is None:
        return None
    return parsed, parsed.text


def repair_content(
    content: str,
    source_devotionals: dict[str, SourceDevotional],
) -> tuple[str, dict[str, int]]:
    replacements: list[tuple[int, int, str]] = []
    stats = {
        "models": 0,
        "matched_models": 0,
        "section_bodies": 0,
        "prayers": 0,
        "missing_source": 0,
        "missing_sections": 0,
    }

    for model_start, model_end in find_invocation_blocks(content, "DevotionalModel"):
        stats["models"] += 1
        model = content[model_start:model_end]
        title_result = parse_named_string(model, "title")
        if title_result is None:
            continue
        _, title = title_result
        source_devotional = source_devotionals.get(canonical(title))
        if source_devotional is None:
            stats["missing_source"] += 1
        else:
            stats["matched_models"] += 1

        for section_start, section_end in find_invocation_blocks(
            content, "DevotionalSection", model_start, model_end
        ):
            section = content[section_start:section_end]
            heading_result = parse_named_string(section, "heading")
            body_match = re.search(r"\bbody\s*:", section)
            if heading_result is None or body_match is None:
                continue
            _, heading = heading_result

            parsed_body = parse_string_expression(section, body_match.end())
            if parsed_body is None:
                continue
            source_body = None
            if source_devotional is not None:
                source_body = source_devotional.sections.get(canonical(heading))
                if source_body is None:
                    stats["missing_sections"] += 1
            desired_body = source_body or normalize_paragraph_newlines(parsed_body.text)
            if parsed_body.text == desired_body:
                continue
            absolute_start = section_start + parsed_body.start
            absolute_end = section_start + parsed_body.end
            replacement = wrap_dart_string(
                desired_body,
                parsed_body.literal_indent,
            )
            replacements.append((absolute_start, absolute_end, replacement))
            stats["section_bodies"] += 1

        prayer_match = re.search(r"\bprayer\s*:", model)
        if prayer_match:
            parsed_prayer = parse_string_expression(model, prayer_match.end())
            if parsed_prayer is not None:
                desired_prayer = (
                    source_devotional.prayer
                    if source_devotional is not None and source_devotional.prayer
                    else normalize_paragraph_newlines(parsed_prayer.text)
                )
                if parsed_prayer.text == desired_prayer:
                    continue
                absolute_start = model_start + parsed_prayer.start
                absolute_end = model_start + parsed_prayer.end
                replacement = wrap_dart_string(
                    desired_prayer,
                    parsed_prayer.literal_indent,
                )
                replacements.append((absolute_start, absolute_end, replacement))
                stats["prayers"] += 1

    repaired_parts: list[str] = []
    cursor = 0
    for start, end, replacement in sorted(replacements):
        repaired_parts.append(content[cursor:start])
        repaired_parts.append(replacement)
        cursor = end
    repaired_parts.append(content[cursor:])
    return "".join(repaired_parts), stats


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", type=Path, default=DEFAULT_TARGET)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--diff", action="store_true")
    args = parser.parse_args()

    original = args.target.read_text(encoding="utf-8")
    newline = "\r\n" if "\r\n" in original else "\n"
    normalized = original.replace("\r\n", "\n")
    source_devotionals = parse_source_devotionals(args.source)

    repaired, stats = repair_content(normalized, source_devotionals)
    if newline == "\r\n":
        repaired = repaired.replace("\n", "\r\n")

    print(f"Parsed {len(source_devotionals)} source devotional(s).")
    print(f"Matched {stats['matched_models']} of {stats['models']} Dart model(s).")
    print(f"Updated {stats['section_bodies']} section body field(s).")
    print(f"Updated {stats['prayers']} prayer field(s).")
    print(f"Missing source title(s): {stats['missing_source']}.")
    print(f"Missing source section(s): {stats['missing_sections']}.")

    if args.diff and repaired != original:
        diff = difflib.unified_diff(
            original.splitlines(keepends=True),
            repaired.splitlines(keepends=True),
            fromfile=str(args.target),
            tofile=str(args.target),
        )
        print("".join(diff))

    if args.write and repaired != original:
        args.target.write_text(repaired, encoding="utf-8", newline="")
        print(f"Wrote {args.target}.")
    elif not args.write:
        print("Dry run only. Re-run with --write to update the file.")


if __name__ == "__main__":
    main()
