import os
import time
import glob
from urllib.parse import urljoin, urlparse
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import WebDriverException

# Config
START_URL = "https://intranet.gov.bc.ca/csnr/csnr-services/procurement-contract-management-support/learning-tools-and-resources/a-z-index"
MAX_DEPTH = 2
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



def is_internal_link(link, base_url, start_url):
    href = link.get('href')
    print(f"is_internal_link called. {link}")
    if not href or href.startswith('#'):
        print("False")
        return False  # exclude empty and fragment-only links        

    try:
        full_url = urljoin(base_url, href)
        parsed_full = urlparse(full_url)
        parsed_base = urlparse(start_url)

        # must have same domain
        if parsed_full.netloc != parsed_base.netloc:
            print("True")
            return True  # internal to gov.bc.ca but different subdomain

        # check if link path is upstream of base path
        base_path = parsed_base.path.rstrip('/')
        full_path = parsed_full.path.rstrip('/')

        if not full_path.startswith(base_path):
            # if the link is upstream of the base, return False
            if base_path.startswith(full_path):
                print("False")
                return False
        print("True")
        return True
    except Exception:
        print("False")
        return False

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
        # wait_for_login_if_needed()
        # time.sleep(2)

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

from bs4 import BeautifulSoup
from urllib.parse import urljoin
from selenium.common.exceptions import WebDriverException

def extract_main_content(soup):
    # Remove top/side/footer sections
    for tag in soup.select("header, nav, footer, aside, .sidebar, .menu, .navbar"):
        tag.decompose()

    # Try to find <main> first
    main = soup.find("main")
    if main:
        return main

    # Otherwise pick the largest div/section/article with "content" or "main" in id/class
    candidates = soup.find_all(
        lambda tag: tag.name in ["div", "section", "article"]
        and any(k in (tag.get("id", "") + " ".join(tag.get("class", []))).lower()
                for k in ["content", "main", "body", "article"])
    )
    if candidates:
        return max(candidates, key=lambda t: len(t.get_text(strip=True)))

    return soup.body or soup  # fallback


# Recursive crawl function
def crawl(url, depth):
    visited.add(url)
    print(f"URL:{url}, DEPTH: {depth}")
    if depth > MAX_DEPTH:
        return

    try:
        driver.get(url)

        # Save extracted text
        text = clean_and_extract_text(driver.page_source)
        with open(OUTPUT_FILE, "a", encoding="utf-8") as f:
            f.write(f"\n\n--- URL: {url} ---\n{text}")

        # Log hierarchy
        with open(HIERARCHY_FILE, "a", encoding="utf-8") as f:
            f.write(f"{'    ' * depth}- {url}\n")

        # Parse page and extract only main content
        soup = BeautifulSoup(driver.page_source, "html.parser")
        main_content = extract_main_content(soup)
        if not main_content:
            return

        # Find all links within main content
        for link in main_content.find_all("a", href=True):
            href = link.get("href")
            if not href or href.startswith("#"):
                continue  # skip empty or same-page anchors

            full_url = urljoin(url, href)
            print(full_url, depth, MAX_DEPTH)

            # Handle downloadable files
            if is_downloadable_file(link) and full_url not in visited:
                print("Downloadable")
                download_file_in_browser(full_url, depth + 1)
                visited.add(full_url)

            # Handle internal crawlable links
            elif depth < MAX_DEPTH and is_internal_link(link, url, START_URL) and full_url not in visited:
                print("Crawlable")
                crawl(full_url, depth + 1)

            else:
                print("Max depth reached or already visited/downloaded")

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
