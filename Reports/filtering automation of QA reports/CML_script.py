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
    file_pattern = os.path.join(script_dir, '../data', 'QA_Multisystem_Tenure_Data_*_*.xlsx')

    # Use glob to find files matching the pattern
    matching_files = glob.glob(file_pattern)

    # Check if any files are found
    if not matching_files:
        raise FileNotFoundError(
            f"""
            The base report cannot be found in your current directory. 
            Please ensure that the base report is in the same folder as this script. 
            The name of the base report should match the following pattern :
            'QA_Multisystem_Tenure_Data_YYYY_MM_DD.xlsx'
            """
        )

    # If files are found, get the first matching file
    file_path = matching_files[0]

    # Read in the data from the base report
    df = pd.read_excel(file_path, sheet_name='qQA_MultisystemTenureData')

except FileNotFoundError as e:
    print(f"Error: {e}")

# Change the datatype of the MARK_SEQ_NBR to Int64 (which was a float before)
df['LICN_SEQ_NBR'] = df['LICN_SEQ_NBR'].astype('Int64')

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



df_1 = df.copy()

df_1['BUSINESS_AREA_CODE'] = (df_1['Business_Area']).apply(lambda x: x[-4:-1])

# Step 1: Deletion of non-licences NOT in FTA 

#####
# Filter 'Licence_in_FTA' for 'N' and 'LRM_Licence_ID_Formatting_Category' for 'LRM invalid Licence ID'  
# or 'LRM possible Licence ID to check' and delete
#####

df_1 = df_1 [
    ~(
            (df_1['Licence_in_FTA'] == 'N') & 
            (
                (df_1['LRM_Licence_ID_Formatting_Category'] == 'LRM invalid Licence ID') | 
                (df_1['LRM_Licence_ID_Formatting_Category'] == 'LRM possible Licence ID to check')
            )
    ) 
]

#####
# Filter ‘FTA_File_Status’ for ‘Licence Closed (HC), Licence Cancelled (HX), or Harvesting Rights Surrendered (HRS)’ 
# Filter ‘LRM Closed Status’ for ‘Done’
# Filter ‘LRM Issued Fiscal’ for ‘blanks’ or prior to 2004
#####

df_1 = df_1[
    ~(
        (
            (df_1['FTA_File_Status'] == 'Closed (HC)') |
            (df_1['FTA_File_Status'] == 'Cancelled (HX)') |
            (df_1['FTA_File_Status'] == 'Harvesting Rights Surrendered (HRS)')
            ) &
        (
            df_1['LRM_Closed_Status'] == 'Done'
            ) &
        (
            (df_1['LRM_Issued_Fiscal'].isnull()) |
            (df_1['LRM_Issued_Fiscal'] < 2004)
            )
    )
]

# Step 2: Deletion of older closed licences 

#####
# Filter ‘LRM Closed Status’ for ‘Done’
# Filter ‘LRM Closed Fiscal’ for previous fiscals (save current and last fiscal) and delete

#####

df_1 = df_1[
    ~(
        (df_1['LRM_Closed_Status'] == 'Done') &
        (df_1['LRM_Closed_Fiscal'] < (current_fiscal - 1))
    )
]

# Mark Duplicate licences in LRM

df_1['Duplicate licences in LRM?'] = (df_1.duplicated(subset='LRM_Licence_ID_Raw', keep=False) | 
                                    df_1.duplicated(subset='Licence_ID', keep=False)).replace({True: 'Y', False: ''})


# Condition 1: If Licence closed in FTA; not closed in LRM
condition_1 = (
    (df_1['FTA_File_Status'] == 'Closed (HC)') &
    (df_1['LRM_Closed_Status'] != 'Done')
)

# Condition 2: If Overdue Closure
condition_2 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Closed_Status'] != 'Done') & 
    (
        (df_1['LRM_Closed_Status'] != 'Planned') | 
        (
            (df_1['LRM_Closed_Date'] <= date_value) |
            (df_1['LRM_Closed_Date'].isnull())
            )
        ) &
    (
        (df_1['Years_Past_LRM_Current_Expiry_Date_At_Report_Date'] >= 3) |
        (current_fiscal - df_1['LRM_Issued_Fiscal'] > 7) |
        (current_fiscal - df_1['FTA_Legal_Effective_Date'].apply(lambda x: x.year) > 7)
    )
)

# Condition 3: If Licence overdue for closure in LRM by >=3 yrs past current expiry date
condition_3 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Closed_Status'] != 'Done') & 
    (
        (df_1['LRM_Closed_Status'] != 'Planned') | 
        (
            (df_1['LRM_Closed_Date'] <= date_value) |
            (df_1['LRM_Closed_Date'].isnull())
            )
        ) &
    (df_1['Years_Past_LRM_Current_Expiry_Date_At_Report_Date'] >= 3)
)

# Condition 4: If Licence overdue for closure in LRM by >7 fiscals past LRM issuance date
condition_4 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Closed_Status'] != 'Done') & 
    (
        (df_1['LRM_Closed_Status'] != 'Planned') | 
        (
            (df_1['LRM_Closed_Date'] <= date_value) |
            (df_1['LRM_Closed_Date'].isnull())
            )
        ) &
    (df_1['LRM_Current_Expiry_Date'].isnull()) &
    (current_fiscal - df_1['LRM_Issued_Fiscal'] > 7)
)

# Condition 5: If Licence overdue for closure in LRM by > 7 yrs past FTA legal effective date
condition_5 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Issued_Fiscal'].isnull()) &
    (df_1['LRM_Closed_Status'] != 'Done') & 
    (
        (df_1['LRM_Closed_Status'] == 'Planned') | 
        (
            (df_1['LRM_Closed_Date'] <= date_value) |
            (df_1['LRM_Closed_Date'].isnull())
            )
        ) &
    (current_fiscal - df_1['FTA_Legal_Effective_Date'].apply(lambda x: x.year) > 7)
)

# Make a list of all the conditions and their corresponding column names
conditions = [
    (condition_1, "Licence closed in FTA; not closed in LRM"),
    (condition_2, "Overdue Closure"),
    (condition_3, "Licence overdue for closure in LRM by >=3 yrs past current expiry date"),
    (condition_4, "Licence overdue for closure in LRM by >7 fiscals past LRM issuance date"),
    (condition_5, "Licence overdue for closure in LRM by > 7 yrs past FTA legal effective date")
]

# Make a list of all the new column names
new_columns = [column for _, column in conditions]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions:
    df_1[column] = np.where(condition, 'Y', df_1[column])


new_columns_1 = ['Duplicate licences in LRM?'] + new_columns

df_1['Error_1'] = df_1[new_columns_1].apply(lambda row: 'Y' if 'Y' in row.values else '', axis=1)

# Condition 6: If Change Circumstance Completion not documented at licence closure
condition_6 = (
    (df_1['Error_1'] == '') &
    (df_1['LRM_Tenure_Type'] != 'B07') &
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Issued_Fiscal'] >= 2021) &
    (df_1['LRM_Closed_Status'] == 'Done') &
    (df_1['LRM_Surrendered_Status'] != 'Done') &
    (df_1['LRM_Cancelled_Status'] != 'Done') &
    (
        (df_1['LRM_Change_Circumstance_Post_Award_Status'] == 'Planned') | 
        (df_1['LRM_Change_Circumstance_Post_Award_Status'].isnull())
        )
)

# Condition 7: If LRM Category mismatch with FTA Sold Category
condition_7 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Tenure_Type'] == 'B20') &
    (df_1['LRM_Category_vs_FTA_Sold_Category_Flag'] == 1) &
    ~(
        (df_1['LRM_Category'] == 'Any/All Registrant Categories (A)') & 
        (df_1['FTA_Sold_Category'] == 'Non-milling (1)')
        ) &
    ~(
        (df_1['LRM_Category'] == 'Value-added (4)') & 
        (df_1['FTA_Sold_Category'] == 'Milling (2)')
        )
) 

# Condition 8: If Licence issued in FTA; Not issued in LRM” error
condition_8 = (
    (
        (df_1['FTA_File_Status'] == 'Issued (HI)') |
        (df_1['FTA_File_Status'] == 'Logging Complete (LC)') |
        (df_1['FTA_File_Status'] == 'Suspended (HS)')
    ) &
    (df_1['LRM_Issued_Status'] != 'Done') &
    (df_1['LRM_Closed_Status'] != 'Done')
)

# Condition 9: If Licence cancelled in LRM on un-issued licence; must be issued & cancelled under S78/78.1/164.1 of Forest Act
condition_9 = (
    (df_1['LRM_Issued_Status'] != 'Done') &
    (df_1['LRM_Cancelled_Status'] == 'Done')
)


# Condition 10: If Licence surrendered in LRM; needs to be closed in LRM
condition_10 = (
    (df_1['LRM_Surrendered_Status'] == 'Done') &
    (df_1['LRM_Closed_Status'] != 'Done')
)

# Condition 11: If Issuance date discrepancy between FTA and LRM
condition_11 = (
    (df_1['Overdue Closure'] != 'Y') &
    (df_1['LRM_Issued_Status'] == 'Done') &
    (
        (df_1['LRM_Closed_Status'] == 'Planned') |
        (df_1['LRM_Closed_Status'] == 'Not Required')
        ) & 
    (df_1['FTA_Legal_Effective_Date'].notnull()) &
    (df_1['LRM_Issued_vs_FTA_Effective_Date_Flag'] == 1)
)

# Condition 12: If Initial expiry date discrepancy between FTA and LRM
condition_12 = (
    (df_1['Overdue Closure'] != 'Y') &
    (df_1['LRM_Issued_Status'] == 'Done') &
    (
        (df_1['LRM_Closed_Status'] == 'Planned') |
        (df_1['LRM_Closed_Status'] == 'Not Required')
        ) & 
    (df_1['FTA_Legal_Effective_Date'].notnull()) &
    (df_1['LRM_Expiry_vs_FTA_Initial_Expiry_Date_Flag'] == 1)
)

# Condition 13: If Extension date discrepancy between FTA and LRM
condition_13 = (
    (df_1['Overdue Closure'] != 'Y') &
    (df_1['LRM_Issued_Status'] == 'Done') &
    (
        (df_1['LRM_Closed_Status'] == 'Planned') |
        (df_1['LRM_Closed_Status'] == 'Not Required')
        ) & 
    (df_1['FTA_Legal_Effective_Date'].notnull()) &
    (df_1['LRM_vs_FTA_Current_Expiry_Date_Flag'] == 1) &
    (df_1['FTA_Current_Expiry_Date'].notnull())
)

#  Make a list of all the newly added conditions and their corresponding column names
conditions_2 = [
    (condition_6, "Change Circumstance Completion not documented at licence closure"),
    (condition_7, "LRM Category mismatch with FTA Sold Category"),
    (condition_8, "Licence issued in FTA; Not issued in LRM” error"),
    (condition_9, "Licence cancelled in LRM on un-issued licence; must be issued & cancelled under S78/78.1/164.1 of Forest Act"),
    (condition_10, "Licence surrendered in LRM; needs to be closed in LRM"),
    (condition_11, "Issuance date discrepancy between FTA and LRM"),
    (condition_12, "Initial expiry date discrepancy between FTA and LRM"),
    (condition_13, "Extension date discrepancy between FTA and LRM")
]

# Make a list of all the new column names
new_columns_2 = [column for _, column in conditions_2]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions_2:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions_2:
    df_1[column] = np.where(condition, 'Y', df_1[column])


new_columns_2 = new_columns_1 + new_columns_2

df_1['Error_2'] = df_1[new_columns_2].apply(lambda row: 'Y' if 'Y' in row.values else '', axis=1)

df_1 = df_1[~((df_1['LRM_Issued_Status'] != 'Done') & (df_1['Error_2'] != 'Y'))]

# Condition 14: If Licence cancelled in FTA; issued but not cancelled in LRM
condition_14 = (
    (df_1['FTA_File_Status'] == 'Cancelled (HX)') &
    (df_1['LRM_Cancelled_Status'] != 'Done')
)

# Condition 15: If Licence surrendered in FTA; not surrendered in LRM
condition_15 = (
    (df_1['FTA_File_Status'] == 'Harvesting Rights Surrendered (HRS)') &
    (df_1['LRM_Surrendered_Status'] != 'Done') 
)

# Condition 16: If Legitimate licence cancellation needs to be closed in LRM
condition_16 = (
    (df_1['LRM_Cancelled_Status'] == 'Done') &
    (df_1['LRM_Closed_Status'] != 'Done')
)

# Condition 17: If Issued licence missing LRM Tenure
condition_17 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Tenure_Type'].isnull())
)

# Condition 18: If Issued licence missing LRM Category for B20 licence
condition_18 = (
    (df_1['LRM_Issued_Status'] == 'Done') &
    (df_1['LRM_Category'].isnull()) &
    (df_1['LRM_Tenure_Type'] == 'B20')
)

conditions_3 = [
    (condition_14, "Licence cancelled in FTA; issued but not cancelled in LRM"),
    (condition_15, "Licence surrendered in FTA; not surrendered in LRM"),
    (condition_16, "Legitimate licence cancellation needs to be closed in LRM"),
    (condition_17, "Issued licence missing LRM Tenure"),
    (condition_18, "Issued licence missing LRM Category for B20 licence")
]

# Make a list of all the new column names
new_columns_3 = [column for _, column in conditions_3]

# Tentatively fill the new columns with empty strings as a placeholder
for _, column in conditions_3:
    df_1[column] = ''

# Fill in the 'Y's where the conditions are met
for condition, column in conditions_3:
    df_1[column] = np.where(condition, 'Y', df_1[column])


new_columns_all = new_columns_2 + new_columns_3

conditions_all = conditions + conditions_2 + conditions_3

df_1['Error_3'] = df_1[new_columns_all].apply(lambda row: 'Y' if 'Y' in row.values else '', axis=1)

# Only keep the rows where there are 'Y's in the new columns (i.e. where there are nonconformances)
selected_df = df_1.query('Error_3 == "Y"')

# Replace the NA's with empty strings to avoid potential errors
selected_df = selected_df.applymap(lambda x: "" if pd.isnull(x) else x)

# Create a list of all the columns where there are nonconformances
columns_with_Y = [col for col in new_columns_all if (selected_df[col] == 'Y').any()]

# Drop the new columns where there's no 'Y' at all (i.e. where there are no nonconformances)
selected_df = selected_df.drop(columns=[col[1] for col in conditions_all if (selected_df[col[1]] == '').all()])

### Create a summary dataframe for the conformance summary sheet

# Create a new data list
summary_data = []

# Accumulator for the total number of nonconformances for all the regions
all_region_total = 0

for region, area in area_list.items():
    # Make a summary for each region
    region_data = selected_df[selected_df['Business_Area_Region'] == region] 

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
        area_data = region_data[region_data['Business_Area'] == area]

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
 'Licence_ID',
 'LRM_Licence_ID_Raw',
 'Licence_in_FTA',
 'LRM_Category',
 'FTA_Sold_Category',
 'LRM_Tenure_Type',
 'FTA_File_Status',
 'LRM_Issued_Status',
 'LRM_Issued_Date',
 'LRM_Issued_Fiscal',
 'FTA_Legal_Effective_Date',
 'LRM_Expiry_Date',
 'LRM_Extend_Date',
 'LRM_Current_Expiry_Date',
 'Years_Past_LRM_Current_Expiry_Date_At_Report_Date',
 'FTA_Initial_Expiry_Date',
 'FTA_Current_Expiry_Date',
 'LRM_Closed_Status',
 'LRM_Closed_Fiscal',
 'LRM_Cancelled_Status',
 'LRM_Cancelled_Date',
 'LRM_Surrendered_Status',
 'LRM_Surrendered_Date',
 'LRM_Change_Circumstance_Post_Award_Status',
 'LRM_Duplicate_Licence_ID_Count',
 'LRM_Category_vs_FTA_Sold_Category_Flag',
 'LRM_Issued_vs_FTA_Effective_Date_Flag',
 'LRM_Expiry_vs_FTA_Initial_Expiry_Date_Flag',
 'LRM_vs_FTA_Current_Expiry_Date_Flag'
 ]

# Select the columns that will be shown in the final report
columns_kept = [
 'Business_Area_Region',
 'Business_Area',
 'BUSINESS_AREA_CODE',
 'Field_Team',
 'Licence_ID',
 'LRM_Licence_ID_Raw',
 'Licence_in_FTA',
 'LRM_Category',
 'FTA_Sold_Category',
 'BCTS_Admin_Category',
 'LRM_Tenure_Type',
 'FTA_Tenure_Type',
 'LRM_Licence_State',
 'FTA_File_Status',
 'FTA_File_Status_Fiscal',
 'LRM_Issued_Status',
 'LRM_Issued_Date',
 'LRM_Issued_Fiscal',
 'FTA_Legal_Effective_Date',
 'LRM_Expiry_Date',
 'LRM_Extend_Date',
 'LRM_Current_Expiry_Date',
 'Years_Past_LRM_Current_Expiry_Date_At_Report_Date',
 'FTA_Initial_Expiry_Date',
 'FTA_Current_Expiry_Date',
 'LRM_Closed_Status',
 'LRM_Closed_Fiscal',
 'LRM_Closed_Date',
 'LRM_Cancelled_Status',
 'LRM_Cancelled_Date',
 'LRM_Surrendered_Status',
 'LRM_Surrendered_Date',
 'LRM_Change_Circumstance_Post_Award_Status',
 'LRM_Duplicate_Licence_ID_Count',
 'LRM_Category_vs_FTA_Sold_Category_Flag',
 'LRM_Issued_vs_FTA_Effective_Date_Flag',
 'LRM_Expiry_vs_FTA_Initial_Expiry_Date_Flag',
 'LRM_vs_FTA_Current_Expiry_Date_Flag',
 'LICN_SEQ_NBR'
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
output_name_pattern = f'{output_folder}/Corporate_Mandatory_Licence_(CML)_Data_Conformance_Summary_YYYY_MM_DD.xlsx'

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
                (new_columns_all[0] in columns_with_Y) and
                (row[new_columns_all[0]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['Licence_ID'], row['Licence_ID'], red_format)
                worksheet.write(row_idx, column_to_index['LRM_Licence_ID_Raw'], row['LRM_Licence_ID_Raw'], red_format)  

            if (
                (new_columns_all[1] in columns_with_Y) and
                (row[new_columns_all[1]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['FTA_File_Status'], row['FTA_File_Status'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format)

            if (
                (new_columns_all[2] in columns_with_Y) and
                (row[new_columns_all[2]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format)

            if (
                (new_columns_all[3] in columns_with_Y) and
                (row[new_columns_all[3]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['Years_Past_LRM_Current_Expiry_Date_At_Report_Date'], row['Years_Past_LRM_Current_Expiry_Date_At_Report_Date'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Current_Expiry_Date'], row['LRM_Current_Expiry_Date'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format)  

            if (
                (new_columns_all[4] in columns_with_Y) and
                (row[new_columns_all[4]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Current_Expiry_Date'], row['LRM_Current_Expiry_Date'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Fiscal'], row['LRM_Issued_Fiscal'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format)

            if (
                (new_columns_all[5] in columns_with_Y) and
                (row[new_columns_all[5]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['FTA_Legal_Effective_Date'], row['FTA_Legal_Effective_Date'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Fiscal'], row['LRM_Issued_Fiscal'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format)

            if (
                (new_columns_all[6] in columns_with_Y) and
                (row[new_columns_all[6]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Tenure_Type'], row['LRM_Tenure_Type'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Fiscal'], row['LRM_Issued_Fiscal'], yellow_format)  
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], yellow_format)  
                worksheet.write(row_idx, column_to_index['LRM_Surrendered_Status'], row['LRM_Surrendered_Status'], yellow_format)  
                worksheet.write(row_idx, column_to_index['LRM_Cancelled_Status'], row['LRM_Cancelled_Status'], yellow_format)  
                worksheet.write(row_idx, column_to_index['LRM_Change_Circumstance_Post_Award_Status'], row['LRM_Change_Circumstance_Post_Award_Status'], red_format)   

            if (
                (new_columns_all[7] in columns_with_Y) and
                (row[new_columns_all[7]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Tenure_Type'], row['LRM_Tenure_Type'], yellow_format)  
                worksheet.write(row_idx, column_to_index['LRM_Category_vs_FTA_Sold_Category_Flag'], row['LRM_Category_vs_FTA_Sold_Category_Flag'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Category'], row['LRM_Category'], red_format)
                worksheet.write(row_idx, column_to_index['FTA_Sold_Category'], row['FTA_Sold_Category'], red_format)

            if (
                (new_columns_all[8] in columns_with_Y) and
                (row[new_columns_all[8]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['FTA_File_Status'], row['FTA_File_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], yellow_format)  
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], red_format)
            
            if (
                (new_columns_all[9] in columns_with_Y) and
                (row[new_columns_all[9]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Cancelled_Status'], row['LRM_Cancelled_Status'], red_format)  

            if (
                (new_columns_all[10] in columns_with_Y) and
                (row[new_columns_all[10]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Surrendered_Status'], row['LRM_Surrendered_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format)

            if (
                (new_columns_all[11] in columns_with_Y) and
                (row[new_columns_all[11]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['FTA_Legal_Effective_Date'], row['FTA_Legal_Effective_Date'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_vs_FTA_Effective_Date_Flag'], row['LRM_Issued_vs_FTA_Effective_Date_Flag'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Change_Circumstance_Post_Award_Status'], row['LRM_Change_Circumstance_Post_Award_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Date'], row['LRM_Issued_Date'], red_date_format)

            if (
                (new_columns_all[12] in columns_with_Y) and
                (row[new_columns_all[12]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['FTA_Initial_Expiry_Date'], row['FTA_Initial_Expiry_Date'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['LRM_Expiry_vs_FTA_Initial_Expiry_Date_Flag'], row['LRM_Expiry_vs_FTA_Initial_Expiry_Date_Flag'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Change_Circumstance_Post_Award_Status'], row['LRM_Change_Circumstance_Post_Award_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Expiry_Date'], row['LRM_Expiry_Date'], red_date_format)     

            if (
                (new_columns_all[13] in columns_with_Y) and
                (row[new_columns_all[13]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['FTA_Legal_Effective_Date'], row['FTA_Legal_Effective_Date'], yellow_date_format)
                worksheet.write(row_idx, column_to_index['LRM_vs_FTA_Current_Expiry_Date_Flag'], row['LRM_vs_FTA_Current_Expiry_Date_Flag'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Change_Circumstance_Post_Award_Status'], row['LRM_Change_Circumstance_Post_Award_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Extend_Date'], row['LRM_Extend_Date'], red_date_format)     

            if (
                (new_columns_all[14] in columns_with_Y) and
                (row[new_columns_all[14]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['FTA_File_Status'], row['FTA_File_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Cancelled_Status'], row['LRM_Cancelled_Status'], red_format) 

            if (
                (new_columns_all[15] in columns_with_Y) and
                (row[new_columns_all[15]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['FTA_File_Status'], row['FTA_File_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Surrendered_Status'], row['LRM_Surrendered_Status'], red_format) 

            if (
                (new_columns_all[16] in columns_with_Y) and
                (row[new_columns_all[16]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Cancelled_Status'], row['LRM_Cancelled_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Closed_Status'], row['LRM_Closed_Status'], red_format) 
            
            if (
                (new_columns_all[17] in columns_with_Y) and
                (row[new_columns_all[17]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Tenure_Type'], row['LRM_Tenure_Type'], red_format) 

            if (
                (new_columns_all[18] in columns_with_Y) and
                (row[new_columns_all[18]] == 'Y')
                ):
                worksheet.write(row_idx, column_to_index['LRM_Issued_Status'], row['LRM_Issued_Status'], yellow_format)
                worksheet.write(row_idx, column_to_index['LRM_Tenure_Type'], row['LRM_Tenure_Type'], yellow_format) 
                worksheet.write(row_idx, column_to_index['LRM_Category'], row['LRM_Category'], red_format) 
                





