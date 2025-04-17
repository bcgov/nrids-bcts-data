select distinct
    case
        when
            B.TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            B.TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            B.TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            B.TSO_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            B.TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        B.TSO_NAME,
        'Seaward',
        'Seaward-Tlasta',
        B.TSO_NAME
    ) || ' (' || B.TSO_CODE || ')' AS BUSINESS_AREA,
    B.TSO_CODE AS BUSINESS_AREA_CODE,
    L.FIELD_TEAM,
    L.NAV_NAME,
    B.OPAR_OPERATING_AREA_NAME AS OperatingArea,
    B.CUTB_LOCATION AS Location,
    L.TENURE,
    L.LICENCE_ID,
    L.LICN_LICENCE_STATE AS Licence_State,
    B.PERMIT_ID,
    B.BLOCK_ID,
    B.UBI,
    B.CUTB_BLOCK_STATE AS Block_State,
    CASE
        WHEN
            Extract(Year From Add_Months(SysDate, 9)) - Extract(Year From Add_Months(A_D.DVC_Date, 9)) > 5
        THEN
            'Before ' || To_Char(Add_Months(SysDate, -60-3), 'YY') || '/' || To_Char(Add_Months(SysDate, -60+9), 'YY')
        ELSE
            To_Char(Add_Months(A_D.DVC_Date, -3), 'YY') || '/' || To_Char(Add_Months(A_D.DVC_Date, 9), 'YY')
        End AS DVC_Category,
    CASE
        WHEN
            Extract(Year From Add_Months(SysDate, 9)) - Extract(Year From Add_Months(A_D.DR_Date, 9)) > 5
        THEN
            'Before ' || To_Char(Add_Months(SysDate, -60-3), 'YY') || '/' || To_Char(Add_Months(SysDate, -60+9), 'YY')
        ELSE
            To_Char(Add_Months(A_D.DR_Date, -3), 'YY') || '/' || To_Char(Add_Months(A_D.DR_Date, 9), 'YY')
        End AS DR_Category,
    CASE
        WHEN
            (
                (
                    A_D.Old_Growth_Strategy > Nvl(LRCT.LATEST_OGS_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
                ) OR (
                    LDF.LATEST_DEF > Nvl(A_D.DEF_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
                )
            )
        THEN
            'Y'
        ELSE
            'N'
        END AS DEFERRED_AT_REPORT_DATE,
    CASE
        WHEN
            A_D.Old_Growth_Strategy > Nvl(LRCT.LATEST_OGS_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
        THEN
            'Deferred-OGS'
        WHEN
            LDF.LATEST_DEF > Nvl(A_D.DEF_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
        THEN
            'Deferred-Other'
        ELSE
            'Ready to Sell'
        END AS INVENTORY_CATEGORY,
    BS.SPATIAL_FLAG,
    B.CRUISE_VOL,
    B.BLAL_RW_VOL AS RW_VOL,
    A_D.RC_Date,
    Extract(Year From Add_Months(A_D.RC_Date, 9)) AS RC_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(A_D.RC_Date, -3)))/3) AS RC_Quarter,
    A_D.DR_Date,
    Extract(Year From Add_Months(A_D.DR_Date, 9)) AS DR_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(A_D.DR_Date, -3)))/3) AS DR_Quarter,
    A_D.DVS_Date,
    A_D.DVC_Date,
    Extract(Year From Add_Months(A_D.DVC_Date, 9)) AS DVC_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(A_D.DVC_Date, -3)))/3) AS DVC_Quarter,
    AUC.ACTIVITY_DATE AS AUC_Date,
    AUC.ACTI_STATUS_IND AS AUC_Status,
    A_D.DEF_Change_of_Op_Plan,
    A_D.DEF_First_Nations,
    A_D.DEF_Loss_of_Access,
    A_D.DEF_Other,
    A_D.DEF_Planning_Constraint,
    A_D.DEF_Returned_to_BCTS,
    A_D.DEF_Stale_dated_Fieldwork,
    A_D.DEF_Stakeholder_Issue,
    A_D.DEF_Environmental_Stewardship_Initiative,
    A_D.DEF_REACTIVATED,
    A_D.Old_Growth_Strategy,
    A_D.OGS_Reactivated_Forest_Health,
    A_D.OGS_Reactivated_FN_Proceed,
    A_D.OGS_Reactivated_Field_Verified,
    A_D.OGS_Reactivated_Minor,
    A_D.OGS_Reactivated_Road,
    A_D.OGS_Reactivated_Re_Engineered,
    decode(
        SALVAGE_ANY_FIRE_YEAR.cutb_seq_nbr,
        null,
        'N',
        'Y'
    ) SALVAGE_ANY_FIRE_YEAR,
    SALVAGE_ANY_FIRE_YEAR.salvage_fire_years,
    decode(
        salvage21.actt_key_ind,
        null,
        null,
        salvage21.activity_type || ' (' || salvage21.activity_class || ' - ' || salvage21.actt_key_ind || ')'
    ) as salvage_2021_fire,
    decode(
        salvage22.actt_key_ind,
        null,
        null,
        salvage22.activity_type || ' (' || salvage22.activity_class || ' - ' || salvage22.actt_key_ind || ')'
    ) as salvage_2022_fire,
    decode(
        salvage23.actt_key_ind,
        null,
        null,
        salvage23.activity_type || ' (' || salvage23.activity_class || ' - ' || salvage23.actt_key_ind || ')'
    ) as salvage_2023_fire,
    decode(
        salvage24.actt_key_ind,
        null,
        null,
        salvage24.activity_type || ' (' || salvage24.activity_class || ' - ' || salvage24.actt_key_ind || ')'
    ) as salvage_2024_fire,
    B.CUTB_SEQ_NBR

FROM
    FORESTVIEW.V_BLOCK B,
    FORESTVIEW.V_BLOCK_SPATIAL BS,
    FORESTVIEW.V_LICENCE L,

    /* Block Activity Date (A_D) */
    (
        Select *
        From
            (
                SELECT
                    A0.CUTB_SEQ_NBR,
                    A0.ACTT_KEY_IND,
                    A0.ACTIVITY_DATE
                FROM
                    FORESTVIEW.V_BLOCK_ACTIVITY_ALL A0
                WHERE
                    (
                        (
                            A0.ACTIVITY_CLASS = 'CMB'  -- Corporate Mandatory Block (CMB) activity class
                            AND A0.ACTT_KEY_IND In (
                                'DVC',  -- Development Completed
                                'DVS',  -- Development Started
                                'RC',  -- Referral Complete
                                'DR',  -- Development Ready
                                'WO'  -- Write-off
                            )
                        ) OR (
                            A0.ACTIVITY_CLASS = 'CSB'  -- Corporate Standard Block (CSB) activity class
                            AND A0.ACTT_KEY_IND IN (
                                'DEL',  -- Deletion Approval
                                'DCP',  -- Deferred - Change of Op Plan
                                'DFN',  -- Deferred - First Nations
                                'DLA',  -- Deferred - Loss of Access
                                'DOG',  -- Deferred - Old Growth Strategy
                                'DOR',  -- Deferred - Other
                                'DPC',  -- Deferred - Planning Constraint
                                'DRB',  -- Deferred - Returned to BCTS
                                'DSD',  -- Deferred - Stale-dated Fieldwork
                                'DSI',  -- Deferred - Stakeholder Issue
                                'DESI',  -- Deferred - Environmental Stewardship Initiative
                                'DRD',  -- Deferred - Reactivated(non-OGS)
                                'RFH',  -- Deferred - Reactivated(OGS-Forest Health)
                                'RFN',  -- Deferred - Reactivated(OGS-FN Proceed)
                                'RFV',  -- Deferred - Reactivated(OGS-Field Verified)
                                'RMN',  -- Deferred - Reactivated(OGS-Minor)
                                'RRD',  -- Deferred - Reactivated(OGS-Road)
                                'RRE'  -- Deferred - Reactivated(OGS-Re-Engineered)
                            )
                        )
                    ) AND A0.ACTI_STATUS_IND = 'D'  -- Done (D)
                    AND A0.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            )
        Pivot
            (
                Max(ACTIVITY_DATE)
                FOR ACTT_KEY_IND In (
                    'DEL' AS Deletion_Approval_Date,
                    'DVC' AS DVC_Date,
                    'DVS' AS DVS_Date,
                    'RC' As RC_Date,
                    'DR' AS DR_Date,
                    'WO' AS Write_Off_Date,
                    'DCP' AS DEF_Change_of_Op_Plan,
                    'DFN' AS DEF_First_Nations,
                    'DLA' AS DEF_Loss_of_Access,
                    'DOR' AS DEF_Other,
                    'DPC' AS DEF_Planning_Constraint,
                    'DRB' AS DEF_Returned_to_BCTS,
                    'DSD' AS DEF_Stale_dated_Fieldwork,
                    'DSI' As DEF_Stakeholder_Issue,
                    'DESI' As DEF_Environmental_Stewardship_Initiative,
                    'DRD' AS DEF_REACTIVATED,
                    'DOG' AS Old_Growth_Strategy,
                    'RFH' AS OGS_Reactivated_Forest_Health,
                    'RFN' AS OGS_Reactivated_FN_Proceed,
                    'RFV' AS OGS_Reactivated_Field_Verified,
                    'RMN' AS OGS_Reactivated_Minor,
                    'RRD' AS OGS_Reactivated_Road,
                    'RRE' AS OGS_Reactivated_Re_Engineered)
            )
    ) A_D,

    /* Latest Non-Old-Growth-Strategy Deferral Block Activity (LDF) */
    (
        SELECT
            A2.CUTB_SEQ_NBR,
            Max(A2.ACTIVITY_DATE) AS LATEST_DEF
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A2
        WHERE
            A2.ACTIVITY_CLASS = 'CSB'  -- Corporate Standard Block (CSB) activity class
            AND A2.ACTT_KEY_IND In (
                'DCP',  -- Deferred - Change of Op Plan
                'DFN',  -- Deferred - First Nations
                'DLA',  -- Deferred - Loss of Access
                'DOR',  -- Deferred - Other
                'DPC',  -- Deferred - Planning Constraint
                'DRB',  -- Deferred - Returned to BCTS
                'DSD',  -- Deferred - Stale-dated Fieldwork
                'DSI',  -- Deferred - Stakeholder Issue
                'DESI'  -- Deferred - Environmental Stewardship Initiative
            )
            AND A2.ACTI_STATUS_IND = 'D'  -- Done (D)
            AND A2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period

        GROUP BY
            A2.CUTB_SEQ_NBR
    ) LDF,

    /* Latest Reactivated Block Activity (LRCT) */
    (
        SELECT DISTINCT
            A4.CUTB_SEQ_NBR,
            MAX(A4.ACTIVITY_DATE) AS LATEST_OGS_REACTIVATED
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A4
        WHERE
            A4.ACTIVITY_CLASS = 'CSB'  -- Corporate Standard Block (CSB) activity class
            AND A4.ACTT_KEY_IND IN (
                'RFH',  -- Deferred - Reactivated(OGS-Forest Health)
                'RFN',  -- Deferred - Reactivated(OGS-FN Proceed)
                'RFV',  -- Deferred - Reactivated(OGS-Field Verified)
                'RMN',  -- Deferred - Reactivated(OGS-Minor)
                'RRD',  -- Deferred - Reactivated(OGS-Road)
                'RRE',  -- Deferred - Reactivated(OGS-Re-Engineered)
                'DRD'  -- Deferred - Reactivated(non-OGS)  -- DRD Added on 2025-03-15. BD
            )
            AND A4.ACTI_STATUS_IND = 'D'  -- Done (D)
            AND A4.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            A4.CUTB_SEQ_NBR,
            A4.ACTI_STATUS_IND
    ) LRCT,

    /* Auction Licence Activity (AUC) */
    (
        SELECT
            LA1.LICN_SEQ_NBR,
            LA1.ACTI_TARGET_DATE,
            LA1.ACTIVITY_DATE,
            LA1.ACTI_STATUS_IND
        FROM
            FORESTVIEW.V_LICENCE_ACTIVITY_ALL LA1
        WHERE
            LA1.ACTIVITY_CLASS = 'CML'  -- Corporate Mandatory Licence (CML) activity class
            AND LA1.ACTT_KEY_IND = 'AUC'  -- Auction
    ) AUC,

    /* Harvest Licence Issued (HI) */
    (
        SELECT
            LA2.LICN_SEQ_NBR
        FROM
            FORESTVIEW.V_LICENCE_ACTIVITY_ALL LA2
        WHERE
            LA2.ACTIVITY_CLASS = 'CML'  -- Corporate Mandatory Licence (CML) activity class
            AND LA2.ACTT_KEY_IND = 'HI'  -- Licence Issued
            AND LA2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            AND LA2.ACTI_STATUS_IND = 'D'  -- Done
    ) HI,

    /* Salvage - Any fire year */
    (
        select
            cutb_seq_nbr,
            listagg( distinct
                substr(
                    activity_type,
                    instr(activity_type, '2'),  -- find the first number '2' in the activity description
                    4  -- take the 4 characters starting with the first 2 in the string to find the four-character fire yera
                ),
                ', '
            ) within group (order by actt_key_ind) as salvage_fire_years

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind like 'SFIRE%'

          group by cutb_seq_nbr
    ) SALVAGE_ANY_FIRE_YEAR,

    /* Salvage - 2021 Fire (calendar year of fire) */
    (
        select distinct  -- Staff can enter multiple CSB SFIRE21 activity for a block; use DISTINCT to include the SFIRE21 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE21'
    ) SALVAGE21,

    /* Salvage - 2022 Fire (calendar year of fire) */
    (
        select distinct  -- Stafff can enter multiple CSB SFIRE22 activity for a block; use DISTINCT to include the SFIRE22 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE22'
    ) SALVAGE22,

    /* Salvage - 2023 Fire (calendar year of fire) */
    (
        select distinct   -- Staff can enter multiple CSB SFIRE23 activity for a block; use DISTINCT to include the SFIRE23 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE23'
    ) SALVAGE23,

    /* Salvage - 2024 Fire (calendar year of fire) */
    (
        select distinct   -- Staff can enter multiple CSB SFIRE23 activity for a block; use DISTINCT to include the SFIRE23 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE24'
    ) SALVAGE24

WHERE
    B.CUTB_SEQ_NBR = A_D.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR = LDF.CUTB_SEQ_NBR (+)
    AND B.CUTB_SEQ_NBR = LRCT.CUTB_SEQ_NBR (+)
    AND B.CUTB_SEQ_NBR = BS.CUTB_SEQ_NBR (+)
    AND B.LICN_SEQ_NBR = L.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR = AUC.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR = HI.LICN_SEQ_NBR (+)
    and b.cutb_seq_nbr = SALVAGE_ANY_FIRE_YEAR.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage21.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage22.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage23.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage24.cutb_seq_nbr (+)
    AND Nvl(L.TENURE,' ') <> 'B07'
    AND A_D.RC_Date Is Not Null
    AND A_D.DR_Date Is Not Null
    AND A_D.DVC_Date Is Not Null
    AND A_D.Deletion_Approval_Date Is Null
    AND A_D.Write_Off_Date Is Null
    AND HI.LICN_SEQ_NBR Is Null

ORDER BY
    length(BUSINESS_AREA_REGION) desc,
    BUSINESS_AREA_REGION,
    BUSINESS_AREA,
    L.FIELD_TEAM,
    L.NAV_NAME,
    L.LICENCE_ID,
    B.PERMIT_ID,
    B.BLOCK_ID
;