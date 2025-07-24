import os
import re
import shutil
from pathlib import Path

# For Office to PDF conversion (Windows only)
import win32com.client as win32
from pathlib import Path
import win32com.client
from pywintypes import com_error

# Set your folder path
FOLDER_PATH = Path("intranet_crawled_docs/sustainability/files")  # Replace with your folder
OTHER_FILES_FOLDER = FOLDER_PATH / "other_file_types"

# Create subfolder if it doesn't exist
OTHER_FILES_FOLDER.mkdir(exist_ok=True)

DUP = re.compile(r"^(.*?)(?:\s*)\((\d+)\)(\.\w+)$", re.IGNORECASE)

# Step 1: Remove duplicate "(1)", "(2)" files
for f in FOLDER_PATH.iterdir():
    if f.is_file():
        m = DUP.match(f.name)
        if m:
            orig = m.group(1).strip() + m.group(3)
            if (FOLDER_PATH / orig).exists():
                print(f"🗑️ Removing duplicate: {f.name}")
                f.unlink()

# Step 2: Start COM apps once
excel = win32.gencache.EnsureDispatch("Excel.Application")
excel.Visible = False
excel.DisplayAlerts = False

ppt = win32.gencache.EnsureDispatch("PowerPoint.Application")
# Do NOT set ppt.Visible = False — PowerPoint disallows hiding its window :contentReference[oaicite:1]{index=1}

try:
    for f in FOLDER_PATH.iterdir():
        if not f.is_file():
            continue

        ext = f.suffix.lower()
        full = str(f.resolve())
        pdf = str(f.with_suffix(".pdf").resolve())

        try:
            if ext in (".xls", ".xlsx"):
                print(f"📄 Converting Excel to PDF: {f.name}")
                wb = excel.Workbooks.Open(full, ReadOnly=True)
                wb.ExportAsFixedFormat(0, pdf)
                wb.Close(False)
                shutil.move(full, OTHER_FILES_FOLDER / f.name)

            elif ext in (".ppt", ".pptx"):
                print(f"📄 Converting PowerPoint to PDF: {f.name}")
                # Use WithWindow=False to run hidden :contentReference[oaicite:2]{index=2}
                deck = ppt.Presentations.Open(full, WithWindow=False)
                deck.SaveAs(pdf, FileFormat=32)
                deck.Close()
                shutil.move(full, OTHER_FILES_FOLDER / f.name)

        except com_error as e:
            print(f"⚠️ Failed processing {f.name}: {e}")

finally:
    excel.Quit()
    ppt.Quit()

print("✅ Done.")
