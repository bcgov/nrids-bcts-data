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
    file_pattern = os.path.join(script_dir, '../data', 'QA_InventoryReconciliation_*_*.xlsx')

    # Use glob to find files matching the pattern
    matching_files = glob.glob(file_pattern)

    # Check if any files are found
    if not matching_files:
        raise FileNotFoundError(
            f"""
            The base report cannot be found in your current directory. 
            Please ensure that the base report is in the same folder as this script. 
            The name of the base report should match the following pattern :
            'QA_InventoryReconciliation_*_*.xlsx'
            """
        )

    # If files are found, get the first matching file
    file_path = matching_files[0]

    # Read in the data from the base report
    df = pd.read_excel(file_path, sheet_name='qQA_InvReconcile')

except FileNotFoundError as e:
    print(f"Error: {e}")

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

df = df.query('UBI != "BL6XE"')

df_1 = df.copy()

df_1['BUSINESS_AREA_CODE'] = (df_1['BUSINESS_AREA']).apply(lambda x: x[-4:-1])

#####

# Filter ‘ISSUED STATUS’ for ‘P, N or blank’ (not D) and delete
# Filter ‘WO_STATUS’ for ‘P or D’ and delete
# Filter ‘DEL_STATUS’ for ‘P or D’ and delete
# Filter ‘SURRENDER_STATUS’ for ‘D’ and delete
# Filter ‘CANCELLED_STATUS’ for ‘D’ and delete
# Filter ‘HVC_STATUS’ for ‘D, A or N’ (not P) and delete

#####

df_1 = df_1[
    ~(
        (df_1['ISSUED_STATUS'] != 'D') |
        (df_1['ISSUED_FISCAL'] < 2004) |    
        (df_1['WO_STATUS'] == 'D') |
        (df_1['WO_STATUS'] == 'P') |
        (df_1['DEL_STATUS'] == 'D') |
        (df_1['DEL_STATUS'] == 'P') |
        (df_1['SURRENDER_STATUS'] == 'D') |
        (df_1['CANCELLED_STATUS'] == 'D') |
        (df_1['HVC_STATUS'] != 'P')
    )
]

# Condition 1: If block waste survey completed with no block Logging Completed 'Done'

condition_1 = (
    ((df_1['WASTE_BLOCK_STATUS_DATE'].notnull())) & 
    (
        (df_1['WASTE_BLOCK_STATUS'] == 'APP') |
        (df_1['WASTE_BLOCK_STATUS'] == 'BIP') |
        (df_1['WASTE_BLOCK_STATUS'] == 'BIS') |
        (df_1['WASTE_BLOCK_STATUS'] == 'RTB') |
        (df_1['WASTE_BLOCK_STATUS'] == 'SUB') |
        (df_1['WASTE_BLOCK_STATUS'] == 'ISUB') 
    )
)

# Condition 2: If cruise base reconciliation indicates licence completion with no block Logging Completed ‘Done’
condition_2 = (
    (df_1['CRUISE_BASED_IND'] == 'Y') & 
    ((df_1['Sold_Variance_m3'] >= -10) & (df_1['Sold_Variance_m3'] <= 10))
)

# Condition 3: If Licence closed with no block Logging Completed ‘Done’
condition_3 = (df_1['HC_STATUS'] == 'D')

# Condition 4: If licence substantially complete with no block Logging Completed ‘Done’
condition_4 = (
    (df_1['SUBCOMP_STATUS'] == 'D') &
    (df_1['HC_STATUS'] != 'D')
)

# Condition 5: If licence expired with no block Logging Completed ‘Done’
condition_5 = (
    (
        (df_1['EXTENSION_FISCAL'].notnull()) &
        (df_1['EXTENSION_FISCAL'] < current_fiscal) # Filter EXTENSION FISCAL for past fiscal years
        ) |
    (
        (df_1['EXTENSION_FISCAL'].isnull()) & # Filter EXTENSION FISCAL for blank
        (df_1['EXPIRY_FISCAL'] < current_fiscal) # Filter EXPIRY FISCAL for past fiscal years 
    ) |
    (
        (df_1['EXTENSION_FISCAL'].notnull()) &
        (df_1['EXTENSION_FISCAL'] == current_fiscal) & # Filter EXTENSION FISCAL for current fiscal year
        (df_1['EXTENSION_STATUS_DATE'].notnull()) &
        (df_1['EXTENSION_STATUS_DATE'] <= date_value) # Filter EXTENSION STATUS DATE for past due
    ) |
    (
        (df_1['EXTENSION_FISCAL'].isnull()) & # Filter EXTENSION FISCAL for blank
        (df_1['EXPIRY_FISCAL'] == current_fiscal) & # Filter EXIPRY FISCAL for current fiscal year
        (df_1['EXPIRY_STATUS_DATE'].notnull()) &
        (df_1['EXPIRY_STATUS_DATE'] <= date_value) # Filter EXPIRY STATUS DATE for past due 
    )
)

# Condition 6: If block state indicates Logging Completed ‘Done’
condition_6 = (
    (df_1['BLOCK_STATE'] == 'LC') | 
    (df_1['BLOCK_STATE'] == 'RG') | 
    (df_1['BLOCK_STATE'] == 'FG')
)

# Condition 7: If licence State indicates Logging Completed ‘Done’
condition_7 = (
    (df_1['LICENCE_STATE_LRM'] == 'RG') |
    (df_1['LICENCE_STATE_LRM'] == 'FG') |
    (df_1['LICENCE_STATE_LRM'] == 'SC') |
    (df_1['LICENCE_STATE_LRM'] == 'LC') |
    (df_1['LICENCE_STATE_LRM'] == 'HC')
)

# Condition 8: If “FTA File Status indicates block Logging Completed ‘Done’
condition_8 = (
    (df_1['FTA_FILE_STATUS'] == 'Logging Complete (LC)') |
    (df_1['FTA_FILE_STATUS'] == 'Closed (HC)')
)

# Make a list for all the conditions and their corresponding column names
conditions = [
    (condition_1, "Block waste survey completed with no block Logging Completed 'Done'"),
    (condition_2, "Cruise base reconciliation indicates licence completion with no block Logging Completed 'Done'"),
    (condition_3, "Licence closed with no block Logging Completed 'Done'"),
    (condition_4, "Licence substantially complete with no block Logging Completed 'Done'"),
    (condition_5, "Licence expired with no block Logging Completed 'Done'"),
    (condition_6, "Block state indicates Logging Completed 'Done'"),
    (condition_7, "Licence State indicates Logging Completed 'Done'"),
    (condition_8, "FTA File Status indicates block Logging Completed 'Done'")
]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions:
    df_1[column] = np.where(condition, 'Y', df_1[column])

# Only keep the rows where there are 'Y's in the new columns (i.e. where there are nonconformances)
select_condition = df_1[[col[1] for col in conditions]].apply(lambda x: (x == 'Y').any(), axis=1)
selected_df = df_1[select_condition]

# Replace the NA's with empty strings to avoid potential errors
selected_df = selected_df.applymap(lambda x: "" if pd.isnull(x) else x)

# Create a list of all the columns where there are nonconformances
columns_with_Y = [col[1] for col in conditions if (selected_df[col[1]] == 'Y').any()]

# Drop the new columns where there's no 'Y' at all (i.e. where there are no nonconformances)
selected_df = selected_df.drop(columns=[col[1] for col in conditions if (selected_df[col[1]] == '').all()])


### Create a summary dataframe for the conformance summary sheet

# Create a new data list
summary_data = []

# Accumulator for the total number of nonconformances for all the regions
all_region_total = 0

for region, area in area_list.items():
    # Make a summary for each region
    region_data = selected_df[selected_df['BUSINESS_AREA_REGION'] == region] 

    ### Check if the region is present in the data
    # If the region is present, calculate the totals
    if not region_data.empty:
        # Calculate the total number of instances for each type of nonconformance in each region
        region_nonconformance = region_data[columns_with_Y].apply(lambda x: (x == 'Y').sum(), axis=0) 

        # Calculate the total number of all nonconformances in the region
        # Note: the occurance of nonconformance for each row is only calculated once when there are multiple nonconformances 
        region_nonconformance_total = (region_data[columns_with_Y].apply(lambda row: (row == 'Y').any(), axis=1)).sum()

        # Write the region stats row to the summary table 
        region_row = [region, region_nonconformance_total] + list(region_nonconformance)

    # If the region is not present, use 0's for all the stats 
    else:
        region_nonconformance_total = 0
        region_row = [region, 0] + [0] * len(columns_with_Y)
    
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
            area_nonconformance = area_data[columns_with_Y].apply(lambda x: (x == 'Y').sum(), axis=0)

            # Calculate the total number of all nonconformances in the area
            # Note: the occurance of nonconformance for each row is only calculated once when there are multiple nonconformances
            area_nonconformance_total = (area_data[columns_with_Y].apply(lambda row: (row == 'Y').any(), axis=1)).sum()

            # Write the area stats row to the summary table
            area_row =[area, area_nonconformance_total] + list(area_nonconformance)

        # If the area is not present, use 0's for all the stats
        else:
            area_nonconformance_total = 0
            area_row = [area, 0] + [0] * len(columns_with_Y)

        # Append the area row to the summary data
        summary_data.append(area_row)

# Calculate the grand total for all the regions 
grand_total_row = ['Grand Total', None]
grand_total = selected_df[columns_with_Y].apply(lambda x: (x == 'Y').sum(), axis=0)
grand_total_row[1] = all_region_total
grand_total_row.extend(grand_total)

summary_data.append(grand_total_row)

# Turn the table into a dataframe
summary_df = pd.DataFrame(summary_data, columns=['Region/Business Area', 'Number of Potential Nonconformance'] + columns_with_Y)

# Create a list for all the columns that were used as filtering conditions for later highlighting purpose
con_column_names = [
    'LICENCE_STATE_LRM',
    'CRUISE_BASED_IND',
    'BLOCK_STATE',
    'WASTE_BLOCK_STATUS',
    'WASTE_BLOCK_STATUS',
    'HVC_STATUS',
    'WO_STATUS',
    'DEL_STATUS',
    'ISSUED_STATUS',
    'ISSUED_FISCAL',
    'SUBCOMP_STATUS',
    'SURRENDER_STATUS',
    'CANCELLED_STATUS',
    'EXPIRY_STATUS_DATE',
    'EXPIRY_FISCAL',
    'EXTENSION_STATUS_DATE',
    'EXTENSION_FISCAL',
    'HC_STATUS',
    'Sold_Variance_m3',
    'FTA_FILE_STATUS'
]

columns_kept = [
    'BUSINESS_AREA_REGION',
    'BUSINESS_AREA',
    'BUSINESS_AREA_CODE',
    'Field_Team',
    'LICENCE',
    'LICENCE_STATE_LRM',
    'CRUISE_BASED_IND',
    'BLOCK',
    'UBI',
    'BLOCK_STATE',
    'WASTE_BLOCK_STATUS',
    'WASTE_BLOCK_STATUS_DATE',
    'DVC_STATUS_DATE',
    'DVC_FISCAL',
    'HVS_STATUS',
    'HVS_STATUS_DATE',
    'HVS_FISCAL',
    'HVC_STATUS',
    'WO_STATUS',
    'DEL_STATUS',
    'ISSUED_STATUS',
    'ISSUED_FISCAL',
    'SUBCOMP_STATUS',
    'SURRENDER_STATUS',
    'CANCELLED_STATUS',
    'EXPIRY_STATUS_DATE',
    'EXPIRY_FISCAL',
    'EXTENSION_STATUS_DATE',
    'EXTENSION_FISCAL',
    'HC_STATUS',
    'Sold_Variance_m3',
    'FTA_FILE_STATUS',
    'FTA_FILE_STATUS_DATE'
] + columns_with_Y

# The final dataframe that will be used to generate the report
selected_df = selected_df[columns_kept]

# Set the Reports directory path relative to the script's location
output_folder = os.path.join(script_dir, '..', 'Reports')

# Ensure that the Reports directory exists, if not, create it
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# Get the current date to format the file name
output_date = str(date_value)[:10].replace("-", "_")

# Pattern of the output file 
output_name_pattern = f'{output_folder}/Logging_Completed_Conformance_Summary_YYYY_MM_DD.xlsx'

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
        for row_idx, (_, row) in enumerate(region_df.iterrows(), start=1):
            # Apply region-specific conditions
            if (
                (row['WASTE_BLOCK_STATUS_DATE'] != '') and 
                (
                    (row['WASTE_BLOCK_STATUS'] == 'APP') or 
                    (row['WASTE_BLOCK_STATUS'] == 'BIP') or 
                    (row['WASTE_BLOCK_STATUS'] == 'BIS') or 
                    (row['WASTE_BLOCK_STATUS'] == 'RTB') or 
                    (row['WASTE_BLOCK_STATUS'] == 'SUB') or 
                    (row['WASTE_BLOCK_STATUS'] == 'ISUB')
                )
            ):
                worksheet.write(row_idx, column_to_index['WASTE_BLOCK_STATUS'], row['WASTE_BLOCK_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['WASTE_BLOCK_STATUS_DATE'], row['WASTE_BLOCK_STATUS_DATE'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)  

            if (
                (row['CRUISE_BASED_IND'] == 'Y') and
                ((row['Sold_Variance_m3'] >= -10) and (row['Sold_Variance_m3'] <= 10))
            ):
                worksheet.write(row_idx, column_to_index['CRUISE_BASED_IND'], row['CRUISE_BASED_IND'], yellow_format) 
                worksheet.write(row_idx, column_to_index['Sold_Variance_m3'], row['Sold_Variance_m3'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)

            if (row['HC_STATUS'] == 'D'):
                worksheet.write(row_idx, column_to_index['HC_STATUS'], row['HC_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)    

            if (
                (row['SUBCOMP_STATUS'] == 'D') and
                (row['HC_STATUS'] != 'D')
            ):
                worksheet.write(row_idx, column_to_index['SUBCOMP_STATUS'], row['SUBCOMP_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['HC_STATUS'], row['HC_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format) 

            if (
                (
                    (row['EXTENSION_FISCAL'] != '') and
                    (row['EXTENSION_FISCAL'] < current_fiscal) 
                ) or
                (
                    (row['EXTENSION_FISCAL'] == '') and
                    (row['EXPIRY_FISCAL'] != '') and
                    (row['EXPIRY_FISCAL'] < current_fiscal) 
                ) or
                (
                    (row['EXTENSION_FISCAL'] != '') and
                    (row['EXTENSION_FISCAL'] == current_fiscal) and
                    (row['EXTENSION_STATUS_DATE'] != '') and
                    (row['EXTENSION_STATUS_DATE'] <= date_value) 
                ) or
                (
                    (row['EXTENSION_FISCAL'] == '') and
                    (row['EXPIRY_FISCAL'] == current_fiscal) and
                    (row['EXPIRY_STATUS_DATE'] != '') and
                    (row['EXPIRY_STATUS_DATE'] <= date_value) 
                )
            ):
                worksheet.write(row_idx, column_to_index['EXTENSION_FISCAL'], row['EXTENSION_FISCAL'], yellow_format)
                worksheet.write(row_idx, column_to_index['EXPIRY_FISCAL'], row['EXPIRY_FISCAL'], yellow_format)
                worksheet.write(row_idx, column_to_index['EXTENSION_STATUS_DATE'], row['EXTENSION_STATUS_DATE'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)

            if (
                (row['BLOCK_STATE'] == 'LC') or
                (row['BLOCK_STATE'] == 'RG') or
                (row['BLOCK_STATE'] == 'FG') 
            ):
                worksheet.write(row_idx, column_to_index['BLOCK_STATE'], row['BLOCK_STATE'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)

            if (
                (row['LICENCE_STATE_LRM'] == 'RG') or
                (row['LICENCE_STATE_LRM'] == 'FG') or
                (row['LICENCE_STATE_LRM'] == 'SC') or
                (row['LICENCE_STATE_LRM'] == 'LC') or
                (row['LICENCE_STATE_LRM'] == 'HC')
            ):
                worksheet.write(row_idx, column_to_index['LICENCE_STATE_LRM'], row['LICENCE_STATE_LRM'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)


            if (
                (row['FTA_FILE_STATUS'] == 'Logging Complete (LC)') or
                (row['FTA_FILE_STATUS'] == 'Closed (HC)')
            ):
                worksheet.write(row_idx, column_to_index['FTA_FILE_STATUS'], row['FTA_FILE_STATUS'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVC_STATUS'], row['HVC_STATUS'], red_format)


            