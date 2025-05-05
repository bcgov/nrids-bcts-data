SELECT DISTINCT
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
    case
        when
            B.TSO_CODE is not null
        then
            decode(
                B.TSO_NAME,
                'Seaward',
                'Seaward-Tlasta',
                B.TSO_NAME
            )
            || ' ('
            || B.TSO_CODE
            || ')'
        end as BUSINESS_AREA,
    B.TSO_CODE as BUSINESS_AREA_CODE,
    L.FIELD_TEAM,
    L.NAV_NAME,
    B.OPAR_OPERATING_AREA_NAME AS OperatingArea,
    B.CUTB_LOCATION AS Location,
    L.TENURE,
    L.LICENCE_ID,
    L.LICN_LICENCE_STATE AS Licence_State,
    B.PERMIT_ID,
    B.BLOCK_ID,
    B.CUTB_BLOCK_STATE AS Block_State,
    B.UBI,
    B.CRUISE_VOL,
    B.BLAL_RW_VOL AS RW_VOL,
    A_D.RC_DONE,
    Extract(Year From Add_Months(A_D.RC_DONE, 9)) AS RC_Fiscal,
    Ceil(EXTRACT(Month From Add_Months(A_D.RC_DONE, -3))/3) AS RC_Quarter,
    A_D.DR_DONE,
    Extract(Year From Add_Months(A_D.DR_DONE, 9)) AS DR_Fiscal,
    Ceil(EXTRACT(Month From Add_Months(A_D.DR_DONE, -3))/3) AS DR_Quarter,
    A_D.DVC_DONE,
    Extract(Year From Add_Months(A_D.DVC_DONE, 9)) AS DVC_Fiscal,
    Ceil(EXTRACT(Month From Add_Months(A_D.DVC_DONE, -3))/3) AS DVC_Quarter,
    A_DFD.Change_of_Op_Plan_Date,
    A_DFS.Change_of_Op_Plan_Status,
    A_DFD.First_Nations_Date,
    A_DFS.First_Nations_Status,
    A_DFD.Loss_of_Access_Date,
    A_DFS.Loss_of_Access_Status,
    A_DFD.Old_Growth_Strategy_Date,
    A_DFS.Old_Growth_Strategy_Status,
    A_DFD.Other_Date,
    A_DFS.Other_Status,
    A_DFD.Planning_Constraint_Date,
    A_DFS.Planning_Constraint_Status,
    A_DFD.Returned_to_BCTS_Date,
    A_DFS.Returned_to_BCTS_Status,
    A_DFD.Stale_dated_Fieldwork_Date,
    A_DFS.Stale_dated_Fieldwork_Status,
    A_DFD.Stakeholder_Issue_Date,
    A_DFS.Stakeholder_Issue_Status,
    A_DFD.Environmental_Stewardship_Initiative_Date,
    A_DFS.Environmental_Stewardship_Initiative_Status,
    A_D.Reactivated_Done,
    BS.SPATIAL_FLAG,
    B.CUTB_SEQ_NBR

FROM
    FORESTVIEW.V_BLOCK B,
    FORESTVIEW.V_BLOCK_SPATIAL BS,
    FORESTVIEW.V_LICENCE L,

    /* Block Activity Date (A_D)*/
    (
        Select *
        From
        (
            SELECT
                A0.cutb_seq_nbr,
                A0.ACTT_KEY_IND,
                A0.ACTIVITY_DATE
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A0
        WHERE
            (
                (
                    A0.ACTIVITY_CLASS = 'CMB'
                    AND A0.actt_key_ind In ('RC', 'DR', 'DVC', 'WO')
                ) OR (
                    A0.ACTIVITY_CLASS = 'CSB'
                    AND A0.actt_key_ind = 'DRD'
                )
            ) AND A0.ACTI_STATUS_IND='D'
            AND A0.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
        Pivot
        (
            Max(ACTIVITY_DATE)
            FOR ACTT_KEY_IND In (
                'RC' AS RC_DONE,
                'DR' AS DR_DONE,
                'DVC' AS DVC_DONE,
                'WO' As WOFF_DONE,
                'DRD' AS REACTIVATED_DONE
            )
        )
    ) A_D,

    /* Latest Deferral Date */
    (
        SELECT
            A1.CUTB_SEQ_NBR,
            Max(A1.ACTIVITY_DATE) AS Latest_Deferral_Date
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A1
        WHERE
            A1.ACTIVITY_CLASS='CSB'
            AND A1.ACTT_KEY_IND In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI')
            AND A1.ACTI_STATUS_IND='D'
            AND A1.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            A1.CUTB_SEQ_NBR
    ) LDF,

    /* Latest Reactivated Date */
    (
        SELECT
            DA3.CUTB_SEQ_NBR,
            Max(DA3.ACTIVITY_DATE) AS Latest_Reactivated_Date
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL DA3
        WHERE
            DA3.ACTI_STATUS_IND='D'
            AND DA3.ACTIVITY_CLASS='CSB'
            AND DA3.ACTT_KEY_IND In ('DRD', 'RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE')
            AND DA3.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            DA3.CUTB_SEQ_NBR
    ) LRCT,

    /* Block Deferral Activity Date */
    (
        Select *
        From
            (
                SELECT
                    A2.cutb_seq_nbr,
                    A2.ACTT_KEY_IND,
                    A2.ACTIVITY_DATE
                FROM
                    FORESTVIEW.V_BLOCK_ACTIVITY_ALL A2
                WHERE
                    A2.actt_key_ind In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI')
                    AND A2.ACTIVITY_CLASS = 'CSB'
                    AND A2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            )
        Pivot
        (
            Max(ACTIVITY_DATE)
            FOR ACTT_KEY_IND In (
                'DCP' AS Change_of_Op_Plan_Date,
                'DFN' AS First_Nations_Date,
                'DLA' AS Loss_of_Access_Date,
                'DOG' AS Old_Growth_Strategy_Date,
                'DOR' AS Other_Date,
                'DPC' AS Planning_Constraint_Date,
                'DRB' AS Returned_to_BCTS_Date,
                'DSD' AS Stale_dated_Fieldwork_Date,
                'DSI' As Stakeholder_Issue_Date,
                'DESI' As Environmental_Stewardship_Initiative_Date
            )
        )
    ) A_DFD,

    /* Block Deferral Activity Status */
    (
        Select *
        From
        (
            SELECT
                A3.cutb_seq_nbr,
                A3.ACTT_KEY_IND,
                A3.ACTI_STATUS_IND
            FROM
                FORESTVIEW.V_BLOCK_ACTIVITY_ALL A3
            WHERE
                A3.actt_key_ind In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI')
                AND A3.ACTIVITY_CLASS = 'CSB'
                AND A3.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
        Pivot
        (
            Max(ACTI_STATUS_IND)
            FOR ACTT_KEY_IND In (
                'DCP' AS Change_of_Op_Plan_Status,
                'DFN' AS First_Nations_Status,
                'DLA' AS Loss_of_Access_Status,
                'DOG' AS Old_Growth_Strategy_Status,
                'DOR' AS Other_Status,
                'DPC' AS Planning_Constraint_Status,
                'DRB' AS Returned_to_BCTS_Status,
                'DSD' AS Stale_dated_Fieldwork_Status,
                'DSI' As Stakeholder_Issue_Status,
                'DESI' As Environmental_Stewardship_Initiative_Status
            )
        )
    ) A_DFS,

    /* Harvest Licence Issued (HI) */
    (
        SELECT
            LICN_SEQ_NBR
        FROM
            FORESTVIEW.V_LICENCE_ACTIVITY_ALL
        WHERE
            ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            AND ACTIVITY_CLASS = 'CML'
            AND ACTT_KEY_IND = 'HI'
            AND ACTI_STATUS_IND = 'D'
    ) HI

WHERE
    B.CUTB_SEQ_NBR = A_D.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR = LDF.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR = LRCT.CUTB_SEQ_NBR (+)
    AND B.CUTB_SEQ_NBR = A_DFD.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR = A_DFS.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR = BS.CUTB_SEQ_NBR (+)
    AND B.LICN_SEQ_NBR = L.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR = HI.LICN_SEQ_NBR (+)
    AND Nvl(L.TENURE,'') <> 'B07'
    AND A_D.RC_DONE Is Not Null
    AND A_D.DR_DONE Is Not Null
    AND A_D.DVC_DONE Is Not Null
    AND LDF.Latest_Deferral_Date >= A_D.DVC_DONE
    AND LDF.Latest_Deferral_Date > Nvl(A_D.Reactivated_Done,To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
    AND HI.LICN_SEQ_NBR Is Null
    AND A_D.WOFF_DONE Is Null

ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    L.FIELD_TEAM,
    L.NAV_NAME,
    L.LICENCE_ID,
    B.PERMIT_ID,
    B.BLOCK_ID
;

SELECT DISTINCT
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
    case
        when
            B.TSO_CODE is not null
        then
            decode(
                B.TSO_NAME,
                'Seaward',
                'Seaward-Tlasta',
                B.TSO_NAME
            )
            || ' ('
            || B.TSO_CODE
            || ')'
        end as BUSINESS_AREA,
    B.TSO_CODE as BUSINESS_AREA_CODE,
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
    B.CRUISE_VOL,
    B.BLAL_RW_VOL AS RW_VOL,
    A_D.RC_Date,
    Extract(Year From Add_Months(A_D.RC_Date, 9)) AS RC_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(A_D.RC_Date, -3)))/3) AS RC_Quarter,
    A_D.DR_Date,
    Extract(Year From Add_Months(A_D.DR_Date, 9)) AS DR_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(A_D.DR_Date, -3)))/3) AS DR_Quarter,
    A_D.DVS_Date,
    A_S.DVS_Status,
    A_D.DVC_Date,
    Extract(Year From Add_Months(A_D.DVC_Date, 9)) AS DVC_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(A_D.DVC_Date, -3)))/3) AS DVC_Quarter,
    DF.DEFERRED_ACTIVITY,
    DF.DEFERRED_ACTIVITY_DATE,
    LDF.Latest_Deferral_Date,
    LRCT.Latest_Reactivated_Date,
    BS.SPATIAL_FLAG,
    B.CUTB_SEQ_NBR

FROM
    FORESTVIEW.V_BLOCK B,
    FORESTVIEW.V_BLOCK_SPATIAL BS,
    FORESTVIEW.V_LICENCE L,

    /* Deferral Block Activity and Date */
    (
        SELECT
            DA1.CUTB_SEQ_NBR,
            DA1.ACTIVITY_TYPE AS DEFERRED_ACTIVITY,
            DA1.ACTIVITY_DATE AS DEFERRED_ACTIVITY_DATE
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL DA1
        WHERE
            DA1.ACTI_STATUS_IND='D' AND
            DA1.ACTIVITY_CLASS='CSB' AND
            DA1.ACTT_KEY_IND In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI') AND
            DA1.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
    ) DF,

    /* Latest Deferral Activity Date */
    (
        SELECT
            DA2.CUTB_SEQ_NBR,
            Max(DA2.ACTIVITY_DATE) AS Latest_Deferral_Date
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL DA2
        WHERE
            DA2.ACTI_STATUS_IND='D' AND
            DA2.ACTIVITY_CLASS='CSB' AND
            DA2.ACTT_KEY_IND In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI') AND
            DA2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            DA2.CUTB_SEQ_NBR
    ) LDF,

    /* Latest Reactivation Activity Date */
    (
        SELECT
            DA3.CUTB_SEQ_NBR,
            Max(DA3.ACTIVITY_DATE) AS Latest_Reactivated_Date
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL DA3
        WHERE
            DA3.ACTI_STATUS_IND='D' AND
            DA3.ACTIVITY_CLASS='CSB' AND
            DA3.ACTT_KEY_IND In ('DRD', 'RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE') AND
            DA3.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            DA3.CUTB_SEQ_NBR
    ) LRCT,

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
                    A0.ACTIVITY_CLASS = 'CMB'
                    AND A0.ACTT_KEY_IND In ('DVC', 'DVS', 'RC', 'DR', 'WO')
                    AND A0.ACTI_STATUS_IND = 'D'
                    AND A0.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            ) Pivot (
                Max(ACTIVITY_DATE)
                FOR ACTT_KEY_IND In (
                    'DVC' AS DVC_Date,
                    'DVS' AS DVS_Date,
                    'RC' As RC_Date,
                    'DR' As DR_Date,
                    'WO' AS Write_Off_Date)
            )
    ) A_D,

    /* Block Activity Status (A_S) */
    (
        Select *
        From
            (
                SELECT
                    A1.CUTB_SEQ_NBR,
                    A1.ACTT_KEY_IND,
                    A1.ACTI_STATUS_IND
                FROM
                    FORESTVIEW.V_BLOCK_ACTIVITY_ALL A1
                WHERE
                    (
                        (
                            A1.ACTIVITY_CLASS = 'CMB'
                            AND A1.ACTT_KEY_IND In ('DVC', 'DVS', 'RC', 'DR', 'WO')
                        ) OR (
                            A1.ACTIVITY_CLASS='CSB'
                            AND A1.ACTT_KEY_IND='DRD'
                        )
                    ) AND A1.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            ) Pivot (
                Max(ACTI_STATUS_IND)
                FOR ACTT_KEY_IND In (
                    'DRD' AS Reactivated_Status,
                    'DVC' AS DVC_Status,
                    'DVS' AS DVS_Status,
                    'RC' As RC_Status,
                    'DR' As DR_Status,
                    'WO' AS Write_Off_Status
                )
            )
    ) A_S,

    /* Harvest Licence Issued (HI) */
    (
        SELECT
            LA2.LICN_SEQ_NBR
        FROM
            FORESTVIEW.V_LICENCE_ACTIVITY_ALL LA2
        WHERE
            LA2.ACTIVITY_CLASS='CML'
            AND LA2.ACTT_KEY_IND='HI'
            AND LA2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            AND LA2.ACTI_STATUS_IND='D'
    ) HI

WHERE
    B.CUTB_SEQ_NBR=DF.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR=LDF.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR=LRCT.CUTB_SEQ_NBR (+)
    AND B.CUTB_SEQ_NBR=A_D.CUTB_SEQ_NBR
    AND B.CUTB_SEQ_NBR=A_S.CUTB_SEQ_NBR (+)
    AND B.CUTB_SEQ_NBR=BS.CUTB_SEQ_NBR (+)
    AND B.LICN_SEQ_NBR = L.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR=HI.LICN_SEQ_NBR (+)
    AND Nvl(L.TENURE,' ') <> 'B07'
    AND A_D.RC_Date Is Not Null
    AND A_D.DR_Date Is Not Null
    AND A_D.DVC_Date Is Not Null
    AND LDF.Latest_Deferral_Date >= A_D.DVC_Date
    AND LDF.Latest_Deferral_Date > Nvl(LRCT.Latest_Reactivated_Date, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
    AND A_D.Write_Off_Date Is Null
    AND HI.LICN_SEQ_NBR Is Null

ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    L.FIELD_TEAM,
    L.NAV_NAME,
    L.LICENCE_ID,
    B.PERMIT_ID,
    B.BLOCK_ID
;
