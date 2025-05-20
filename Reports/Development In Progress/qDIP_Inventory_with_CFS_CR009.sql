SELECT DIP.BUSINESS_AREA_REGION_CATEGORY, DIP.BUSINESS_AREA_REGION, DIP.BUSINESS_AREA, DIP.FIELDTEAM, DIP.MANU_ID, DIP.LICENCE_ID, DIP.TENURE_TYPE, DIP.PERM_PERMIT_ID, DIP.MARK_MARK_ID, DIP.BLOCK_ID, DIP.UBI, DIP.BLOCK_NBR, DIP.SUB_OPERATING_AREA, DIP.LICN_LICENCE_STATE, DIP.CUTB_BLOCK_STATE, DIP.DEFERRED_AT_REPORT_DATE, DIP.INVENTORY_CATEGORY, DIP.MERCH_AREA, DIP.CRUISE_VOLUME, DIP.RW_VOLUME, DIP.RC_STATUS, DIP.RC_DATE, DIP.RC_FISCAL, DIP.DR_STATUS, DIP.DR_DATE, DIP.DR_FISCAL, DIP.DVS_STATUS, DIP.DVS_DATE, CStr(DIP.DVS_DATE) AS DVS_Done, DIP.DVS_FISCAL, DIP.DSC_STATUS, DIP.DSC_DATE, DIP.DVC_STATUS, DIP.DVC_DATE, DIP.DVC_FISCAL, DIP.AUC_STATUS, DIP.AUC_DATE, DIP.HI_STATUS, DIP.HI_DATE, DIP.HVS_STATUS, DIP.HVS_DATE, DIP.HVC_STATUS, DIP.HVC_DATE, DIP.FG_Met_Status, DIP.FG_DATE, DIP.DEF_Change_of_Op_Plan_Status, DIP.DEF_Change_of_Op_Plan, DIP.DEF_First_Nations_Status, DIP.DEF_First_Nations, DIP.DEF_Loss_of_Access_Status, DIP.DEF_Loss_of_Access, DIP.DEF_Other_Status, DIP.DEF_Other, DIP.DEF_Planning_Constraint_Status, DIP.DEF_Planning_Constraint, DIP.DEF_Returned_to_BCTS_Status, DIP.DEF_Returned_to_BCTS, DIP.DEF_Stale_dated_Fieldwork_Status, DIP.DEF_Stale_dated_Fieldwork, DIP.DEF_Stakeholder_Issue_Status, DIP.DEF_Stakeholder_Issue, DIP.DEF_Environmental_Stewardship_Initiative_Status, DIP.DEF_Environmental_Stewardship_Initiative, DIP.DEF_REACTIVATED_Status, DIP.DEF_REACTIVATED, DIP.Old_Growth_Strategy_Status, DIP.Old_Growth_Strategy, DIP.OGS_Reactivated_Forest_Health_Status, DIP.OGS_Reactivated_Forest_Health, DIP.OGS_Reactivated_FN_Proceed_Status, DIP.OGS_Reactivated_FN_Proceed, DIP.OGS_Reactivated_Field_Verified_Status, DIP.OGS_Reactivated_Field_Verified, DIP.OGS_Reactivated_Minor_Status, DIP.OGS_Reactivated_Minor, DIP.OGS_Reactivated_Road_Status, DIP.OGS_Reactivated_Road, DIP.OGS_Reactivated_Re_Engineered_Status, DIP.OGS_Reactivated_Re_Engineered, DIP.Days_in_DIP, IIf(
        DIP.Days_in_DIP < 1,
        "Less than One Day",
        IIf(
            DIP.Days_in_DIP < 181,
            "1 to 180 Days",
            IIf(
                DIP.Days_in_DIP < 366,
                "181 to 365 Days",
                IIf(
                    DIP.Days_in_DIP < 546,
                    "366 to 545 Days",
                    IIf(
                        DIP.Days_in_DIP < 731,
                        "546 to 730 Days",
                        "Greater Than Two Years"
                    )
                )
            )
        )
    ) AS Days_in_DIP_Category, DIP.WOFF_STATUS, DIP.WOFF_DATE, DIP.WOFF_FISCAL, CS.*, getFiscal(CS.Last_Date) AS LAST_FISCAL, DIP.XXX_ZZZ_FLAG, DIP.SPATIAL_FLAG, DIP.RC_FLAG, DIP.DR_FLAG, DIP.DVS_FLAG, DIP.DSC_FLAG, DIP.DVC_FLAG, DIP.LICN_SEQ_NBR, DIP.MARK_SEQ_NBR, DIP.CUTB_SEQ_NBR
FROM qDIP_Inventory_LRM_CR009 AS DIP LEFT JOIN qCFS_SvrLine AS CS ON DIP.UBI = CS.CFS_UBI
ORDER BY len(business_area_region) DESC , business_area_region, business_area, fieldteam, manu_id, licence_id, ubi;
