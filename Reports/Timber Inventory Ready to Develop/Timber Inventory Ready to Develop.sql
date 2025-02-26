-- Report Name: !Timber Inventory - Ready to Develop
/* Report Query Name: qReadyToDevelop
Specification:
A monthly report of blocks that are DR 'Done', but are not development started or written off.
- DR completion date is up to the reporting 'To' date.
- DVS is NOT 'Done'.
- DVC is NOT 'Done'.
- Write Off is NOT 'Done'.
- Deletion Approval is NOT 'Done'.
- HI, HC, HX, and HS are NOT 'Done'.
* INVENTORY_CATEGORY:
     - OGS: Old Growth Strategy (OGS) Date is after any OGS related reactivation date.
     - Deferred: The latest deferral (excuding OGS) date is after Reactivated (DRD) Date.
     - No Deferral: Not OGS and Not Deferred.
     o When both (OGS) and conventional deferrals exist for the same block, it is set to OGS.
# Key Fields: DR Status, DR Completion Date, Development Started (DVS) Status, Development Completed (DVC) Status.
Change Log:
Implemented RC DR split. 2023-05-23, NJ.
Added Environmental Stewardship Initiative deferral category. 2023-04-17, NJ.
Split RCDR into RC and DR per Janie Ramsey's request. 2022-08-08, RX.
Renamed to !TimberInventory_ReadytoDevelop from RCDR_Inventory per Ron Letham's request. 2022-06-08, RX.
Added Deferrals per Ron Letham and Janie Ramsey's request. Removed planned dates as they are disabled in LRM for over a year now. 2022-05-11, RX.
Added RCDR_Category per DSWG request. 2022-03-04, RX.
Added Deletion Approval (DEL) filter to remove Deletion Approval 'Done' blocks per Ron Lathem's request. 2021-08-25, RX.
*/
SELECT DISTINCT
    case
        when
            BLOCK.TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            BLOCK.TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            BLOCK.TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            BLOCK.TSO_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            BLOCK.TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        BLOCK.TSO_NAME,
        'Seaward', -- See https://apps.nrs.gov.bc.ca/int/jira/projects/SD/queues/issue/SD-74878 to track whether this DECODE statement still needs to be in this report
        'Seaward/Tlasta',
        BLOCK.TSO_NAME
    ) || ' (' || BLOCK.TSO_CODE || ')' AS BUSINESS_AREA,
    BLOCK.TSO_CODE AS BUSINESS_AREA_CODE,
    LICENCE.FIELD_TEAM,
    LICENCE.NAV_NAME,
    BLOCK.OPAR_OPERATING_AREA_NAME AS OperatingArea,
    BLOCK.CUTB_LOCATION AS Location,
    LICENCE.TENURE,
    LICENCE.LICENCE_ID,
    LICENCE.LICN_LICENCE_STATE AS Licence_State,
    BLOCK.PERMIT_ID,
    BLOCK.BLOCK_ID,
    BLOCK.UBI,
    BLOCK.CUTB_BLOCK_STATE AS Block_State,
    CASE WHEN (ACTB.Old_Growth_Strategy > Nvl(LRCT.LATEST_OGS_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD')))  -- Date: fixed (1900-01-01)
                OR (LDF.LATEST_DEF > Nvl(ACTB.DEF_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD')))  -- Date: fixed (1900-01-01)
        THEN 'Y' ELSE 'N' END AS DEFERRED,
    CASE WHEN ACTB.Old_Growth_Strategy > Nvl(LRCT.LATEST_OGS_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
            THEN 'Deferred-OGS'
        WHEN LDF.LATEST_DEF > Nvl(ACTB.DEF_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
            THEN 'Deferred-Other' ELSE 'No Deferral' END AS INVENTORY_CATEGORY,
    BLOCK.CRUISE_VOL,
    BLOCK.BLAL_RW_VOL AS RW_VOL,
    ACTB_S.RC_Status,
    ACTB.RC_DATE,
    ACTB_S.DR_Status,
    ACTB.DR_DATE,
    Extract(Year From Add_months(ACTB.DR_DATE, 9)) AS DR_Fiscal,
    Ceil(EXTRACT(Month From Add_Months(ACTB.DR_DATE, -3))/3) AS DR_Quarter,
    CASE WHEN Extract(Year From Add_Months(SysDate, 9))
                - Extract(Year From Add_Months(ACTB.DR_DATE, 9)) > 5
        THEN
            'Before ' || To_Char(Add_Months(SysDate, -60-3), 'YY') || '/' || To_Char(Add_Months(SysDate, -60+9), 'YY')
        ELSE
            To_Char(Add_Months(ACTB.DR_DATE, -3), 'YY') || '/' || To_Char(Add_Months(ACTB.DR_DATE, 9), 'YY')
        End AS DR_Category,
    ACTB_S.DVS_Status,
    ACTB.DVS_DATE,
    ACTB_S.DVC_Status,
    ACTB.DVC_DATE,
    Extract(Year From Add_months(ACTB.DVS_DATE, 9)) AS DVS_Fiscal,
    Ceil(EXTRACT(Month From Add_Months(ACTB.DVS_DATE, -3))/3) AS DVS_Quarter,
    ACTB_S.DEF_Change_of_Op_Plan_Status,
    ACTB.DEF_Change_of_Op_Plan,
    ACTB_S.DEF_First_Nations_Status,
    ACTB.DEF_First_Nations,
    ACTB_S.DEF_Loss_of_Access_Status,
    ACTB.DEF_Loss_of_Access,
    ACTB_S.DEF_Other_Status,
    ACTB.DEF_Other,
    ACTB_S.DEF_Planning_Constraint_Status,
    ACTB.DEF_Planning_Constraint,
    ACTB_S.DEF_Returned_to_BCTS_Status,
    ACTB.DEF_Returned_to_BCTS,
    ACTB_S.DEF_Stale_dated_Fieldwork_Status,
    ACTB.DEF_Stale_dated_Fieldwork,
    ACTB_S.DEF_Stakeholder_Issue_Status,
    ACTB.DEF_Stakeholder_Issue,
    ACTB_S.DEF_Environmental_Stewardship_Initiative_Status,
    ACTB.DEF_Environmental_Stewardship_Initiative,
    ACTB_S.DEF_REACTIVATED_Status,
    ACTB.DEF_REACTIVATED,
    ACTB_S.Old_Growth_Strategy_Status,
    ACTB.Old_Growth_Strategy,
    ACTB_S.OGS_Reactivated_Forest_Health_Status,
    ACTB.OGS_Reactivated_Forest_Health,
    ACTB_S.OGS_Reactivated_FN_Proceed_Status,
    ACTB.OGS_Reactivated_FN_Proceed,
    ACTB_S.OGS_Reactivated_Field_Verified_Status,
    ACTB.OGS_Reactivated_Field_Verified,
    ACTB_S.OGS_Reactivated_Minor_Status,
    ACTB.OGS_Reactivated_Minor,
    ACTB_S.OGS_Reactivated_Road_Status,
    ACTB.OGS_Reactivated_Road,
    ACTB_S.OGS_Reactivated_Re_Engineered_Status,
    ACTB.OGS_Reactivated_Re_Engineered,
    BS.SPATIAL_FLAG,
    BLOCK.CUTB_SEQ_NBR

FROM
    FORESTVIEW.V_BLOCK BLOCK,
    FORESTVIEW.V_BLOCK_SPATIAL BS,
    FORESTVIEW.V_LICENCE LICENCE,
    (
        Select *
        From
            (
                SELECT
                    a.cutb_seq_nbr,
                    atype.actt_key_ind,
                    a.acti_status_date
                FROM
                    forest.activity_class ac,
                    forest.activity_type atype,
                    forest.activity a
                WHERE
                    ac.accl_seq_nbr = atype.accl_seq_nbr
                    AND ac.divi_div_nbr = atype.divi_div_nbr
                    AND atype.actt_seq_nbr =  a.actt_seq_nbr
                    AND (
                        (
                            atype.actt_key_ind In (
                                'DSC', 'DVC', 'DVS', 'FG', 'HVC', 'HVS', 'RC', 'DR', 'WO'
                            )
                            AND ac.accl_key_ind = 'CMB'
                        ) OR (
                            atype.actt_key_ind IN (
                                'DEL', 	-- Deletion Approval
                                'DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI',
                                'DESI', 'DRD', 'RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE'
                            ) AND ac.accl_key_ind = 'CSB'
                        )
                    )
            AND a.plan_seq_nbr Is Null
        ) Pivot (
            Max(acti_status_date)
            FOR ACTT_KEY_IND In (
                'DEL' AS DEL_DATE,
                'DSC' AS DSC_DATE,
                'DVC' AS DVC_DATE,
                'DVS' AS DVS_DATE,
                'FG' AS FG_DATE,
                'HVC' AS HVC_DATE,
                'HVS' AS HVS_DATE,
                'RC' AS RC_DATE,
                'DR' AS DR_DATE,
                'WO' As WOFF_DATE,
                'DCP' AS DEF_Change_of_Op_Plan,
                'DFN' AS DEF_First_Nations,
                'DLA' AS DEF_Loss_of_Access,
                'DOR' AS DEF_Other,
                'DPC' AS DEF_Planning_Constraint,
                'DRB' AS DEF_Returned_to_BCTS,
                'DSD' AS DEF_Stale_dated_Fieldwork,
                'DSI' As DEF_Stakeholder_Issue,
                'DESI' AS DEF_Environmental_Stewardship_Initiative,
                'DRD' AS DEF_REACTIVATED,
                'DOG' AS Old_Growth_Strategy,
                'RFH' AS OGS_Reactivated_Forest_Health,
                'RFN' AS OGS_Reactivated_FN_Proceed,
                'RFV' AS OGS_Reactivated_Field_Verified,
                'RMN' AS OGS_Reactivated_Minor,
                'RRD' AS OGS_Reactivated_Road,
                'RRE' AS OGS_Reactivated_Re_Engineered)
        )
    ) ACTB,
    (
        Select *
        From
            (
                SELECT
                    a.cutb_seq_nbr,
                    atype.actt_key_ind,
                    a.acti_status_ind
                FROM
                    forest.activity_class ac,
                    forest.activity_type atype,
                    forest.activity a
                WHERE
                    ac.accl_seq_nbr = atype.accl_seq_nbr
                    AND ac.divi_div_nbr = atype.divi_div_nbr
                    AND atype.actt_seq_nbr =  a.actt_seq_nbr
                    AND (
                        (
                            atype.actt_key_ind In ('DSC', 'DVC', 'DVS', 'FG', 'HVC', 'HVS', 'RC', 'DR', 'WO')
                            AND ac.accl_key_ind = 'CMB'
                        ) OR (
                            atype.actt_key_ind IN (
                                'DEL', 	-- Deletion Approval
                                'DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI',
                                'DESI', 'DRD', 'RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE'
                            ) AND ac.accl_key_ind = 'CSB'
                        )
                    )
                    AND a.plan_seq_nbr Is Null
            ) Pivot (
                Max(acti_status_ind)
                FOR ACTT_KEY_IND In (
                    'DEL' AS DEL_Status,
                    'DSC' AS DSC_Status,
                    'DVC' AS DVC_Status,
                    'DVS' AS DVS_Status,
                    'FG' AS FG_Met_Status,
                    'HVC' AS HVC_Status,
                    'HVS' AS HVS_Status,
                    'RC' AS RC_Status,
                    'DR' AS DR_Status,
                    'WO' As WOFF_Status,
                    'DCP' AS DEF_Change_of_Op_Plan_Status,
                    'DFN' AS DEF_First_Nations_Status,
                    'DLA' AS DEF_Loss_of_Access_Status,
                    'DOR' AS DEF_Other_Status,
                    'DPC' AS DEF_Planning_Constraint_Status,
                    'DRB' AS DEF_Returned_to_BCTS_Status,
                    'DSD' AS DEF_Stale_dated_Fieldwork_Status,
                    'DSI' As DEF_Stakeholder_Issue_Status,
                    'DESI' As DEF_Environmental_Stewardship_Initiative_Status,
                    'DRD' AS DEF_REACTIVATED_Status,
                    'DOG' AS Old_Growth_Strategy_Status,
                    'RFH' AS OGS_Reactivated_Forest_Health_Status,
                    'RFN' AS OGS_Reactivated_FN_Proceed_Status,
                    'RFV' AS OGS_Reactivated_Field_Verified_Status,
                    'RMN' AS OGS_Reactivated_Minor_Status,
                    'RRD' AS OGS_Reactivated_Road_Status,
                    'RRE' AS OGS_Reactivated_Re_Engineered_Status)
            )
    ) ACTB_S,
    (
        /* Excluding DOG */
        SELECT
            A2.CUTB_SEQ_NBR,
            Max(A2.ACTIVITY_DATE) AS LATEST_DEF
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A2
        WHERE
            A2.ACTIVITY_CLASS='CSB'
            AND A2.ACTT_KEY_IND In ('DCP', 'DFN', 'DLA', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI')
            AND A2.ACTI_STATUS_IND='D'
            AND A2.ACTIVITY_DATE <= To_Date('2023-11-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            A2.CUTB_SEQ_NBR
    ) LDF,
    (
        /* Excluding DRD */
        SELECT DISTINCT
            A4.CUTB_SEQ_NBR,
            MAX(A4.ACTIVITY_DATE) AS LATEST_OGS_REACTIVATED
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A4
        WHERE
            A4.ACTIVITY_CLASS='CSB'
            AND A4.ACTT_KEY_IND IN ('RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE')
            AND A4.ACTI_STATUS_IND='D'
            AND A4.ACTIVITY_DATE <= To_Date('2023-11-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY A4.CUTB_SEQ_NBR,
            A4.ACTI_STATUS_IND
    ) LRCT,
    (
        SELECT DISTINCT
            LICN_SEQ_NBR
        FROM
            FORESTVIEW.V_LICENCE_ACTIVITY_ALL
        WHERE
            (
                ACTIVITY_CLASS='CML'
                AND ACTT_KEY_IND In ('HI', 'HC', 'HX', 'HS')
                AND ACTI_STATUS_IND='D'
            )
        ORDER BY LICN_SEQ_NBR
    ) EXL

WHERE
    BLOCK.CUTB_SEQ_NBR = ACTB.CUTB_SEQ_NBR
    AND BLOCK.CUTB_SEQ_NBR = ACTB_S.CUTB_SEQ_NBR
    AND BLOCK.CUTB_SEQ_NBR = LDF.CUTB_SEQ_NBR (+)
    AND BLOCK.CUTB_SEQ_NBR = LRCT.CUTB_SEQ_NBR (+)
    AND BLOCK.CUTB_SEQ_NBR = BS.CUTB_SEQ_NBR (+)
    AND BLOCK.LICN_SEQ_NBR = LICENCE.LICN_SEQ_NBR (+)
    AND LICENCE.LICN_SEQ_NBR=EXL.LICN_SEQ_NBR (+)
    AND ACTB_S.DR_STATUS = 'D'
    AND ACTB.DR_DATE <= To_Date('2023-11-30', 'YYYY-MM-DD')  -- Date: end of reporting period
    AND (NVL(ACTB_S.DVC_STATUS, ' ') <> 'D')
    AND (NVL(ACTB_S.DVS_STATUS, ' ') <> 'D')
    AND (NVL(ACTB_S.DEL_STATUS, ' ') <> 'D')
    AND (NVL(ACTB_S.WOFF_Status, ' ') <> 'D')
    AND EXL.LICN_SEQ_NBR Is Null

ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    LICENCE.FIELD_TEAM,
    LICENCE.NAV_NAME,
    LICENCE.LICENCE_ID,
    BLOCK.PERMIT_ID,
    BLOCK.BLOCK_ID
;
