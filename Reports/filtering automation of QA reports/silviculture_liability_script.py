import numpy as np
import pandas as pd
from datetime import datetime
from datetime import date
import glob
from openpyxl import load_workbook
import string
import re
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
    file_pattern = os.path.join(script_dir, '../data', 'QA_SilvicultureLiability_*_*.xlsx')

    # Use glob to find files matching the pattern
    matching_files = glob.glob(file_pattern)

    # Check if any files are found
    if not matching_files:
        raise FileNotFoundError(
            f"""
            The base report cannot be found in your current directory. 
            Please ensure that the base report is in the same folder as this script. 
            The name of the base report should match the following pattern :
            'QA_SilvicultureLiability_YYYY_MM_DD.xlsx'
            """
        )

    # If files are found, get the first matching file
    file_path = matching_files[0]

    # Read in the data from the base report
    df = pd.read_excel(file_path, sheet_name='qQA_SilviLiability')

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

try:
    # Get the directory of the script (relative to where it is executed)
    script_dir = os.path.dirname(os.path.realpath(__file__))

    # Define the file pattern with wildcard (searching in the root folder for the base report)
    file_pattern = os.path.join(script_dir, '../Reports', 'Logging_Started_Conformance_Summary_*_*.xlsx')

    # Use glob to find files matching the pattern
    matching_files = glob.glob(file_pattern)

    # Check if any files are found
    if not matching_files:
        raise FileNotFoundError(
            f"""
            The base report cannot be found in your current directory. 
            Please ensure that the base report is in the same folder as this script. 
            The name of the base report should match the following pattern :
            'Logging_Started_Conformance_Summary.xlsx'
            """
        )

    # If files are found, get the first matching file
    file_path = matching_files[0]

    # Read in the data from the base report
    df_ls = pd.read_excel(file_path, sheet_name='Province')

except FileNotFoundError as e:
    print(f"Error: {e}")

error_columns = [
    "Logging is started according to the 'Logging Started Conformance Summary' report; with planned activities",
    "Block waste survey completed with no block Logging Completed 'Done'",
    "Cruise base reconciliation indicates licence completion with no block Logging Completed 'Done'",
    "Licence closed with no block Logging Completed 'Done'",
    "Licence substantially complete with no block Logging Completed 'Done'",
    "Licence expired with no block Logging Completed 'Done'",
    "Block state indicates Logging Completed 'Done'",
    "Licence State indicates Logging Completed 'Done'",
    "FTA File Status indicates block Logging Completed 'Done'"
]

ls_con = [col for col in df_ls.columns.values if col in error_columns]
selected_ls_con = df_ls[[col for col in ls_con]].apply(lambda x: (x == 'Y').any(), axis=1)
selected_ls = df_ls[selected_ls_con]
selected_ls['ls_errors'] = 'Y'
selected_ls = selected_ls[['CUTB_SEQ_NBR'] + ['ls_errors']]
df_1 = pd.merge(df_1, selected_ls, how="left", on='CUTB_SEQ_NBR')

df_1 = df_1[~((df_1['DEL_STATUS'] == 'D') | (df_1['DEL_STATUS'] == 'P'))]

df_1 = df_1[~((df_1['BLOCK_FUNDING'] != 'BCT') & (df_1['BLOCK_FUNDING'].notnull()))]

df_1 = df_1[~(
                (df_1['PLANNED_TOTAL_COST'] == 0) &
                (
                    (df_1['BASE'] == 'AU') |
                    (df_1['BASE'] == 'DN') |
                    (df_1['BASE'] == 'RD') |
                    (df_1['BASE'] == 'SP') |
                    (df_1['BASE'] == 'SU') |
                    (df_1['BASE'] == 'SX') |
                    (df_1['BASE'] == 'FE') |
                    (df_1['BASE'] == 'CM') |
                    (df_1['BASE'] == 'IM') 
                )
             )]

# Condition 1: 'Logging Started Conformance Summary' report; with planned activities
condition_1 = (
    (df_1['ls_errors'] == 'Y') &
    (df_1['HVS_STATUS'] == 'P')
)

# Condition 2: Activity with liability completed without Logging Started
condition_2 = (
    (df_1['STATUS'] == 'DONE') &
    (df_1['PLANNED_TOTAL_COST'] > 0) &
    (df_1['HVS_STATUS'] != 'D')
)

# Condition 3: Block Status FG with no Logging Started 'Done' and proposed 'Planned' Activities with cost
condition_3 = (
    (df_1['RESULTS_FG_DECLARED'].notnull()) &
    (df_1['HVS_STATUS'] != 'D') &
    (df_1['WOFF_STATUS'] != 'P') &
    (df_1['WOFF_STATUS'] != 'D') &
    (df_1['PLANNED_TOTAL_COST'] > 0)
)

# Condition 4: Block State FG with no HVS 'Done' and proposed 'Planned' Activities with cost
condition_4 = (
    (df_1['HVS_STATUS'] != 'D') &
    (df_1['BLOCK_STATE'] == 'FG') &
    (df_1['PLANNED_TOTAL_COST'] > 0)
)

# Make a list of all the conditions and their corresponding column names
conditions = [
    (condition_1, "Logging is started according to the 'Logging Started Conformance Summary' report; with planned activities"),
    (condition_2, "Activity with liability completed without Logging Started"),
    (condition_3, "Block Status FG with no Logging Started 'Done' and proposed 'Planned' Activities with cost"),
    (condition_4, "Block State FG with no HVS 'Done' and proposed 'Planned' Activities with cost")
]

# Make a list of all the new column names
new_columns = [column for _, column in conditions]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions:
    df_1[column] = np.where(condition, 'Y', df_1[column])

df_1['Error'] = df_1[new_columns].apply(lambda row: 'Y' if 'Y' in row.values else '', axis=1)

df_1 = df_1[
    ~(
        (
            (df_1['HVS_STATUS'] != 'D') &
            (df_1['Error'] != 'Y')
        ) |
        (
            (df_1['WOFF_STATUS'] == 'D') &
            (df_1['Error'] != 'Y')
        ) |
        (
            (df_1['PRIMARY_RECORD'] == 'N') &
            (df_1['Error'] != 'Y')
        ) |
        (
            (df_1['STATUS'] == 'DONE') &
            (df_1['Error'] != 'Y')
        )
    )
]

# Condition 5: Missing NAR
condition_5 = (
    ((df_1['NAR_AREA'] == 0) | (df_1['NAR_AREA'].isnull())) &
    (df_1['SP_EXEMPT'] == 'N')
)

# Condition 6: Missing Gross Area
condition_6 = (
    (df_1['GROSS_AREA_BLOCK'] == 0) | 
    (df_1['GROSS_AREA_BLOCK'].isnull())
)

# Condition 7: Missing Treatment Unit Area
condition_7 = (
    (df_1['TREATMENT_AREA'] == 0) |
    (df_1['TREATMENT_AREA'].isnull())
)

# Condition 8: Blank total planned cost; need $0 for inhouse/no direct contract cost, or contract $
condition_8 = (
    df_1['PLANNED_TOTAL_COST'].isnull()
)

# Condition 9: Blank activity funding source for booking liability
condition_9 = (
    df_1['ACTIVITY_FUNDING'].isnull()
)

# Condition 10: Incorrect activity funding source for booking liability
condition_10 = (
    (df_1['ACTIVITY_FUNDING'] != 'BCT') &
    (df_1['ACTIVITY_FUNDING'] != 'FRP') &
    ~(df_1['ACTIVITY'].str.contains(
        r'\b(FIP|FFT|FIP\s+FFT)?\s*Survey\b|\bFIP\b|\bFFT\b',
        flags=re.IGNORECASE,
        na=False
        )
    )
)

# Condition 11: No planned activity start date for liability booking
condition_11 = (
    (df_1['START_DATE'].isnull()) &
    (df_1['PLANNED_TOTAL_COST'] > 0)
)

# Condition 12: Past due planned activity start date in past fiscals for liability booking
condition_12 = (
    (df_1['START_FISCAL'] < current_fiscal) &
    (df_1['PLANNED_TOTAL_COST'] > 0)
)

# Condition 13: Declared FG in RESULTS; CMB FG Met Activity not updated
condition_13 = (
    (df_1['RESULTS_FG_DECLARED'].notnull()) &
    (df_1['FG_Done'].isnull())
)

# Condition 14: FG declared/FG Met date discrepancy
condition_14 = (
    (df_1['RESULTS_FG_DECLARED'].notnull()) &
    (df_1['FG_Done'].notnull()) &
    (df_1['FG_MATCH'] == 'N')
)

# Condition 15: FG Met in LRM without FG declaration in RESULTS
condition_15 = (
    (df_1['RESULTS_FG_DECLARED'].isnull()) &
    (df_1['FG_Done'].notnull())
)

# Condition 16: FG Met block state without FG Met ‘Done’
condition_16 = (
    (df_1['BLOCK_STATE'] == 'FG') &
    (df_1['FG_Done'].isnull())
)

# Condition 17: Contract $ required for activity?
condition_17 = (
    (df_1['PLANNED_TOTAL_COST'] == 0) &
    (
        (df_1['BASE'] == 'PL') |
        (df_1['BASE'] == 'BR') |
        (df_1['BASE'] == 'SP')
        ) &
    ((df_1['METHOD'] != 'LAYOT') & (df_1['METHOD'] != 'GRAZE')) &
    ~(df_1['ACTIVITY'].str.contains(r'(?i)\bsowing request\b|\bplanting admin\b|\bgrazing\b', regex=True, na=False))
)

# Condition 18: TU area exceeds Gross Area of block
condition_18 = (
    (df_1['PLANNED_TOTAL_COST'] > 0) &
    (
        (df_1['BASE'] == 'SU') |
        (df_1['BASE'] == 'AU') |
        (df_1['BASE'] == 'IM')
        ) &
    (df_1['QA_FLAG_TREATMENT_AREA_GREATER_THAN_GROSS_AREA'] > 1)
)

# Condition 19: TU area exceeds NAR
condition_19 = (
    (df_1['PLANNED_TOTAL_COST'] > 0) &
    (
        (df_1['BASE'] != 'SU') &
        (df_1['BASE'] != 'AU') &
        (df_1['BASE'] != 'IM')
        ) &
    (df_1['QA_FLAG_TREATMENT_AREA_GREATER_THAN_NAR_AREA'] >= 0.1)
    
)

df_1['START_DATE'] = pd.to_datetime(df_1['START_DATE'], errors='coerce').dt.date

##### Starting at end of Q2 until fiscal year end
# Condition 20: Work ‘should’ already be completed in current fiscal for dropping liability?
condition_20 = (
    ((date(current_fiscal - 1, 9, 20) <= (date_value).date()) & (date_value.date() <= date(current_fiscal, 4, 15))) &
    (df_1['START_FISCAL'] == current_fiscal) &
    (df_1['START_DATE'] <= date(current_fiscal - 1, 12, 30)) &
    (df_1['STATUS'] != 'DONE') &
    (df_1['PLANNED_TOTAL_COST'] > 0) &
    (
        (df_1['BASE'] == 'PL') |
        (df_1['BASE'] == 'SP') |
        (df_1['BASE'] == 'BR') |
        (df_1['BASE'] == 'JS') |
        (df_1['BASE'] == 'FE') |
        (df_1['BASE'] == 'PC') 
    ) &
    ~(df_1['ACTIVITY'].str.contains(r'(?i)\bsowing request\b', regex=True, na=False))
)

##### Starting at end of Q3 until fiscal year end
# Condition 21: Survey field and data submission  work ‘should’ already be completed in current fiscal for dropping liability
condition_21 = (
    ((date(current_fiscal - 1, 12, 20) <= (date_value).date()) & (date_value.date() <= date(current_fiscal, 4, 15))) &
    (df_1['START_FISCAL'] == current_fiscal) &
    (df_1['START_DATE'] <= date(current_fiscal - 1, 12, 30)) &
    (df_1['STATUS'] != 'DONE') &
    (df_1['PLANNED_TOTAL_COST'] > 0) &
    (df_1['BASE'] == 'SU')
) 

##### Starting at end of Q4 until fiscal year end
# Condition 22: Work must already be completed in current fiscal for dropping liability
condition_22 = (
    ((date(current_fiscal, 3, 20) <= (date_value).date()) & (date_value.date() <= date(current_fiscal, 4, 15))) &
    (df_1['START_FISCAL'] == current_fiscal) &
    (df_1['START_DATE'] <= date(current_fiscal - 1, 12, 30)) &
    (df_1['STATUS'] != 'DONE') &
    (df_1['PLANNED_TOTAL_COST'] > 0) &
    (
        (df_1['BASE'] == 'PL') |
        (df_1['BASE'] == 'SP') |
        (df_1['BASE'] == 'BR') |
        (df_1['BASE'] == 'JS') |
        (df_1['BASE'] == 'FE') |
        (df_1['BASE'] == 'PC') |
        (df_1['BASE'] == 'SU')
    ) &
    ~(df_1['ACTIVITY'].str.contains(r'(?i)\bsowing request\b', regex=True, na=False))
)

conditions_new = [
    (condition_5, "Missing NAR"),
    (condition_6, "Missing Gross Area"),
    (condition_7, "Missing Treatment Unit Area"),
    (condition_8, "Blank total planned cost; need $0 for inhouse/no direct contract cost, or contract $"),
    (condition_9, "Blank activity funding source for booking liability"),
    (condition_10, "Incorrect activity funding source for booking liability"),
    (condition_11, "No planned activity start date for liability booking"),
    (condition_12, "Past due planned activity start date in past fiscals for liability booking"),
    (condition_13, "Declared FG in RESULTS; CMB FG Met Activity not updated"),
    (condition_14, "FG declared/FG Met date discrepancy"),
    (condition_15, "FG Met in LRM without FG declaration in RESULTS"),
    (condition_16, "FG Met block state without FG Met ‘Done’"),
    (condition_17, "Contract $ required for activity?"),
    (condition_18, "TU area exceeds Gross Area of block"),
    (condition_19, "TU area exceeds NAR"),
    (condition_20, "Work ‘should’ already be completed in current fiscal for dropping liability?"),
    (condition_21, "Survey field and data submission  work ‘should’ already be completed in current fiscal for dropping liability"),
    (condition_22, "Work must already be completed in current fiscal for dropping liability")
    
]

# Make a list of all the new column names
new_columns_2 = [column for _, column in conditions_new]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions_new:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions_new:
    df_1[column] = np.where(condition, 'Y', df_1[column])

columns_all = new_columns + new_columns_2

conditions_all = conditions + conditions_new

df_1['Error_2'] = df_1[columns_all].apply(lambda row: 'Y' if 'Y' in row.values else '', axis=1)

# Only keep the rows where there are 'Y's in the new columns (i.e. where there are nonconformances)
selected_df = df_1.query('Error_2 == "Y"')

# Replace the NA's with empty strings to avoid potential errors
selected_df = selected_df.applymap(lambda x: "" if pd.isnull(x) else x)

# Create a list of all the columns where there are nonconformances
columns_with_Y = [col for col in columns_all if (selected_df[col] == 'Y').any()]

# Drop the new columns where there's no 'Y' at all (i.e. where there are no nonconformances)
selected_df = selected_df.drop(columns=[col[1] for col in conditions_all if (selected_df[col[1]] == '').all()])

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
 'UBI',
 'BLOCK_STATE',
 'CUTB_OPENING',
 'SP_EXEMPT',
 'HVS_STATUS',
 'HVS_DATE',
 'HVS_FISCAL',
 'HVC_STATUS',
 'HVC_DATE',
 'HVC_FISCAL',
 'Harvest_Start_After_or_Same_Day_Harvest_Complete',
 'WOFF_STATUS',
 'WOFF_DATE',
 'DEL_STATUS',
 'DEL_DATE',
 'LRM_Expiry_Date',
 'LRM_Extend_Date',
 'LRM_Current_Expiry_Done_Date',
 'LRM_ISSUED_Date',
 'LRM_Substantial_Completion_Date',
 'LRM_Closed_Date',
 'LRM_CANCELLED_Date',
 'LRM_SURRENDERED_Date',
 'FG_Done',
 'RESULTS_FG_DECLARED',
 'FG_MATCH',
 'TREATMENT_UNIT',
 'BLOCK_FUNDING',
 'ACTIVITY_FUNDING',
 'BASE',
 'TECHNIQUE',
 'METHOD',
 'ACTIVITY',
 'STATUS',
 'START_DATE',
 'START_FISCAL',
 'COMPLETE_DATE',
 'GROSS_AREA_BLOCK',
 'NAR_AREA',
 'TREATMENT_AREA',
 'QA_FLAG_TREATMENT_AREA_GREATER_THAN_NAR_AREA',
 'QA_FLAG_TREATMENT_AREA_GREATER_THAN_GROSS_AREA',
 'COST_PER_HA_PLAN',
 'PLANNED_TOTAL_COST',
 'PRIMARY_RECORD'
] 

# Select the columns that will be shown in the final report
columns_kept = [
 'BUSINESS_AREA_REGION',
 'BUSINESS_AREA',
 'BUSINESS_AREA_CODE',
 'FIELD_TEAM',
 'MANU_ID',
 'TENURE',
 'LICENCE',
 'BLOCK_ID',
 'BLOCK_NBR',
 'UBI',
 'BLOCK_STATE',
 'CUTB_OPENING',
 'SP_EXEMPT',
 'HVS_STATUS',
 'HVS_DATE',
 'HVS_FISCAL',
 'HVC_STATUS',
 'HVC_DATE',
 'HVC_FISCAL',
 'Harvest_Start_After_or_Same_Day_Harvest_Complete',
 'WOFF_STATUS',
 'WOFF_DATE',
 'DEL_STATUS',
 'DEL_DATE',
 'LRM_Expiry_Date',
 'LRM_Extend_Date',
 'LRM_Current_Expiry_Done_Date',
 'LRM_ISSUED_Date',
 'LRM_Substantial_Completion_Date',
 'LRM_Closed_Date',
 'LRM_CANCELLED_Date',
 'LRM_SURRENDERED_Date',
 'FG_Done',
 'RESULTS_FG_DECLARED',
 'FG_MATCH',
 'TREATMENT_UNIT',
 'BLOCK_FUNDING',
 'ACTIVITY_FUNDING',
 'BASE',
 'TECHNIQUE',
 'METHOD',
 'ACTIVITY',
 'STATUS',
 'START_DATE',
 'START_FISCAL',
 'COMPLETE_DATE',
 'GROSS_AREA_BLOCK',
 'NAR_AREA',
 'TREATMENT_AREA',
 'QA_FLAG_TREATMENT_AREA_GREATER_THAN_NAR_AREA',
 'QA_FLAG_TREATMENT_AREA_GREATER_THAN_GROSS_AREA',
 'COST_PER_HA_PLAN',
 'PLANNED_TOTAL_COST',
 'PRIMARY_RECORD'
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
output_name_pattern = f'{output_folder}/SilvicultureLiability_Conformance_Summary_YYYY_MM_DD.xlsx'

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
                (columns_all[0] in columns_with_Y) and
                (row[columns_all[0]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['HVS_STATUS'], row['HVS_STATUS'], red_format)  

            if (
                (columns_all[1] in columns_with_Y) and
                (row[columns_all[1]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['START_DATE'], row['START_DATE'], yellow_format)
                worksheet.write(row_idx, column_to_index['ACTIVITY'], row['ACTIVITY'], yellow_format)
                worksheet.write(row_idx, column_to_index['COMPLETE_DATE'], row['COMPLETE_DATE'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVS_STATUS'], row['HVS_STATUS'], red_format) 
                worksheet.write(row_idx, column_to_index['STATUS'], row['STATUS'], red_format)

            if (
                (columns_all[2] in columns_with_Y) and
                (row[columns_all[2]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVS_STATUS'], row['HVS_STATUS'], red_format)

            if (
                (columns_all[3] in columns_with_Y) and
                (row[columns_all[3]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['BLOCK_STATE'], row['BLOCK_STATE'], yellow_format)
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['HVS_STATUS'], row['HVS_STATUS'], red_format) 

            if (
                (columns_all[4] in columns_with_Y) and
                (row[columns_all[4]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['SP_EXEMPT'], row['SP_EXEMPT'], yellow_format)
                worksheet.write(row_idx, column_to_index['NAR_AREA'], row['NAR_AREA'], red_format)

            if (
                (columns_all[5] in columns_with_Y) and
                (row[columns_all[5]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['GROSS_AREA_BLOCK'], row['GROSS_AREA_BLOCK'], red_format)

            if (
                (columns_all[6] in columns_with_Y) and
                (row[columns_all[6]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['TREATMENT_AREA'], row['TREATMENT_AREA'], red_format)   

            if (
                (columns_all[7] in columns_with_Y) and
                (row[columns_all[7]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], red_format)

            if (
                (columns_all[8] in columns_with_Y) and
                (row[columns_all[8]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['ACTIVITY_FUNDING'], row['ACTIVITY_FUNDING'], red_format)
            
            if (
                (columns_all[9] in columns_with_Y) and
                (row[columns_all[9]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['ACTIVITY'], row['ACTIVITY'], yellow_format)
                worksheet.write(row_idx, column_to_index['ACTIVITY_FUNDING'], row['ACTIVITY_FUNDING'], red_format)  

            if (
                (columns_all[10] in columns_with_Y) and
                (row[columns_all[10]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['START_DATE'], row['START_DATE'], red_date_format)

            if (
                (columns_all[11] in columns_with_Y) and
                (row[columns_all[11]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['START_FISCAL'], row['START_FISCAL'], red_format)

            if (
                (columns_all[12] in columns_with_Y) and
                (row[columns_all[12]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['RESULTS_FG_DECLARED'], row['RESULTS_FG_DECLARED'], yellow_date_format) 
                worksheet.write(row_idx, column_to_index['FG_Done'], row['FG_Done'], red_date_format)

            if (
                (columns_all[13] in columns_with_Y) and
                (row[columns_all[13]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['FG_Done'], row['FG_Done'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['RESULTS_FG_DECLARED'], row['RESULTS_FG_DECLARED'], red_date_format)    

            if (
                (columns_all[14] in columns_with_Y) and
                (row[columns_all[14]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['FG_Done'], row['FG_Done'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['RESULTS_FG_DECLARED'], row['RESULTS_FG_DECLARED'], red_date_format)      

            if (
                (columns_all[15] in columns_with_Y) and
                (row[columns_all[15]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['BLOCK_STATE'], row['BLOCK_STATE'], yellow_format)
                worksheet.write(row_idx, column_to_index['RESULTS_FG_DECLARED'], row['RESULTS_FG_DECLARED'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['FG_Done'], row['FG_Done'], red_date_format) 

            if (
                (columns_all[16] in columns_with_Y) and
                (row[columns_all[16]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['ACTIVITY'], row['ACTIVITY'], yellow_format)
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], red_format)

            if (
                (columns_all[17] in columns_with_Y) and
                (row[columns_all[17]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['GROSS_AREA_BLOCK'], row['GROSS_AREA_BLOCK'], yellow_format)
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['TREATMENT_AREA'], row['TREATMENT_AREA'], red_format) 
            
            if (
                (columns_all[18] in columns_with_Y) and
                (row[columns_all[18]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['NAR_AREA'], row['NAR_AREA'], yellow_format)
                worksheet.write(row_idx, column_to_index['TREATMENT_AREA'], row['TREATMENT_AREA'], red_format) 

            if (
                (columns_all[19] in columns_with_Y) and
                (row[columns_all[19]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['ACTIVITY'], row['ACTIVITY'], yellow_format)
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['START_DATE'], row['START_DATE'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['STATUS'], row['STATUS'], red_format)
                
            if (
                (columns_all[20] in columns_with_Y) and
                (row[columns_all[20]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['ACTIVITY'], row['ACTIVITY'], yellow_format)
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['START_DATE'], row['START_DATE'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['STATUS'], row['STATUS'], red_format)

            if (
                (columns_all[21] in columns_with_Y) and
                (row[columns_all[21]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['ACTIVITY'], row['ACTIVITY'], yellow_format)
                worksheet.write(row_idx, column_to_index['PLANNED_TOTAL_COST'], row['PLANNED_TOTAL_COST'], yellow_format)
                worksheet.write(row_idx, column_to_index['START_DATE'], row['START_DATE'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['STATUS'], row['STATUS'], red_format)



                
