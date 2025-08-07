import os
import io
import sys
import time
import random
import tempfile
import pandas as pd
import psycopg2
import undetected_chromedriver as uc

from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from sqlalchemy import create_engine

import boto3
from datetime import datetime, timedelta
import time
import pandas as pd
import io
import requests

# PostgreSQL config from environment
# postgres_username = os.environ["ODS_USERNAME"]
# postgres_password = os.environ["ODS_PASSWORD"]
# postgres_host = os.environ["ODS_HOST"]
# postgres_port = os.environ["ODS_PORT"]
# postgres_database = os.environ["ODS_DATABASE"]
# postgres_schema = "bcts_staging"
# postgres_table = "bcbids_tsl_weekly_report"

URL = "https://www.bcbid.gov.bc.ca/page.aspx/en/rfp/request_browse_public"


# AWS credentials (optional if using other methods like environment variables)
aws_access_key_id = 'nr-dap-bcts'
aws_secret_access_key = 
# aws_session_token = 'your_session_token'  # Include this if using temporary security credentials

# S3 specific information
# region_name = 'your_region'  # e.g., 'us-east-1'
s3_endpoint_url = 'https://nrs.objectstore.gov.bc.ca:443'  # e.g., 'https://s3.amazonaws.com' or a custom endpoint

# S3 bucket name
bucket_name = 'wyprwt'


s3_client = boto3.client(
    's3',
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    # aws_session_token=aws_session_token,
    endpoint_url=s3_endpoint_url
)


def load_into_object_storage(df):
    try:
        url = s3_client.generate_presigned_url(
        ClientMethod='put_object',
        Params={'Bucket': 'wyprwt', 'Key': 'bcbids_tsl_weekly_report.csv'},
        ExpiresIn=24*60*60*2  # URL valid for 2 days
        )

        csv_bytes = df.to_csv(index=False).encode('utf-8')
        response = requests.put(url, data=csv_bytes)

        print(response.status_code)  # 200 means success

    except Exception as e:
        print(f"❌ Error writing to Object Storage: {e}")
        sys.exit(1)



def run_scraper():
    options = uc.ChromeOptions()
    options.headless = False  # Set True to run headless
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_argument("start-maximized")
    

    driver = uc.Chrome(options=options, version_main=138)
    wait = WebDriverWait(driver, 20)

    try:
        driver.get(URL)
        time.sleep(5)

        # Step 1: Clear default "Status" filter selection
        print("🧹 Clearing default Status filter...")
        status_section = wait.until(EC.presence_of_element_located(
            (By.CSS_SELECTOR, "div[data-iv-control='body_x_selSrfxCode']")))
        clear_btn = status_section.find_element(By.CLASS_NAME, "dropdown-clear")
        wait.until(EC.element_to_be_clickable((By.CLASS_NAME, "dropdown-clear")))
        driver.execute_script("arguments[0].click();", clear_btn)
        time.sleep(1)

        # Step 2: Filter to "Timber Auction"
        print("🔘 Selecting 'Timber Auction'...")
        dropdown = wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, "div[data-iv-control='body_x_selRtgrouCode'] .ui.dropdown")))
        dropdown.click()
        time.sleep(1)
        timber_option = wait.until(EC.element_to_be_clickable((By.ID, "body_x_selRtgrouCode_ta")))
        driver.execute_script("arguments[0].scrollIntoView(true);", timber_option)
        timber_option.click()
        time.sleep(1)

        print("🏢 Selecting 'BC Timber Sales Branch' by typing...")
        # Step 1: Click dropdown to open it
        org_dropdown = wait.until(EC.element_to_be_clickable(
            (By.CSS_SELECTOR, "div[data-iv-control='body_x_selBpmIdOrgaLevelOrgaNode'] .ui.dropdown")))
        org_dropdown.click()
        # Step 2: Find the search input inside dropdown and type text to filter options
        search_input = wait.until(EC.element_to_be_clickable(
            (By.ID, "body_x_selBpmIdOrgaLevelOrgaNode_search")))
        search_input.clear()
        search_input.send_keys("BC Timber Sales Branch")
        # Step 3: Wait for the option matching filtered text to appear and be clickable
        option_selector = "li.item[data-value='act;153']"
        bc_tim_opt = wait.until(EC.element_to_be_clickable(
            (By.CSS_SELECTOR, option_selector)))
        # Step 4: Click the filtered option
        bc_tim_opt.click()

        time.sleep(1)


        # Calculate previous week's Monday and Saturday
        today = datetime.today()
        days_since_monday = (today.weekday() - 0) % 7
        prev_monday = today - timedelta(days=days_since_monday + 7)
        prev_saturday = prev_monday + timedelta(days=5)
        min_date = prev_monday.strftime('%Y-%m-%d')
        max_date = prev_saturday.strftime('%Y-%m-%d')

        print("📆 Setting Closing Date range...")
        # Step 1: Locate and type into the Min date input
        closing_date_min = wait.until(EC.presence_of_element_located((By.ID, "body_x_txtRfpEndDate")))
        closing_date_min.clear()
        closing_date_min.send_keys(min_date)
        # Step 2: Locate and type into the Max date input
        closing_date_max = wait.until(EC.presence_of_element_located((By.ID, "body_x_txtRfpEndDatemax")))
        closing_date_max.clear()
        closing_date_max.send_keys(max_date)
        time.sleep(1)


        # Step 3: Click Search
        print("🔍 Clicking Search...")
        search_btn = wait.until(EC.element_to_be_clickable((By.ID, "body_x_prxFilterBar_x_cmdSearchBtn")))
        search_btn.click()
        time.sleep(3)

        # Step 4: Wait for results
        wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "table.table thead tr")))
        headers = [h.text.strip() for h in driver.find_elements(By.CSS_SELECTOR, "table.table thead tr th") if h.text.strip()]
        print(f"📋 Headers: {headers}")

        all_data, page = [], 1
        while True:
            print(f"📄 Scraping page {page}")
            rows = driver.find_elements(By.CSS_SELECTOR, "table.table tbody tr")
            for row in rows:
                cols = row.find_elements(By.TAG_NAME, "td")
                if len(cols) == len(headers):
                    row_data = {headers[i]: cols[i].text.strip() for i in range(len(headers))}
                    all_data.append(row_data)
                else:
                    print(f"⚠️ Skipped row with {len(cols)} cols (expected {len(headers)})")

            try:
                next_btn = driver.find_element(By.ID, "body_x_grid_gridPagerBtnNextPage")
                if "disabled" in next_btn.get_attribute("class").lower():
                    break
                next_btn.click()
                time.sleep(random.uniform(2, 4))
                page += 1
            except:
                break

        df = pd.DataFrame(all_data)
        if df.empty:
            print("⚠️ No data found.")
            return

        load_into_object_storage(df)
        print(f"✅ Done. Scraped {len(df)} rows from {page} pages.")

    finally:
        if driver:
            driver.quit()
            del driver  # ← this prevents __del__ from trying again later

if __name__ == "__main__":
    run_scraper()
