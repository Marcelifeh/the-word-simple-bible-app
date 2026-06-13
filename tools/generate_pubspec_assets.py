import argparse
import os
import re
from pathlib import Path


def _iter_book_dirs(assets_root: Path) -> list[str]:
    """Return pubspec asset entries for book directories.

    We generate entries like:
        - assets/data/bibles/web/john/

    Flutter's asset bundler will include all files within each listed directory.
    """
    results: list[str] = []

    if not assets_root.exists():
        return results

    # assets/data/bibles/<translation>/<bookId>/
    for translation_dir in sorted([p for p in assets_root.iterdir() if p.is_dir()]):
        for book_dir in sorted([p for p in translation_dir.iterdir() if p.is_dir()]):
            # Only include if it looks like it has chapter json files.
            has_json = any(book_dir.glob("*.json"))
            if not has_json:
                continue
            rel = book_dir.as_posix().rstrip("/") + "/"
            results.append(rel)

    return results


def _render_block(*, entries: list[str], indent: str, begin_marker: str, end_marker: str) -> str:
    lines: list[str] = []
    lines.append(f"{indent}{begin_marker}")
    for e in entries:
        lines.append(f"{indent}- {e}")
    lines.append(f"{indent}{end_marker}")
    return "\n".join(lines) + "\n"


def _replace_or_insert_block(*, raw: str, block: str, begin_marker: str, end_marker: str) -> str:
    begin = re.search(rf"^\s*{re.escape(begin_marker)}\s*$", raw, flags=re.MULTILINE)
    end = re.search(rf"^\s*{re.escape(end_marker)}\s*$", raw, flags=re.MULTILINE)

    if begin and end and begin.start() < end.end():
        return raw[: begin.start()] + block + raw[end.end() :]

    # Insert right after the first 'assets:' line inside flutter.
    lines = raw.splitlines(True)
    out: list[str] = []
    inserted = False
    for line in lines:
        out.append(line)
        if not inserted and re.match(r"^\s*assets:\s*$", line):
            if not line.endswith("\n"):
                out.append("\n")
            out.append(block)
            inserted = True
    if not inserted:
        raise SystemExit("pubspec.yaml: failed to insert generated block")
    return "".join(out)


def update_pubspec(pubspec_path: Path, bible_assets_root: Path, commentary_assets_root: Path) -> None:
    raw = pubspec_path.read_text(encoding="utf-8")

    # Find the flutter: assets: section indentation.
    m_flutter = re.search(r"^flutter:\s*$", raw, flags=re.MULTILINE)
    if not m_flutter:
        raise SystemExit("pubspec.yaml: missing 'flutter:' section")

    m_assets = re.search(r"^flutter:\s*\n(?:.*\n)*?^\s*assets:\s*$", raw, flags=re.MULTILINE)
    if not m_assets:
        raise SystemExit("pubspec.yaml: missing 'flutter: ... assets:' section")

    # Indent of list items under assets: is typically 4 spaces.
    indent = "    "

    bible_entries = _iter_book_dirs(bible_assets_root)
    bible_block = _render_block(
        entries=bible_entries,
        indent=indent,
        begin_marker="# BEGIN GENERATED BIBLE ASSETS",
        end_marker="# END GENERATED BIBLE ASSETS",
    )

    new_raw = _replace_or_insert_block(
        raw=raw,
        block=bible_block,
        begin_marker="# BEGIN GENERATED BIBLE ASSETS",
        end_marker="# END GENERATED BIBLE ASSETS",
    )

    # Commentary assets live under: assets/data/commentary/<style>/<translation>/<bookId>/<chapter>.json
    # We generate entries like:
    #   - assets/data/commentary/insight_premium_v2/kjv/romans/
    commentary_entries = _iter_book_dirs(commentary_assets_root)
    commentary_block = _render_block(
        entries=commentary_entries,
        indent=indent,
        begin_marker="# BEGIN GENERATED COMMENTARY ASSETS",
        end_marker="# END GENERATED COMMENTARY ASSETS",
    )

    new_raw = _replace_or_insert_block(
        raw=new_raw,
        block=commentary_block,
        begin_marker="# BEGIN GENERATED COMMENTARY ASSETS",
        end_marker="# END GENERATED COMMENTARY ASSETS",
    )

    pubspec_path.write_text(new_raw, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate pubspec.yaml asset entries for split Bible and commentary chapter folders."
    )
    parser.add_argument(
        "--pubspec",
        default="pubspec.yaml",
        help="Path to pubspec.yaml (default: pubspec.yaml)",
    )
    parser.add_argument(
        "--bible-assets-root",
        default="assets/data/bibles",
        help="Root folder containing translation/book/chapter Bible assets (default: assets/data/bibles)",
    )
    parser.add_argument(
        "--commentary-assets-root",
        default="assets/data/commentary/insight_premium_v2",
        help="Root folder containing style/translation/book/chapter commentary assets (default: assets/data/commentary/insight_premium_v2)",
    )

    args = parser.parse_args()

    pubspec_path = Path(args.pubspec)
    bible_assets_root = Path(args.bible_assets_root)
    commentary_assets_root = Path(args.commentary_assets_root)

    if not pubspec_path.exists():
        raise SystemExit(f"pubspec.yaml not found: {pubspec_path}")

    update_pubspec(
        pubspec_path=pubspec_path,
        bible_assets_root=bible_assets_root,
        commentary_assets_root=commentary_assets_root,
    )


if __name__ == "__main__":
    main()
