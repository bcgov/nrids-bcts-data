import os
import time
import glob
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import WebDriverException

# Config
START_URL = "https://intranet.gov.bc.ca/for/bcts/sustainability/advisory-bulletins-memos-advice-list"
MAX_DEPTH = 4
OUTPUT_FILE = "intranet_full_crawl.txt"
HIERARCHY_FILE = "intranet_url_tree.txt"
DOWNLOAD_FOLDER = "downloads"
visited = set()

# Create downloads folder
os.makedirs(DOWNLOAD_FOLDER, exist_ok=True)

# Configure Chrome options
chrome_options = Options()
prefs = {
    "download.default_directory": os.path.abspath(DOWNLOAD_FOLDER),
    "download.prompt_for_download": False,
    "download.directory_upgrade": True,
    "safebrowsing.enabled": True,
    "plugins.always_open_pdf_externally": True  # force download instead of viewing PDFs
}
chrome_options.add_experimental_option("prefs", prefs)

# Start WebDriver
driver = webdriver.Chrome(options=chrome_options)
driver.get(START_URL)

input("🔐 Log in via IDIR (if needed), then press Enter to start crawling...")

# Helper functions
def clean_and_extract_text(html):
    soup = BeautifulSoup(html, "html.parser")
    visible_text = soup.stripped_strings
    return " ".join(visible_text)

def is_internal_link(link, base_url):
    href = link.get('href')
    if not href:
        return False
    full_url = urljoin(base_url, href)
    parsed_full = urlparse(full_url)
    parsed_base = urlparse(START_URL)
    return (
        parsed_full.netloc == parsed_base.netloc and
        parsed_full.path.startswith(parsed_base.path)
    )

def is_downloadable_file(link):
    href = link.get('href', '')
    return href.lower().endswith((
        '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx'
    ))

def wait_for_download_to_finish(existing_files, timeout=20):
    start = time.time()
    while time.time() - start < timeout:
        current_files = set(os.listdir(DOWNLOAD_FOLDER))
        downloading = glob.glob(os.path.join(DOWNLOAD_FOLDER, "*.crdownload"))
        new_files = current_files - existing_files
        if new_files and not downloading:
            return True
        time.sleep(1)
    return False

def download_file_in_browser(file_url, indent):
    try:
        print(f"📥 Triggering download: {file_url}")
        existing_files = set(os.listdir(DOWNLOAD_FOLDER))

        driver.get(file_url)
        wait_for_login_if_needed()
        time.sleep(2)

        if wait_for_download_to_finish(existing_files):
            print("✅ Download completed")
        else:
            print("⚠️ Download timeout or still in progress")

        with open(HIERARCHY_FILE, "a", encoding="utf-8") as f:
            f.write(f"{'    ' * indent}📎 Downloaded: {file_url}\n")

    except Exception as e:
        print(f"❌ Failed to download {file_url}: {e}")

def wait_for_login_if_needed():
    page_text = driver.page_source.lower()
    if "idir" in page_text or "password" in page_text:
        input("🔒 Login prompt detected. Please complete login and press Enter to continue...")

# Recursive crawl function
def crawl(url, depth):
    if depth > MAX_DEPTH or url in visited:
        return

    try:
        driver.get(url)
        wait_for_login_if_needed()
        time.sleep(2)

        # Save extracted text
        text = clean_and_extract_text(driver.page_source)
        with open(OUTPUT_FILE, "a", encoding="utf-8") as f:
            f.write(f"\n\n--- URL: {url} ---\n{text}")

        # Log hierarchy
        with open(HIERARCHY_FILE, "a", encoding="utf-8") as f:
            f.write(f"{'    ' * depth}- {url}\n")

        visited.add(url)

        # Parse links and crawl/download
        soup = BeautifulSoup(driver.page_source, "html.parser")
        for link in soup.find_all("a", href=True):
            full_url = urljoin(url, link['href'])

            if is_downloadable_file(link):
                download_file_in_browser(full_url, depth + 1)
            elif is_internal_link(link, url):
                crawl(full_url, depth + 1)

    except WebDriverException as e:
        print(f"⚠️ Error loading {url}: {e}")

# Clear hierarchy file
with open(HIERARCHY_FILE, "w", encoding="utf-8") as f:
    f.write(f"📂 Crawl Hierarchy for: {START_URL}\n\n")

# Start crawl
crawl(START_URL, depth=0)
driver.quit()

print(f"\n✅ Done.")
print(f"📄 Text saved to: '{OUTPUT_FILE}'")
print(f"🗂️ URL hierarchy saved to: '{HIERARCHY_FILE}'")
print(f"📎 Files downloaded to: '{DOWNLOAD_FOLDER}/'")
