SELECT
    LRM.BUSINESS_AREA_REGION_CATEGORY,
    LRM.BUSINESS_AREA_REGION,
    LRM.BUSINESS_AREA,
    LRM.BUSINESS_AREA_CODE,
    LRM.FIELD_TEAM,
    LRM.NAV_NAME,
    LRM.CATEGORY,
    FTA.BCTS_Admin_Category,
    LRM.DISTRICT_NAME,
    LRM.GeographicLocation,
    LRM.Agreement_Type_Code,
    LRM.Agreement_Type,
    LRM.LICENCE_ID AS LRM_LICENCE_ID,
    FTA.forest_file_id AS BCTS_Admin_Licence_ID,
    LRM.LRM_LICENCE_STATE,
    LRM.LRM_Tender_Posted_Status,
    LRM.LRM_Tender_Posted_Date,
    LRM.LRM_Auction_Status,
    LRM.LRM_Auction_Date,
    FTA.auction_date AS BCTS_Admin_Auction_Date,
    FTA.no_sale_rationale_code,
    IIf(
        IsNull(FTA.BCTS_Admin_Vol),
        Null,
        CLng(FTA.BCTS_Admin_Vol)
    ) AS Sale_Volume,
    IIf(IsNull(FTA.FTA_Vol), Null, CLng(FTA.FTA_Vol)) AS FTA_Volume,
    IIf(
        IsNull(FTA.ECAS_TOTAL_Vol),
        Null,
        CLng(FTA.ECAS_TOTAL_Vol)
    ) AS ECAS_TOTAL_VOLUME,
    LRM.LRM_TOTAL_VOLUME,
    LRM.LRM_CRUISE_VOLUME,
    LRM.LRM_RW_VOLUME,
    IIf(
        IsNull(FTA.ECAS_cruise_Vol),
        Null,
        CLng(FTA.ECAS_cruise_Vol)
    ) AS ECAS_Cruise_volume,
    IIf(
        IsNull(FTA.ECAS_DECIDUOUS_Vol),
        Null,
        CLng(FTA.ECAS_DECIDUOUS_Vol)
    ) AS ECAS_Deciduous_Volume,
    IIf(
        IsNull(FTA.ECAS_decked_Vol),
        Null,
        CLng(FTA.ECAS_decked_Vol)
    ) AS ECAS_Decked_Volume,
    IIf(
        IsNull(FTA.ECAS_rw_Vol),
        Null,
        CLng(FTA.ECAS_rw_Vol)
    ) AS ECAS_RW_Volume,
    LRM.LICN_SEQ_NBR
FROM
    qActiveNotices_LRM AS LRM
    LEFT JOIN qActiveNotices_FTA AS FTA ON LRM.LICENCE_ID = FTA.forest_file_id
ORDER BY
    len(BUSINESS_AREA_REGION) DESC,
    BUSINESS_AREA_REGION,
    BUSINESS_AREA,
    LRM.FIELD_TEAM,
    LRM.LICENCE_ID,
    FTA.auction_date;