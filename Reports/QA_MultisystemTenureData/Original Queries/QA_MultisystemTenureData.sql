SELECT
    lrm.Business_Area_Region_Category,
    lrm.Business_Area_Region,
    lrm.Business_Area,
    lrm.Field_Team,
    lrm.lrm_licence_id_clean AS Licence_ID,
    iif(
        lrm.lrm_licence_id_clean = lrm.LRM_Licence_ID_Raw,
        'LRM Licence ID in standard format',
        iif(
            lrm.LRM_Possible_Valid_Licence_Id is null,
            'LRM invalid Licence ID',
            iif(
                lrm.lrm_licence_id_clean is not null,
                'LRM Licence ID in non-standard format',
                'LRM possible Licence ID to check',
            )
        )
    ) AS LRM_Licence_ID_Formatting_Category,
    lrm.LRM_Licence_ID_Raw,
    iif(
        lrm.lrm_licence_id_clean is not null
        and lrm.lrm_licence_id_clean <> lrm.LRM_Licence_ID_Raw,
        lrm.LRM_Licence_ID_Raw,
        null
    ) AS LRM_Licence_ID_Non_Standard_Format,
    iif(
        lrm.lrm_licence_id_clean is null
        and lrm.LRM_Possible_Valid_Licence_Id is not null,
        lrm.LRM_Possible_Valid_Licence_Id,
        null
    ) AS LRM_Possible_Licence_ID_To_Check,
    iif(
        lrm.LRM_Possible_Valid_Licence_Id is null,
        lrm.LRM_Licence_ID_Raw,
        null
    ) AS LRM_Invalid_Licence_ID,
    lrm.LRM_Block_Count_for_Licence,
    iif(
        fta_admin.forest_file_id is null,
        'N',
        'Y'
    ) AS Licence_in_FTA,
    fta_admin.Licence_in_BCTS_ADMIN,
    lrm.LRM_Category,
    fta_admin.FTA_Planned_Category,
    fta_admin.FTA_Sold_Category,
    fta_admin.BCTS_Admin_Category,
    lrm.LRM_Tenure_Type,
    fta_admin.FTA_Tenure_Type,
    fta_admin.FTA_Sale_Method,
    fta_admin.FTA_Permittee_Client_Number,
    fta_admin.FTA_Permittee,
    fta_admin.FTA_Total_Bidders,
    fta_admin.BCTS_Admin_Eligible_Bidder_Count_Latest_Auction,
    fta_admin.BCTS_Admin_Ineligible_Bidder_Count_Latest_Auction,
    fta_admin.BCTS_Admin_Eligibility_Missing_Count_Latest_Auction,
    lrm.LRM_Licence_State,
    fta_admin.FTA_File_Status,
    fta_admin.FTA_File_Status_Date,
    fta_admin.FTA_File_Status_Fiscal,
    lrm.LRM_Tender_Posted_Status,
    lrm.LRM_Tender_Posted_Date,
    fta_admin.FTA_Tender_Opening_Date,
    lrm.LRM_Auction_Status,
    lrm.LRM_Auction_Date,
    fta_admin.FTA_Planned_Sale_Date,
    fta_admin.BCTS_Admin_Latest_Auction_Date,
    fta_admin.BCTS_Admin_No_Sale_Rationale_Code,
    fta_admin.BCTS_Admin_Sale_Awarded,
    lrm.LRM_Awarded_Status,
    lrm.LRM_Awarded_Date,
    fta_admin.BCTS_Admin_Approved_Date,
    fta_admin.BCTS_Admin_Approved_By,
    lrm.LRM_Issued_Status,
    lrm.LRM_Issued_Date,
    lrm.LRM_Issued_Fiscal,
    lrm.LRM_Issued_Quarter,
    fta_admin.FTA_Legal_Effective_Date,
    lrm.LRM_Expiry_Date,
    lrm.LRM_Extend_Date,
    lrm.LRM_Current_Expiry_Date,
    lrm.Days_Past_LRM_Current_Expiry_Date_At_Report_Date,
    lrm.Months_Past_LRM_Current_Expiry_Date_At_Report_Date,
    lrm.Years_Past_LRM_Current_Expiry_Date_At_Report_Date,
    fta_admin.FTA_Initial_Expiry_Date,
    fta_admin.FTA_Current_Expiry_Date,
    fta_admin.FTA_Tenure_Term AS FTA_Tenure_Term_Months,
    iif(
        fta_admin.FTA_Legal_Effective_Date is null
        or fta_admin.FTA_TENURE_TERM is null
        or fta_admin.FTA_TENURE_TERM = 0,
        null,
        DateAdd(
            "d",
            -1,
            DateAdd(
                "m",
                fta_admin.FTA_TENURE_TERM,
                fta_admin.FTA_Legal_Effective_Date
            )
        )
    ) AS FTA_Expiry_Date_by_Term,
    lrm.LRM_Substantial_Completion_Status,
    lrm.LRM_Substantial_Completion_Date,
    lrm.LRM_Closed_Status,
    lrm.LRM_Closed_Date,
    lrm.LRM_Closed_Fiscal,
    lrm.LRM_Closed_Quarter,
    lrm.LRM_Cancelled_Status,
    lrm.LRM_Cancelled_Date,
    lrm.LRM_Surrendered_Status,
    lrm.LRM_Surrendered_Date,
    lrm.LRM_VCU_Rate_Calculation_Status,
    lrm.LRM_VCU_Rate_Calculation_Date,
    lrm.LRM_Change_Circumstance_Post_Award_Status,
    lrm.LRM_Change_Circumstance_Post_Award_Date,
    IIf(
        lrm_duplicate_clean_licence_id.licence_id_count > 1,
        lrm_duplicate_clean_licence_id.licence_id_count,
        null
    ) AS LRM_Duplicate_Licence_ID_Count,
    IIf(
        lrm.LRM_Category_Description is null,
        1,
        0
    ) AS LRM_Category_Invalid_Flag,
    IIf(
        Nz(lrm.LRM_Category_Code) <> Nz(fta_admin.FTA_Planned_Category_Code),
        1,
        0
    ) AS LRM_Category_vs_FTA_Planned_Category_Flag,
    IIf(
        Nz(lrm.LRM_Category_Code) <> Nz(fta_admin.FTA_Sold_Category_Code),
        1,
        0
    ) AS LRM_Category_vs_FTA_Sold_Category_Flag,
    IIf(
        Nz(fta_admin.FTA_Planned_Category_Code) <> Nz(fta_admin.FTA_Sold_Category_Code),
        1,
        0
    ) AS FTA_Planned_Category_vs_FTA_Sold_Category_Flag,
    IIf(
        Nz(lrm.LRM_Category_Code) <> Nz(fta_admin.BCTS_Admin_Category_Code),
        1,
        0
    ) AS LRM_Category_vs_BCTS_Admin_Category_Flag,
    IIf(
        Nz(lrm.LRM_Tenure_Type) <> Nz(fta_admin.FTA_Tenure_Type),
        1,
        0
    ) AS LRM_vs_FTA_Tenure_Type_Flag,
    IIf(
        Nz(fta_admin.BCTS_Admin_Latest_Auction_Date) <> Nz(LRM.LRM_AUCTION_Date),
        1,
        0
    ) AS LRM_vs_BCTS_Admin_Auction_Date_Flag,
    IIf(
        fta_admin.BCTS_Admin_Sale_Awarded = 'Y'
        and fta_admin.BCTS_Admin_Approved_Date <> lrm.LRM_Awarded_Date,
        1,
        0
    ) AS LRM_vs_BCTS_Admin_Awarded_Date_Flag,
    IIF(
        Nz(FTA_Total_Bidders) <> Nz(BCTS_Admin_Eligible_Bidder_Count_Latest_Auction)
        And fta_admin.BCTS_Admin_Sale_Awarded = 'Y',
        1,
        0
    ) AS FTA_BCTS_Admin_Total_Eligible_Bidder_Flag,
    fta_admin.BCTS_Admin_Ineligible_Indicator_Missing,
    IIf(
        Nz(fta_admin.FTA_Legal_Effective_Date) <> Nz(LRM.LRM_ISSUED_Date),
        1,
        0
    ) AS LRM_Issued_vs_FTA_Effective_Date_Flag,
    IIf(
        Nz(fta_admin.FTA_INITIAL_EXPIRY_DATE) <> Nz(LRM.LRM_Expiry_Date),
        1,
        0
    ) AS LRM_Expiry_vs_FTA_Initial_Expiry_Date_Flag,
    IIf(
        Nz(fta_admin.FTA_CURRENT_EXPIRY_DATE) <> Nz(LRM.LRM_Current_Expiry_Date),
        1,
        0
    ) AS LRM_vs_FTA_Current_Expiry_Date_Flag,
    IIf(
        Days_Past_LRM_Current_Expiry_Date_At_Report_Date >= 1,
        1,
        0
    ) AS One_or_More_Days_Past_Current_LRM_Expiry_Date_Flag,
    IIf(
        Years_Past_LRM_Current_Expiry_Date_At_Report_Date >= 2,
        1,
        0
    ) AS Two_or_More_Years_Past_Current_LRM_Expiry_Date_Flag,
    IIf(
        Years_Past_LRM_Current_Expiry_Date_At_Report_Date >= 3,
        1,
        0
    ) AS Three_or_More_Years_Past_Current_LRM_Expiry_Date_Flag,
    IIf(
        fta_admin.FTA_File_Status_Code = 'LC'
        AND fta_admin.FTA_File_Status_Date <> Nz(LRM.LRM_Substantial_Completion_Date),
        1,
        0
    ) AS LRM_SC_vs_FTA_LC_Status_Date_Flag,
    IIf(
        fta_admin.FTA_File_Status_Code = 'HC'
        AND fta_admin.FTA_File_Status_Date <> Nz(LRM.LRM_Closed_Date),
        1,
        0
    ) AS LRM_HC_vs_FTA_HC_Status_Date_Flag,
    lrm.LICN_SEQ_NBR
FROM
    (
        qQA_MultisystemTenureData_LRM AS lrm
        LEFT JOIN qQA_MultisystemTenureData_FTA_BctsAdmin AS fta_admin ON lrm.lrm_licence_id_clean = fta_admin.forest_file_id
    )
    LEFT JOIN (
        SELECT
            lrm0.lrm_licence_id_clean,
            count(lrm0.lrm_licence_id_clean) AS licence_id_count
        FROM
            qQA_MultisystemTenureData_LRM AS lrm0
        GROUP BY
            lrm0.lrm_licence_id_clean
    ) AS lrm_duplicate_clean_licence_id ON lrm.lrm_licence_id_clean = lrm_duplicate_clean_licence_id.lrm_licence_id_clean
ORDER BY
    len(lrm.business_area_region) DESC,
    lrm.business_area_region,
    lrm.business_area,
    lrm.field_team,
    lrm.lrm_licence_id_clean,
    lrm.lrm_licence_id_raw;