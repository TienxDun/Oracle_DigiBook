import requests
import json
import os
import re

def sanitize_filename(name):
    return re.sub(r'[\\/*?:"<>|]', "", name).strip()

def fetch_chunk(page_id):
    url = "https://www.notion.so/api/v3/loadPageChunk"
    headers = {"Content-Type": "application/json"}
    body = {
        "pageId": page_id,
        "limit": 100,
        "cursor": {"stack": []},
        "chunkNumber": 0,
        "verticalColumns": False
    }
    r = requests.post(url, json=body, headers=headers)
    if r.status_code != 200:
        print(f"Error fetching {page_id}: {r.status_code}")
        return {}
    return r.json()

def extract_text(prop):
    if not prop: return ""
    text_out = ""
    for segment in prop:
        text = segment[0]
        mods = segment[1] if len(segment) > 1 else []
        is_bold = is_italic = is_code = is_strike = False
        link = None
        for mod in mods:
            if mod[0] == 'b': is_bold = True
            elif mod[0] == 'i': is_italic = True
            elif mod[0] == 'c': is_code = True
            elif mod[0] == 's': is_strike = True
            elif mod[0] == 'a': link = mod[1]
        
        # apply formatting
        if is_code: text = f"`{text}`"
        else:
            if is_bold: text = f"**{text}**"
            if is_italic: text = f"*{text}*"
            if is_strike: text = f"~~{text}~~"
            if link:
                if link.startswith('/'): link = f"https://hoadm.notion.site{link}"
                text = f"[{text}]({link})"
        text_out += text
    return text_out

def get_block(blocks, block_id):
    if block_id in blocks: return blocks[block_id]
    # sometimes IDs are missing hyphens
    hyphenated = f"{block_id[:8]}-{block_id[8:12]}-{block_id[12:16]}-{block_id[16:20]}-{block_id[20:]}"
    return blocks.get(hyphenated)

def parse_page(page_id, parent_dir, blocks=None):
    if not blocks:
        data = fetch_chunk(page_id)
        blocks = data.get('recordMap', {}).get('block', {})
    
    root_block_rec = get_block(blocks, page_id)
    if not root_block_rec: return
    root_block = root_block_rec.get('value', {})
    
    title_prop = root_block.get('properties', {}).get('title', [])
    page_title = extract_text(title_prop) or "Untitled"
    safe_title = sanitize_filename(page_title)
    
    page_dir = os.path.join(parent_dir, safe_title)
    os.makedirs(page_dir, exist_ok=True)
    md_file = os.path.join(page_dir, f"{safe_title}.md")
    
    print(f"Scraping: {page_title} -> {md_file}")
    md_content = f"# {page_title}\n\n"
    
    content_ids = root_block.get('content', [])
    
    for c_id in content_ids:
        b_rec = get_block(blocks, c_id)
        if not b_rec:
            # fetch missing block ? Usually not needed for children in same chunk
            continue
        
        block = b_rec.get('value', {})
        b_type = block.get('type')
        props = block.get('properties', {})
        
        if b_type == 'page':
            child_title = extract_text(props.get('title')) or "Untitled"
            md_content += f"- [📄 {child_title}](./{sanitize_filename(child_title)}/{sanitize_filename(child_title)}.md)\n\n"
            parse_page(c_id, page_dir)
            continue
            
        text = extract_text(props.get('title', []))
        
        if b_type == 'text':
            if text: md_content += f"{text}\n\n"
        elif b_type in ('header', 'sub_header', 'sub_sub_header'):
            level = '#' * ({'header': 2, 'sub_header': 3, 'sub_sub_header': 4}.get(b_type, 2))
            md_content += f"{level} {text}\n\n"
        elif b_type == 'bulleted_list':
            md_content += f"- {text}\n"
        elif b_type == 'numbered_list':
            md_content += f"1. {text}\n"
        elif b_type == 'to_do':
            checked = 'x' if props.get('checked', [['No']])[0][0] == 'Yes' else ' '
            md_content += f"- [{checked}] {text}\n"
        elif b_type == 'toggle':
            md_content += f"- **Toggle**: {text}\n"
        elif b_type == 'code':
            lang = extract_text(props.get('language', [['']]))
            md_content += f"```{lang}\n{text}\n```\n\n"
        elif b_type == 'image':
            src = extract_text(props.get('source', [['']]))
            if block.get('format', {}).get('display_source'):
                src = block['format']['display_source']
            md_content += f"![Image]({src})\n\n"
        elif b_type == 'divider':
            md_content += f"---\n\n"
        elif b_type == 'quote':
            md_content += f"> {text}\n\n"
        elif b_type == 'callout':
            icon = block.get('format', {}).get('page_icon', 'ℹ️')
            md_content += f"> {icon} {text}\n\n"
        else:
            if text:
                md_content += f"{text}\n\n"
                
    with open(md_file, 'w', encoding='utf-8') as f:
        f.write(md_content)

if __name__ == "__main__":
    start_id = "3109b786-47e0-80f0-a220-d243017f8aba"
    base_out = "notion_api_md"
    os.makedirs(base_out, exist_ok=True)
    parse_page(start_id, base_out)
    print("Done!")
