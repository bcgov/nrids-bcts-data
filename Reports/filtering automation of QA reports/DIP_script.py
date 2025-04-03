import numpy as np
import pandas as pd
from datetime import datetime
import glob
from openpyxl import load_workbook
import string
import warnings
import os
import sys
warnings.filterwarnings('ignore')
pd.set_option('future.no_silent_downcasting', True)

# Make a list of all the regions and their respective business areas 
area_list = {
    'North Interior': [
        'Babine (TBA)','Peace-Liard (TPL)', 'Prince George (TPG)', 'Skeena (TSK)', 'Stuart-Nechako (TSN)'
        ],
    'South Interior': [
        'Cariboo-Chilcotin (TCC)', 'Kamloops (TKA)', 'Kootenay (TKO)', 'Okanagan-Columbia (TOC)'
        ],
    'Coast': [
        'Chinook (TCH)', 'Seaward-Tlasta (TST)', 'Strait of Georgia (TSG)'
        ]
 }

try:
    # Get the directory of the script (relative to where it is executed)
    script_dir = os.path.dirname(os.path.realpath(__file__))

    # Define the file pattern with wildcard (searching in the root folder for the base report)
    file_pattern = os.path.join(script_dir, '../data', 'QA_DR_DIP_RTS_HICurrentFiscal-Or-Planned_with_CFSSvrLine_*_*.xlsx')

    # Use glob to find files matching the pattern
    matching_files = glob.glob(file_pattern)

    # Check if any files are found
    if not matching_files:
        raise FileNotFoundError(
            f"""
            The base report cannot be found in your current directory. 
            Please ensure that the base report is in the same folder as this script. 
            The name of the base report should match the following pattern :
            'QA_DR_DIP_RTS_HICurrentFiscal-Or-Planned_with_CFSSvrLine_YYYY_MM_DD.xlsx'
            """
        )

    # If files are found, get the first matching file
    file_path = matching_files[0]

    # Read in the data from the base report
    df = pd.read_excel(file_path, sheet_name='qDR_DIP_RTS_HICurrentFYAndNotD_')

except FileNotFoundError as e:
    print(f"Error: {e}")


# Read in the data from the base report 
df = pd.read_excel(file_path, sheet_name='qDR_DIP_RTS_HICurrentFYAndNotD_')
# Change the datatype of the MARK_SEQ_NBR to Int64 (which was a float before)
df['MARK_SEQ_NBR'] = df['MARK_SEQ_NBR'].astype('Int64')

# Read in the specification sheet from the base report 
spec_df = pd.read_excel(
    file_path, 
    sheet_name='Specification',
    header=None # Set header to None since there is no header in this sheet
    )
# Fill the NAN's with empty strings, otherwise there will be some subsequent errors in future steps
spec_df = spec_df.applymap(lambda x: "" if pd.isnull(x) else x)

# Remove the last row of the Specification sheet (which is not used in the generated reports)
spec_df = spec_df[:-1]

# Define a function to retrieve the current fiscal year from the report date on the Specification sheet
def get_fiscal_year(date):
    if date.month - 1 < 4:  
        fiscal_year = date.year
    else:
        fiscal_year = date.year + 1 
    return fiscal_year 

# Extract the report date from the Specification sheet 
date_value = spec_df.iloc[1, 1]

# Retrieve the current fiscal year from the report 
current_fiscal = get_fiscal_year(date_value)

# delete all the B07 licenses
df = df.query('TENURE_TYPE != "B07"') 
df = df.query('UBI != "BL6XE"')
df_1 = df.copy()

########
## Filter 'WOFF_STATUS' for 'D' and delete them
## Filter 'DEL STATUS' for 'D' and delete them
## Filter 'HI STATUS' for 'D' and delete them
## Filter 'DVC STATUS' for 'D' and delete them
########

df_1 = df_1[~((df_1['WOFF_STATUS'] == 'D') | (df_1['DEL_STATUS'] == 'D') | (df_1['HI_STATUS'] == 'D') | (df_1['DVC_STATUS'] == 'D'))]

# Exclude this block
# df_1 = df_1[~(df_1['BLOCK_ID'] == 'SAlc4SG')]

# Condition 1: If development is deferred
condition_1 = (
    (
        (df_1['DVS_STATUS'] == 'D') &
        (df_1['HAS_OGS_DEFERRAL'] == 'Y') &
        (df_1['OGS_REACTIVATED'] == 'N') &
        (df_1['HAS_OTHER_DEFERRAL'] == 'N') &
        (df_1['OTHER_REACTIVATED'] == 'N')
    ) |
    (
        (df_1['HAS_OGS_DEFERRAL'] == 'N') &
        (df_1['HAS_OTHER_DEFERRAL'] == 'Y') &
        (df_1['OTHER_REACTIVATED'] == 'N') 
    ) |
    (
        (df_1['HAS_OGS_DEFERRAL'] == 'Y') &
        (df_1['OGS_REACTIVATED'] == 'N') &
        (df_1['HAS_OTHER_DEFERRAL'] == 'Y') &
        (df_1['OTHER_REACTIVATED'] == 'N')
    ) |
    (
        (df_1['HAS_OGS_DEFERRAL'] == 'Y') &
        (df_1['OGS_REACTIVATED'] == 'Y') &
        (df_1['HAS_OTHER_DEFERRAL'] == 'Y') &
        (df_1['OTHER_REACTIVATED'] == 'N')  
    )
)

# Condition 2: If development has started and >$1000 spent on layout
condition_2 = (
    (df_1['DVS_STATUS'] != 'D') &
    (df_1['Layout_Amount'] > 1000) 
)

# Condition 3: If development has started Apr 1 2020 later and >$0 spent on layout
condition_3 = (
    (df_1['DVS_STATUS'] != 'D') &
    (df_1['First_Layout_Date'] >= datetime(2020, 4, 1)) &
    (df_1['Layout_Amount'] > 0)
)

# Condition 4: If no volume has been registered in inventory
condition_4 = (
    (df_1['DVS_STATUS'] == 'D') &
    ((df_1['BLAL_CRUISE_M3_VOL'].isnull()) | (df_1['BLAL_CRUISE_M3_VOL'] == 0)) &
    ((df_1['RW_VOL'].isnull()) | (df_1['RW_VOL'] == 0))
)

# Condition 5: If no spatial data has been registered for inventory
condition_5 = (
    (df_1['DVS_STATUS'] == 'D') &
    ((df_1['DEL_STATUS'] == 'N') | (df_1['DEL_STATUS'].isnull())) &
    (df_1['SPATIAL_LINKED'] == 'NO')
)

# Condition 6: If Development Started without a mandatory UBI
condition_6 = (
    (df_1['DVS_STATUS'] == 'D') &
    (df_1['UBI'].isnull())
)

# Condition 7: If development started status is set to ‘Done’ with a blank or future date
condition_7 = (
    (df_1['DVS_STATUS'] == 'D') &
    ((df_1['DVS_Status_Date'].isnull()) | (df_1['DVS_Status_Date'] > date_value))
)


# Make a list of all the conditions and their corresponding column names
conditions = [
    (condition_1, "Deferred"),
    (condition_2, "Development Started (>$1000 spent on layout; helicopter/water taxi included) without Development Started 'Done'"),
    (condition_3, "Development Started (>$0 spent on layout; helicopter/water taxi included) April 1, 2020 or later without Development Started 'Done'"),
    (condition_4, "Block and R/W cruise volume is blank or 0"),
    (condition_5, "No spatial data linked for blocks without Deletion Approval 'Planned' activity"),
    (condition_6, "No LRM UBI assigned for DVS 'Done'"),
    (condition_7, "DVS 'Done' date is blank or in the future")

]

# Make a list of all the new column names
new_columns = [column for _, column in conditions]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions:
    df_1[column] = np.where(condition, 'Y', df_1[column])

# Remove all 'non errors' without DVS 'Done'
df_1 = df_1[df_1[new_columns].eq('Y').any(axis=1) | (df_1['DVS_STATUS'] == 'D')]

### Adding new sets of conditions
### These conditions are used for all of the following steps: filtering 'DVS_STATUS' for 'D' and 'Deferred' for blank

# Condition 8: If development started status is set to 'done' and the development complete status has been set to not required (NR)
condition_8 = (
    (df_1['DVS_STATUS'] == 'D') &
    (df_1['Deferred'] != 'Y') &
    (df_1['DVC_STATUS'] == 'N') &
    (df_1['WOFF_STATUS'].isnull()) &
    (df_1['DEL_STATUS'].isnull()) 
)

# Condition 9: If development started status is set to 'done' and the development complete status is blank
condition_9 = (
    (df_1['DVS_STATUS'] == 'D') &
    (df_1['Deferred'] != 'Y') &
    (df_1['DVC_STATUS'].isnull()) 
)

# Condition 10: If development complete planned date is past due 
condition_10 = (
    (df_1['DVS_STATUS'] == 'D') &
    (df_1['Deferred'] != 'Y') &
    (df_1['DVC_STATUS'] == 'P') &
    (df_1['DVC_FISCAL'] < current_fiscal) 
)

# Condition 11: If development complete planned date is blank 
condition_11 = (
    (df_1['DVS_STATUS'] == 'D') &
    (df_1['Deferred'] != 'Y') &
    (df_1['DVC_STATUS'] == 'P') &
    (df_1['DVC_Status_Date'].isnull())
)

# Condition 12: If development complete planned date is too far in the future
condition_12 = (
    (df_1['DVS_STATUS'] == 'D') &
    (df_1['Deferred'] != 'Y') &
    (df_1['DVC_STATUS'] == 'P') &
    (df_1['DVC_FISCAL'] > (current_fiscal + 6))
)

#  Make a list of all the newly added conditions and their corresponding column names
conditions_new = [
    (condition_8, "DVC Status can't be NR unless planned for WO or deletion"),
    (condition_9, "DVC Status can't be Blank"),
    (condition_10, "DVC 'Planned' date is past-due fiscal"),
    (condition_11, "DVC 'Planned' date is blank"),
    (condition_12, "DVC 'Planned' date can't be >7 fiscal years out for un-deferred block"),
]

# Combine the old and new conditions
conditions_all = conditions + conditions_new

### Repeat the same steps for the newly added columns
# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions_new:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions_new:
    df_1[column] = np.where(condition, 'Y', df_1[column])

# Only keep the rows where there are 'Y's in the new columns (i.e. where there are nonconformances)
select_condition = df_1[[col[1] for col in conditions_all]].apply(lambda x: (x == 'Y').any(), axis=1)
selected_df = df_1[select_condition]

# Replace the NA's with empty strings to avoid potential errors
selected_df = selected_df.applymap(lambda x: "" if pd.isnull(x) else x)

# Create a list of all the columns where there are nonconformances
columns_with_Y = [col[1] for col in conditions_all if (selected_df[col[1]] == 'Y').any()]

# Drop the new columns where there's no 'Y' at all (i.e. where there are no nonconformances)
selected_df = selected_df.drop(columns=[col[1] for col in conditions_all if (selected_df[col[1]] == '').all()])

### Create a summary dataframe for the conformance summary sheet

# Create a new data list
summary_data = []

# Exclude 'Deferred' in the summary
columns_with_Y_no_deferred = columns_with_Y[1:]

# Accumulator for the total number of nonconformances for all the regions
all_region_total = 0

for region, area in area_list.items():
    # Make a summary for each region
    region_data = selected_df[selected_df['BUSINESS_AREA_REGION'] == region] 

    ### Check if the region is present in the data
    # If the region is present, calculate the totals
    if not region_data.empty:
        # Calculate the total number of instances for each type of nonconformance in each region
        region_nonconformance = region_data[columns_with_Y_no_deferred].apply(lambda x: (x == 'Y').sum(), axis=0) 

        # Calculate the total number of all nonconformances in the region
        # Note: the occurance of nonconformance for each row is only calculated once when there are multiple nonconformances 
        region_nonconformance_total = (region_data[columns_with_Y_no_deferred].apply(lambda row: (row == 'Y').any(), axis=1)).sum()

        # Write the region stats row to the summary table 
        region_row = [region, region_nonconformance_total] + list(region_nonconformance)

    # If the region is not present, use 0's for all the stats 
    else:
        region_nonconformance_total = 0
        region_row = [region, 0] + [0] * len(columns_with_Y_no_deferred)
    
    # Append the region row to the summary data
    summary_data.append(region_row)

    # Add the total number of nonconformances for this region to the accumulator
    all_region_total += region_nonconformance_total

    # Make a summary for each area in the region above
    for area in area_list[region]:
        area_data = region_data[region_data['BUSINESS_AREA'] == area]

        ### Check if the area is present in the data
        # If the area is present, calculate the totals
        if not area_data.empty:
            # Calculate the total number of instances for each type of nonconformance in each area
            area_nonconformance = area_data[columns_with_Y_no_deferred].apply(lambda x: (x == 'Y').sum(), axis=0)

            # Calculate the total number of all nonconformances in the area
            # Note: the occurance of nonconformance for each row is only calculated once when there are multiple nonconformances
            area_nonconformance_total = (area_data[columns_with_Y_no_deferred].apply(lambda row: (row == 'Y').any(), axis=1)).sum()

            # Write the area stats row to the summary table
            area_row =[area, area_nonconformance_total] + list(area_nonconformance)

        # If the area is not present, use 0's for all the stats
        else:
            area_nonconformance_total = 0
            area_row = [area, 0] + [0] * len(columns_with_Y_no_deferred)

        # Append the area row to the summary data
        summary_data.append(area_row)

# Calculate the grand total for all the regions 
grand_total_row = ['Grand Total', None]
grand_total = selected_df[columns_with_Y_no_deferred].apply(lambda x: (x == 'Y').sum(), axis=0)
grand_total_row[1] = all_region_total
grand_total_row.extend(grand_total)

summary_data.append(grand_total_row)

# Turn the table into a dataframe
summary_df = pd.DataFrame(summary_data, columns=['Region/Business Area', 'Number of Potential Nonconformance'] + columns_with_Y_no_deferred)

# Create a list for all the columns that were used as filtering conditions for later highlighting purpose
con_column_names = [
    'UBI',
    'SPATIAL_LINKED',
    'HAS_OGS_DEFERRAL',
    'OGS_REACTIVATED',
    'HAS_OTHER_DEFERRAL',
    'OTHER_REACTIVATED',
    'BLAL_CRUISE_M3_VOL',
    'RW_VOL',
    'DEL_STATUS',
    'WOFF_STATUS',
    'DVS_STATUS',
    'DVS_Status_Date',
    'DVC_STATUS',
    'DVC_Status_Date',
    'DVC_FISCAL',
    'First_Layout_Date',
    'Layout_Amount'

]

# Remove 'Deferred' from the new columns added for nonconformance criteria
new_columns_all = [con[1] for con in conditions_all]
new_columns_all_no_deferred = new_columns_all[1:]

# Only keep the rows where there are 'Y's in the new columns (i.e. where there are nonconformances)
select_condition = selected_df[[col for col in columns_with_Y_no_deferred]].apply(lambda x: (x == 'Y').any(), axis=1)
selected_df = selected_df[select_condition]

# Select the columns that will be shown in the final report
columns_kept = [
    'BUSINESS_AREA_REGION',
    'BUSINESS_AREA',
    'BUSINESS_AREA_CODE',
    'FIELDTEAM',	
    'LICENCE_ID',	
    'TENURE_TYPE',	
    'BLOCK_ID',	
    'BLOCK_NUMBER',
    'UBI',
    'SPATIAL_LINKED',
    'HAS_OGS_DEFERRAL',
    'OGS_REACTIVATED',
    'HAS_OTHER_DEFERRAL',
    'OTHER_REACTIVATED',
    'CUTB_BLOCK_STATE',	
    'BLAL_CRUISE_M3_VOL',	
    'RW_VOL',	
    'DEL_STATUS',	
    'WOFF_STATUS',
    'DR_STATUS',
    'DVS_STATUS',	
    'DVS_Status_Date',	
    'DVS_FISCAL',	
    'DVC_STATUS',	
    'DVC_Status_Date',	
    'DVC_FISCAL',
    'HI_STATUS',
    'First_Layout_Date',	
    'Layout_Amount_7018',
    'Layout_Amount',
    'CUTB_SEQ_NBR'
] + columns_with_Y

# The final dataframe that will be used to generate the report
selected_df = selected_df[columns_kept]

# # Pattern of the output file 
# output_name_pattern = '../Reports/Development In Progress (DIP) Timber Inventory Conformance Summary_YYYY_MM_DD.xlsx'

# # Define the date in the output file name which is extracted from the report date of the spec sheet in the base report
# output_date = str(date_value)[:10].replace("-", "_")
# output_path = output_name_pattern.replace('YYYY_MM_DD', output_date)

# Get the directory of the script (relative to where it is executed)
# script_dir = os.path.dirname(os.path.realpath(__file__))

# Set the Reports directory path relative to the script's location
output_folder = os.path.join(script_dir, '..', 'Reports')

# Ensure that the Reports directory exists, if not, create it
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# Get the current date to format the file name
output_date = str(date_value)[:10].replace("-", "_")

# Pattern of the output file 
output_name_pattern = f'{output_folder}/Development In Progress (DIP) Timber Inventory Conformance Summary_YYYY_MM_DD.xlsx'

# Replace the 'YYYY_MM_DD' part of the pattern with the actual output date
output_path = output_name_pattern.replace('YYYY_MM_DD', output_date)

### Formatting of the resultant report excel file

# Retrieve the column names of the dataframe
column_names = selected_df.columns

# Create a list of indices for each column
column_to_index = {column_name: idx for idx, column_name in enumerate(column_names)}

# Get the last column letter for Excel format for summary_df
num_columns_summary = len(summary_df.columns)
last_column_letter_summary = string.ascii_uppercase[num_columns_summary - 1]

# Get the last column letter for Excel format for spec_df
num_columns_spec = len(spec_df.columns)
last_column_letter_spec = string.ascii_uppercase[num_columns_spec - 1]

# Column index based on the conditional columns
col_indices = [selected_df.columns.get_loc(col) for col in con_column_names]

with pd.ExcelWriter(output_path) as writer:

    # Write the spec sheet
    spec_df.to_excel(writer, sheet_name='Specification', index=False)

    # Write each business area sheet and the province sheet
    for area, area_df in selected_df.groupby('BUSINESS_AREA_CODE'):
        area_df.to_excel(writer, sheet_name=area, index=False)
    
    selected_df.to_excel(writer, index=False, sheet_name='Province')

    # Write the conformance summary sheet
    summary_df.to_excel(writer, index=False, sheet_name='Conformance Summary')

    # Access the workbook and worksheet
    workbook = writer.book
    

    ### Define formats

    # Define header format for conformance report
    header_format = workbook.add_format({
        'bold': True, 
        'bg_color': '#DCE6F1', 
        'align': 'center',
        'valign': 'bottom',
        'text_wrap': True  
    })

    bold_format = workbook.add_format({'bold': True})  # Define bold format for conformance summary
    wrap_format = workbook.add_format({'text_wrap': True}) # Define text wrapping format for conformance summary
    highlight_format = workbook.add_format({'bg_color': '#DCE6F1'}) # Define highlighting format for conformance summary 
    grid_format = workbook.add_format({'border': 1}) # Define grid format for conformance summary
    centered_format = workbook.add_format({'align': 'center', 'valign': 'vcenter'}) # Define center format for conformance summary
    indent_format = workbook.add_format({'align': 'left', 'indent': 1}) # Define indent format for conformance summary
    last_row_format = workbook.add_format({'bold': True, 'bg_color': '#DCE6F1'}) # Define bold and highlighting format for the last row for conformance summary

    yellow_format = workbook.add_format({'bg_color': '#FFC000'}) # Define yellow highlighting format for regional and province sheets
    red_format = workbook.add_format({'bg_color': '#FF0000'}) # Define red highlighting format for regional and province sheets

    yellow_date_format = workbook.add_format({'num_format': 'yyyy-mm-dd', 'bg_color': '#FFC000'}) # Define yellow highlighting and date format for datetime values
    red_date_format = workbook.add_format({'num_format': 'yyyy-mm-dd', 'bg_color': '#FF0000'}) # Define red highlighting and date format for datetime values 

    datetime_format_region = workbook.add_format({'num_format': 'yyyy-mm-dd'}) # Define datetime format for regional and province sheets

    spec_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'border': 0, 'text_wrap': True}) # Define spec sheet format
    datetime_format_spec = workbook.add_format({'num_format': 'yyyy-mm-dd', 'align': 'left', 'valign': 'top', 'border': 0, 'text_wrap': True}) # Define datetime format for spec sheet


    ### Apply formatting to spec sheet 
    worksheet = writer.sheets['Specification']

    # Set column width to 50
    for col_idx in range(num_columns_spec):
        worksheet.set_column(col_idx, col_idx, 50)

    for row_idx in range(len(spec_df)): # Iterate through each row of spec_df
        for col_idx in range(num_columns_spec): # Iterate through each column of spec_df        
            cell_value = spec_df.iloc[row_idx, col_idx] # Get the index of each cell
            if isinstance(cell_value, datetime): # Determine if the cell value is a datetime datatype, and apply datetime format if so
                worksheet.write(row_idx, col_idx, cell_value, datetime_format_spec) 
            else:
                worksheet.write(row_idx, col_idx, cell_value, spec_format) 
    

    ### Apply formatting to conformance summary sheet
    worksheet = writer.sheets['Conformance Summary']

    # Set header row height to 75
    worksheet.set_row(0, 75)
    for col_num, value in enumerate(summary_df.columns.values):
        worksheet.write(0, col_num, value, header_format)

    # Adjust column widths to be 5x wider than default
    for col_idx in range(num_columns_summary):
        worksheet.set_column(col_idx, col_idx, 25)

    # Apply centered format for numeric values in conformance summary
    for row_idx in range(1, len(summary_df) + 1):  # Iterate through each row of summary_df
        for col_idx in range(num_columns_summary): # Iterate through each column of summary_df
            cell_value = summary_df.iloc[row_idx - 1, col_idx] # Determine if the cell value is numeric, and apply centered format if so
            if pd.api.types.is_numeric_dtype(type(cell_value)):
                worksheet.write(row_idx, col_idx, cell_value, centered_format)

    # Apply indent format for area names in the first column of conformance summary
    for row_idx in range(1, len(summary_df) + 1): # Iterate through each row of summary_df
        cell_value = summary_df.iloc[row_idx - 1, 0]   # Only checks the first column of each row
        # Determine if the cell value is an area name, and apply indent format if so 
        if cell_value not in area_list.keys():
            worksheet.write(row_idx, 0, cell_value, indent_format)

    # Apply bold formatting to each region row
    for idx, row in summary_df.iterrows(): # Iterate through each row of summary_df
        if row['Region/Business Area'] in area_list.keys(): # Determine if the first column is a region name, and apply bold format if so
            row_range = f'A{idx + 2}:{last_column_letter_summary}{idx + 2}'
            worksheet.conditional_format(row_range, {'type': 'no_blanks', 'format': bold_format})


    # Highlight and bold the last row (Grand Total row) only within the column range
    last_row_idx = len(summary_df)
    last_row_range = f'A{last_row_idx + 1}:{last_column_letter_summary}{last_row_idx + 1}'
    worksheet.conditional_format(last_row_range, {'type': 'no_blanks', 'format': highlight_format})
    worksheet.conditional_format(last_row_range, {'type': 'no_blanks', 'format': last_row_format})
    # worksheet.set_row(last_row_idx, None, last_row_format)  # Ensure the last row is bolded

    # Apply grid lines to only the cells within the table’s column range
    for row in range(last_row_idx + 1):
        worksheet.conditional_format(f'A{row + 1}:{last_column_letter_summary}{row + 1}', {'type': 'no_blanks', 'format': grid_format})

    ### Apply conditional highlighting format to columns in regional and province sheets
    for sheet_name in selected_df['BUSINESS_AREA_CODE'].unique().tolist() + ['Province']: # Iterate through each regional + province sheet
        worksheet = writer.sheets[sheet_name]

        for col_num, value in enumerate(selected_df.columns.values): # Iterate through each column in selected_df
            worksheet.write(0, col_num, value, workbook.add_format({})) # Write the column names in the first row (as header) for each sheet
        
        # Filter the selected_df to only include rows for the current sheet (based on region or business area code)
        region_filter = selected_df[selected_df['BUSINESS_AREA_CODE'] == sheet_name] if sheet_name != 'Province' else selected_df
        region_df = region_filter.copy()

        for row_idx in range(1, len(region_df) + 1):  # Iterate through each row of region_df
            for col_idx in range(len(region_df.columns)):         # Iterate through each column of region_df
                cell_value = region_df.iloc[row_idx - 1, col_idx]
                if isinstance(cell_value, datetime) and pd.notnull(cell_value):  # Determine if the cell_value is a datetime and apply datetime format if so 
                    worksheet.write(row_idx, col_idx, cell_value, datetime_format_region)

        for col_idx in col_indices: # Iterate through the column indices in the condition columns 
            worksheet.write(0, col_idx, selected_df.columns[col_idx], yellow_format) # Highlight the column name if it's used as a filtering condition

        # Apply the conditions and write to the sheet
        for row_idx, (_, row) in enumerate(region_df.iterrows(), start=1): # Iterate through each row of region_df and apply condition highlighting format
            if (
                (new_columns_all_no_deferred[0] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[0]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['Layout_Amount'], row['Layout_Amount'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], red_format)  

            if (
                (new_columns_all_no_deferred[1] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[1]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['First_Layout_Date'], row['First_Layout_Date'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['Layout_Amount'], row['Layout_Amount'], yellow_format)  
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], red_format)

            if (
                (new_columns_all_no_deferred[2] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[2]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['BLAL_CRUISE_M3_VOL'], row['BLAL_CRUISE_M3_VOL'], red_format) 
                worksheet.write(row_idx, column_to_index['RW_VOL'], row['RW_VOL'], red_format)   

            if (
                (new_columns_all_no_deferred[3] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[3]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DEL_STATUS'], row['DEL_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['SPATIAL_LINKED'], row['SPATIAL_LINKED'], red_format)     

            if (
                (new_columns_all_no_deferred[4] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[4]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['UBI'], row['UBI'], red_format) 

            if (
                (new_columns_all_no_deferred[5] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[5]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVS_Status_Date'], row['DVS_Status_Date'], red_date_format)

            if (
                (new_columns_all_no_deferred[6] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[6]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DEL_STATUS'], row['DEL_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVC_STATUS'], row['DVC_STATUS'], red_format)     

            if (
                (new_columns_all_no_deferred[7] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[7]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVC_STATUS'], row['DVC_STATUS'], red_format)  

            if (
                (new_columns_all_no_deferred[8] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[8]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVC_STATUS'], row['DVC_STATUS'], yellow_format)  
                worksheet.write(row_idx, column_to_index['DVC_FISCAL'], row['DVC_FISCAL'], red_format)
            
            if (
                (new_columns_all_no_deferred[9] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[9]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVC_STATUS'], row['DVC_STATUS'], yellow_format) 
                worksheet.write(row_idx, column_to_index['DVC_Status_Date'], row['DVC_Status_Date'], red_date_format)  

            if (
                (new_columns_all_no_deferred[10] in columns_with_Y_no_deferred) and
                (row[new_columns_all_no_deferred[10]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['DVS_STATUS'], row['DVS_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['DVC_STATUS'], row['DVC_STATUS'], yellow_format)  
                worksheet.write(row_idx, column_to_index['DVC_FISCAL'], row['DVC_FISCAL'], red_format)


