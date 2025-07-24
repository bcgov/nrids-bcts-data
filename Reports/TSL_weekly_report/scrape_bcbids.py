from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import pandas as pd

URL = 'https://www.bcbid.gov.bc.ca/page.aspx/en/rfp/request_browse_public'

options = Options()
options.headless = True
driver = webdriver.Chrome(service=Service(), options=options)
wait = WebDriverWait(driver, 15)

try:
    driver.get(URL)
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, "table.table tbody tr")))

    all_data = []
    page = 1

    while True:
        print(f"🔄 Scraping page {page}")
        wait.until(EC.presence_of_all_elements_located((By.CSS_SELECTOR, "table.table tbody tr")))
        rows = driver.find_elements(By.CSS_SELECTOR, "table.table tbody tr")

        for row in rows:
            cols = row.find_elements(By.TAG_NAME, "td")
            if len(cols) >= 5:
                all_data.append({
                    "Number": cols[0].text.strip(),
                    "Name": cols[1].text.strip(),
                    "Buyer": cols[2].text.strip(),
                    "Close Date": cols[3].text.strip(),
                    "Status": cols[4].text.strip()
                })

        # Check if Next button exists and is enabled
        try:
            next_btn = driver.find_element(By.ID, "body_x_grid_gridPagerBtnNextPage")
            if 'disabled' in next_btn.get_attribute('class').lower():
                break
            next_btn.click()
            time.sleep(2)
            page += 1
        except:
            break  # No more pages

    # Save results
    df = pd.DataFrame(all_data)
    df.to_csv("bcbid_all_rfps.csv", index=False)
    print(f"\n✅ Done. Scraped {len(df)} total records across {page} pages.")

finally:
    driver.quit()
