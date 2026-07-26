import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
base_dir = r"C:\Users\hp\OneDrive\Projects\The_word_simple_bible_app"

def repair_topics():
    topics_path = os.path.join(base_dir, r"lib\features\devotional\data\devotional_topics.dart")
    with open(topics_path, "r", encoding="utf-8") as f:
        topics_content = f.read()

    # The file has a list of DevotionalModel
    # Each starts with: // ── <num>. <THEME> ───────
    # And ends with ), before the next one or  ];

    # Let's find the start of the list
    list_start_idx = topics_content.find("static final List<DevotionalModel> all = [")
    if list_start_idx == -1:
        print("Could not find start of list")
        return

    list_start_offset = topics_content.find("[", list_start_idx) + 1

    end_marker = "  ];\n}"
    list_end_idx = topics_content.rfind(end_marker)
    if list_end_idx == -1:
        list_end_idx = topics_content.rfind("];\n}")
        if list_end_idx == -1:
            print("Could not find end marker")
            return

    header = topics_content[:list_start_offset]
    footer = topics_content[list_end_idx:]

    body = topics_content[list_start_offset:list_end_idx]

    # Split by the comment pattern
    blocks = re.split(r'(\s*// ── \d+\..*?\n)', body)

    parsed_blocks = []
    # blocks[0] is whitespace before first comment
    if blocks[0].strip():
        parsed_blocks.append(blocks[0])

    for i in range(1, len(blocks), 2):
        comment = blocks[i]
        content = blocks[i+1]

        # extract title
        match = re.search(r"title:\s*'(.+?)',", content)
        if match:
            title = match.group(1)
            parsed_blocks.append({"title": title, "comment": comment, "content": content})
        else:
            parsed_blocks.append(comment + content) # raw text

    # keep unique by title
    seen = set()
    unique_blocks = []

    seq_counter = 1

    for item in parsed_blocks:
        if isinstance(item, dict):
            if item["title"] not in seen:
                seen.add(item["title"])
                # update sequence number
                new_comment = re.sub(r'// ── \d+\.', f'// ── {seq_counter}.', item["comment"])
                unique_blocks.append(new_comment + item["content"])
                seq_counter += 1
        else:
            unique_blocks.append(item)

    new_body = "".join(unique_blocks)

    with open(topics_path, "w", encoding="utf-8") as f:
        f.write(header + new_body + footer)
    print("Repaired devotional_topics.dart")

def repair_txt():
    txt_path = os.path.join(base_dir, r"lib\features\devotional\devotionals.txt")
    with open(txt_path, "r", encoding="utf-8") as f:
        txt_content = f.read()

    # Split by "🌿 Daily Devotional:"
    parts = txt_content.split("🌿 Daily Devotional:")

    if len(parts) <= 1:
        return

    unique_parts = []
    seen = set()

    for p in parts[1:]:
        # title is first line
        title = p.splitlines()[0].strip()
        if title not in seen:
            seen.add(title)
            unique_parts.append("🌿 Daily Devotional:" + p.rstrip())

    new_txt = parts[0].rstrip() + "\n\n\n\n\n" + "\n\n\n\n\n".join(unique_parts) + "\n"

    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(new_txt)
    print("Repaired devotionals.txt")

if __name__ == "__main__":
    repair_topics()
    repair_txt()
