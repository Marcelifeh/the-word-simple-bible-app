import os
import re
import sys

# Reconfigure stdout to use UTF-8
sys.stdout.reconfigure(encoding='utf-8')

def clean_reference(ref):
    ref = ref.strip()
    ref = re.sub(r'^[—–-]\s*', '', ref)
    ref = re.sub(r'^(Book of|Epistle to the|Epistle of|First Epistle to the|First Epistle of|Second Epistle to the|Second Epistle to|Second Epistle of|Gospel of)\s+', '', ref)
    return ref

def parse_scripture_focus(content):
    lines = [line.strip() for line in content.splitlines() if line.strip()]
    scripture_line = ""
    for line in lines:
        if line.startswith(">") or "—" in line:
            scripture_line = line
            break
    if not scripture_line:
        scripture_line = lines[-1]
        
    match = re.search(r'(?:>\s*)?[“"\'«](.*)[”"\'»]\s*[—–-]\s*(.*)', scripture_line)
    if match:
        quote = match.group(1).strip()
        ref = match.group(2).strip()
    else:
        parts = scripture_line.split("—")
        if len(parts) > 1:
            quote = "—".join(parts[:-1]).strip().strip('>').strip().strip('“').strip('”').strip('"')
            ref = parts[-1].strip()
        else:
            quote = scripture_line.strip('>').strip().strip('“').strip('”').strip('"')
            ref = "Unknown"
            
    quote = quote.strip('“').strip('”').strip('"').strip('‘').strip('’').strip("'")
    
    orig_ref = ref
    if "Second Epistle to the" in orig_ref or "Second Epistle to" in orig_ref or "Second Epistle of" in orig_ref:
        ref_clean = clean_reference(orig_ref)
        ref = f"2 {ref_clean}"
    elif "First Epistle to the" in orig_ref or "First Epistle to" in orig_ref or "First Epistle of" in orig_ref:
        ref_clean = clean_reference(orig_ref)
        ref = f"1 {ref_clean}"
    else:
        ref = clean_reference(orig_ref)
        
    return quote, ref

def wrap_text_to_dart(text, indent_spaces):
    text = text.replace('\r\n', '\n').replace('\r', '\n')
    wrapped_lines = []
    paragraphs = text.split('\n')
    for p in paragraphs:
        if not p.strip():
            wrapped_lines.append("")
            continue
            
        words = p.split(' ')
        current_line = []
        current_len = 0
        for word in words:
            if current_len + len(word) + 1 > 70:
                wrapped_lines.append(" ".join(current_line))
                current_line = [word]
                current_len = len(word)
            else:
                current_line.append(word)
                current_len += len(word) + 1
        if current_line:
            wrapped_lines.append(" ".join(current_line))
            
    dart_lines = []
    for idx, wl in enumerate(wrapped_lines):
        wl_escaped = wl.replace('\\', '\\\\').replace("'", "\\'")
        is_last = (idx == len(wrapped_lines) - 1)
        next_wl = wrapped_lines[idx+1] if not is_last else None
        
        if is_last:
            suffix = ""
        elif wl == "" or next_wl == "":
            suffix = "\\n"
        else:
            suffix = " "
            
        dart_lines.append(f"{' ' * indent_spaces}'{wl_escaped}{suffix}'")
        
    return "\n".join(dart_lines)

def parse_single_devotional(block):
    header_patterns = [
        ("scripture", r'📖 Scripture Focus'),
        ("sec1", r'(?:🔑\s*)?1\.\s+'),
        ("sec2", r'(?:🔍\s*)?2\.\s+'),
        ("sec3", r'(?:⚔️\s*)?3\.\s+'),
        ("sec4", r'(?:🌱\s*)?4\.\s+'),
        ("sec5", r'(?:🚶\s*)?5\.\s+'),
        ("revelation", r'✨ Final Revelation'),
        ("reflection", r'🌅 Closing Reflection'),
        ("prayer", r'🙏 Prayer')
    ]
    
    positions = []
    for name, pattern in header_patterns:
        match = re.search(pattern, block)
        if match:
            positions.append((name, match.start(), match.end(), match.group(0)))
        else:
            print(f"Error: Could not find header pattern '{pattern}' in block.")
            return None
            
    positions.sort(key=lambda x: x[1])
    
    if len(positions) != 9:
        print(f"Error: Found {len(positions)} headers instead of 9.")
        return None
        
    title_text = block[:positions[0][1]].strip()
    title_line = title_text.splitlines()[0] if title_text else ""
    title = title_line.replace("🌿 Daily Devotional:", "").replace("🌿", "").strip()
    
    parts = {}
    for idx in range(len(positions)):
        current_name, current_start, current_end, current_text = positions[idx]
        next_start = positions[idx+1][1] if idx + 1 < len(positions) else len(block)
        
        content = block[current_end:next_start].strip()
        parts[current_name] = {
            'header': current_text.strip(),
            'content': content
        }
        
    return title, parts

def parse_devotionals_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
    
    content = content.replace('\r\n', '\n').replace('\r', '\n')
    
    # Split by main title line
    blocks = []
    current = []
    for line in content.splitlines():
        if line.strip().startswith("🌿 Daily Devotional:"):
            if current:
                blocks.append("\n".join(current))
                current = []
        current.append(line)
    if current:
        blocks.append("\n".join(current))
        
    parsed = []
    for b in blocks:
        if not b.strip():
            continue
        res = parse_single_devotional(b)
        if res:
            title, parts = res
            
            # Parse scripture focus
            scripture_quote, scripture_ref = parse_scripture_focus(parts['scripture']['content'])
            
            # Parse sections
            sections = []
            for sec_key in ['sec1', 'sec2', 'sec3', 'sec4', 'sec5']:
                sec_content = parts[sec_key]['content']
                lines = sec_content.splitlines()
                heading = lines[0].strip()
                body = "\n".join(lines[1:]).strip()
                body = re.sub(r'\n\s*\n', '\n\n', body)
                
                icon = parts[sec_key]['header'].split()[0]
                sections.append({
                    'icon': icon,
                    'heading': heading,
                    'body': body
                })
                
            # Parse final revelation
            revelation = parts['revelation']['content']
            revelation = re.sub(r'\s+', ' ', revelation)
            
            # Parse reflection questions
            reflection_content = parts['reflection']['content']
            questions = []
            for q in reflection_content.splitlines():
                q = q.strip()
                if q.startswith('-') or q.startswith('•') or q.startswith('*') or (q and q[0].isdigit()):
                    q = re.sub(r'^[-•*\d\.\s]+', '', q).strip()
                if q.endswith('?'):
                    questions.append(q)
            if not questions:
                # Fallback: take all lines ending in question marks or non-empty lines
                for q in reflection_content.splitlines():
                    q = q.strip()
                    if q:
                        questions.append(q)
                        
            # Parse prayer
            prayer = parts['prayer']['content']
            prayer = re.sub(r'\n\s*\n', '\n\n', prayer)
            
            parsed.append({
                'title': title,
                'scripture': scripture_quote,
                'scriptureReference': scripture_ref,
                'sections': sections,
                'finalRevelation': revelation,
                'reflectionQuestions': questions,
                'prayer': prayer
            })
            
    return parsed

def main():
    scratch_path = r"c:\Users\hp\The_word_simple_bible_app\scratch_devotionals.txt"
    parsed_devs = parse_devotionals_file(scratch_path)
    print(f"Parsed {len(parsed_devs)} devotionals successfully.")
    
    if len(parsed_devs) != 9:
        print(f"Error: expected 9 devotionals, got {len(parsed_devs)}.")
        sys.exit(1)
        
    # Hardcoded metadata for the 9 devotionals
    devotional_meta = [
        {"id": "stability", "theme": "Trust", "year": 2024, "month": 2, "day": 8},
        {"id": "invisible_battle", "theme": "Warfare", "year": 2024, "month": 2, "day": 9},
        {"id": "gods_attention", "theme": "Love", "year": 2024, "month": 2, "day": 10},
        {"id": "debt_cancelled", "theme": "Grace", "year": 2024, "month": 2, "day": 11},
        {"id": "faithful_fire", "theme": "Endurance", "year": 2024, "month": 2, "day": 12},
        {"id": "chosen_shine", "theme": "Identity", "year": 2024, "month": 2, "day": 13},
        {"id": "beyond_fear", "theme": "Peace", "year": 2024, "month": 2, "day": 14},
        {"id": "ascended_victory", "theme": "Victory", "year": 2024, "month": 2, "day": 15},
        {"id": "god_speaks_surely", "theme": "Promises", "year": 2024, "month": 2, "day": 16}
    ]
    
    # 1. Modify devotionals.txt
    formatted_devs_txt = []
    for d in parsed_devs:
        sections_txt = []
        for idx, s in enumerate(d['sections'], 1):
            sections_txt.append(f"{s['icon']} {idx}. {s['heading']}\n{s['body']}")
            
        questions_txt = "\n".join(d['reflectionQuestions'])
        
        dev_txt = f"""🌿 Daily Devotional: {d['title']}
📖 Scripture Focus
> “{d['scripture']}” — {d['scriptureReference']}
---
""" + "\n---\n".join(sections_txt) + f"""
---
✨ Final Revelation
{d['finalRevelation']}
---
🌅 Closing Reflection
{questions_txt}
---
🙏 Prayer
{d['prayer']}"""
        formatted_devs_txt.append(dev_txt)
        
    devotionals_path = r"c:\Users\hp\The_word_simple_bible_app\lib\features\devotional\devotionals.txt"
    with open(devotionals_path, "r", encoding="utf-8") as f:
        devotionals_content = f.read()
    
    devotionals_content = devotionals_content.replace('\r\n', '\n').replace('\r', '\n')
    if not devotionals_content.endswith("\n"):
        devotionals_content += "\n"
        
    # Append the new formatted devotionals separated by 5 newlines
    new_text_to_append = "\n\n\n\n\n" + "\n\n\n\n\n".join(formatted_devs_txt) + "\n"
    modified_devotionals = devotionals_content.rstrip() + new_text_to_append
    
    with open(devotionals_path, "w", encoding="utf-8") as f:
        f.write(modified_devotionals)
    print(f"Successfully appended {len(parsed_devs)} devotionals to {devotionals_path}")
    
    # 2. Modify devotional_topics.dart
    dart_blocks = []
    for i, d in enumerate(parsed_devs):
        meta = devotional_meta[i]
        
        sections_str = []
        for s in d['sections']:
            heading_wrapped = wrap_text_to_dart(s['heading'], 14)
            body_wrapped = wrap_text_to_dart(s['body'], 14)
            sec_code = f"""        DevotionalSection(
          icon: '{s['icon']}',
          heading:
{heading_wrapped},
          body:
{body_wrapped},
        ),"""
            sections_str.append(sec_code)
            
        sections_joined = "\n".join(sections_str)
        scripture_wrapped = wrap_text_to_dart(d['scripture'], 10)
        final_rev_wrapped = wrap_text_to_dart(d['finalRevelation'], 10)
        
        questions_str = []
        for q in d['reflectionQuestions']:
            q_wrapped = wrap_text_to_dart(q, 8)
            questions_str.append(f"        {q_wrapped.strip()},")
        questions_joined = "\n".join(questions_str)
        
        prayer_wrapped = wrap_text_to_dart(d['prayer'], 10)
        
        # Determine the sequence number
        seq_num = 38 + i + 1
        
        block_code = f"""    // ── {seq_num}. {meta['theme'].upper()} ──────────────────────────────────────────────────
    DevotionalModel(
      id: '{meta['id']}',
      theme: '{meta['theme']}',
      title: '{d['title'].replace("'", "\\'")}',
      scripture:
{scripture_wrapped},
      scriptureReference: '{d['scriptureReference']}',
      sections: const [
{sections_joined}
      ],
      finalRevelation:
{final_rev_wrapped},
      reflectionQuestions: const [
{questions_joined}
      ],
      prayer:
{prayer_wrapped},
      createdAt: DateTime({meta['year']}, {meta['month']}, {meta['day']}),
    ),"""
        dart_blocks.append(block_code)
        
    dart_to_insert = "\n\n" + "\n\n".join(dart_blocks) + "\n"
    
    topics_path = r"c:\Users\hp\The_word_simple_bible_app\lib\features\devotional\data\devotional_topics.dart"
    with open(topics_path, "r", encoding="utf-8") as f:
        topics_content = f.read()
        
    topics_content = topics_content.replace('\r\n', '\n').replace('\r', '\n')
    
    end_marker = "  ];\n}"
    if end_marker not in topics_content:
        end_marker = "];\n}"
        if end_marker not in topics_content:
            print("Error: Could not locate end marker ];} in devotional_topics.dart")
            sys.exit(1)
            
    split_idx = topics_content.rfind(end_marker)
    modified_topics = topics_content[:split_idx] + dart_to_insert + "  ];\n}\n"
    
    with open(topics_path, "w", encoding="utf-8") as f:
        f.write(modified_topics)
    print(f"Successfully appended {len(parsed_devs)} devotionals to {topics_path}")

if __name__ == "__main__":
    main()
