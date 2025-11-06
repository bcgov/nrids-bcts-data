import os
import re
import random
from urllib.parse import urlparse

INPUT_FILE = "./intranet_full_crawl.txt"   # your large text file
OUTPUT_FOLDER = "./bcts_chatbot_additional_context_procurement_contracts_2025_11_05/"    # folder to save individual files
MIN_TEXT_LENGTH = 50  
MAX_FILENAME_LEN = 75  # updated limit

os.makedirs(OUTPUT_FOLDER, exist_ok=True)

with open(INPUT_FILE, "r", encoding="utf-8") as f:
    content = f.read()

entries = re.split(r'--- URL: (.+?) ---', content)[1:]

for i in range(0, len(entries), 2):
    url = entries[i].strip()
    text = entries[i+1].strip()

    if url.startswith("mailto:") or len(text) < MIN_TEXT_LENGTH:
        continue

    # Replace Windows-reserved and unsafe characters
    safe_url = re.sub(r'[<>:"/\\|?*&]', '_', url)
    safe_url = re.sub(r'_+', '_', safe_url)  # collapse multiple underscores

    # Truncate if too long
    if len(safe_url) > MAX_FILENAME_LEN:
        parsed = urlparse(url)
        last_part = os.path.basename(parsed.path.strip("/"))
        if not last_part:
            last_part = "file"
        safe_last = re.sub(r'[<>:"/\\|?*&]', '_', last_part)
        safe_last = re.sub(r'_+', '_', safe_last)
        safe_url = safe_url[-(MAX_FILENAME_LEN - len(safe_last)):] + safe_last

    # Strip leading non-alphanumeric characters
    safe_url = re.sub(r'^[^A-Za-z0-9]+', '', safe_url)

    if not safe_url:  # fallback if name becomes empty
        safe_url = "file"

    filename = safe_url + ".txt"
    filepath = os.path.join(OUTPUT_FOLDER, filename)

    # Ensure unique filename
    while os.path.exists(filepath):
        rand_num = random.randint(1000, 9999)
        filename = f"{safe_url}_{rand_num}.txt"
        filepath = os.path.join(OUTPUT_FOLDER, filename)

    # Limit path length for Windows
    if len(filepath) > 200:
        filepath = filepath[:200]

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(text)

    print(f"Saved: {filepath}")
