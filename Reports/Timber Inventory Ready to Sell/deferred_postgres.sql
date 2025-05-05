WITH DF AS
 /* Deferral Block Activity and Date */
    (
        SELECT
            DA1.CUTB_SEQ_NBR,
            DA1.ACTIVITY_TYPE AS DEFERRED_ACTIVITY,
            DA1.ACTIVITY_DATE AS DEFERRED_ACTIVITY_DATE
        FROM
            LRM_REPLICATION.V_BLOCK_ACTIVITY_ALL DA1
        WHERE
            DA1.ACTI_STATUS_IND='D' AND
            DA1.ACTIVITY_CLASS='CSB' AND
            DA1.ACTT_KEY_IND In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI') AND
            DA1.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
    ),

    /* Latest Deferral Activity Date */
    LDF AS
    (
        SELECT
            DA2.CUTB_SEQ_NBR,
            Max(DA2.ACTIVITY_DATE) AS Latest_Deferral_Date
        FROM
            LRM_REPLICATION.V_BLOCK_ACTIVITY_ALL DA2
        WHERE
            DA2.ACTI_STATUS_IND='D' AND
            DA2.ACTIVITY_CLASS='CSB' AND
            DA2.ACTT_KEY_IND In ('DCP', 'DFN', 'DLA', 'DOG', 'DOR', 'DPC', 'DRB', 'DSD', 'DSI', 'DESI') AND
            DA2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            DA2.CUTB_SEQ_NBR
    ),

    /* Latest Reactivation Activity Date */
    LRCT AS
    (
        SELECT
            DA3.CUTB_SEQ_NBR,
            Max(DA3.ACTIVITY_DATE) AS Latest_Reactivated_Date
        FROM
            LRM_REPLICATION.V_BLOCK_ACTIVITY_ALL DA3
        WHERE
            DA3.ACTI_STATUS_IND='D' AND
            DA3.ACTIVITY_CLASS='CSB' AND
            DA3.ACTT_KEY_IND In ('DRD', 'RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE') AND
            DA3.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
        GROUP BY
            DA3.CUTB_SEQ_NBR
    ),

    /* Block Activity Date (A_D) */
    A_D AS
    (
        SELECT 
            cutb_seq_nbr,
            MAX(CASE WHEN actt_key_ind = 'DVC' THEN activity_date END) AS DVC_Date,
            MAX(CASE WHEN actt_key_ind = 'DVS' THEN activity_date END) AS DVS_Date,
            MAX(CASE WHEN actt_key_ind = 'RC' THEN activity_date END) AS RC_Date,
            MAX(CASE WHEN actt_key_ind = 'DR' THEN activity_date END) AS DR_Date,
            MAX(CASE WHEN actt_key_ind = 'WO' THEN activity_date END) AS Write_Off_Date
        FROM 
            lrm_replication.v_block_activity_all
        WHERE 
            activity_class = 'CMB'
            AND actt_key_ind IN ('DVC', 'DVS', 'RC', 'DR', 'WO')
            AND acti_status_ind = 'D'
            AND activity_date <= '2025-03-31'  -- Date: end of reporting period
        GROUP BY 
            cutb_seq_nbr
    ),

    /* Block Activity Status (A_S) */
    A_S AS
    (
        SELECT 
            cutb_seq_nbr,
            MAX(CASE WHEN actt_key_ind = 'DRD' THEN acti_status_ind END) AS Reactivated_Status,
            MAX(CASE WHEN actt_key_ind = 'DVC' THEN acti_status_ind END) AS DVC_Status,
            MAX(CASE WHEN actt_key_ind = 'DVS' THEN acti_status_ind END) AS DVS_Status,
            MAX(CASE WHEN actt_key_ind = 'RC' THEN acti_status_ind END) AS RC_Status,
            MAX(CASE WHEN actt_key_ind = 'DR' THEN acti_status_ind END) AS DR_Status,
            MAX(CASE WHEN actt_key_ind = 'WO' THEN acti_status_ind END) AS Write_Off_Status
        FROM 
            lrm_replication.v_block_activity_all
        WHERE 
            (
                (activity_class = 'CMB' AND actt_key_ind IN ('DVC', 'DVS', 'RC', 'DR', 'WO')) OR 
                (activity_class = 'CSB' AND actt_key_ind = 'DRD')
            ) 
            AND activity_date <= '2025-03-31'  -- Date: end of reporting period
        GROUP BY 
            cutb_seq_nbr

    ),

    /* Harvest Licence Issued (HI) */
    HI AS
    (
        SELECT
            LA2.LICN_SEQ_NBR
        FROM
            LRM_REPLICATION.V_LICENCE_ACTIVITY_ALL LA2
        WHERE
            LA2.ACTIVITY_CLASS='CML'
            AND LA2.ACTT_KEY_IND='HI'
            AND LA2.ACTIVITY_DATE <= To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of reporting period
            AND LA2.ACTI_STATUS_IND='D'
    ) 

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
	(CASE 
		WHEN B.TSO_NAME = 'Seaward' THEN 'Seaward-Tlasta' 
		ELSE B.TSO_NAME 
	END) || ' (' || B.TSO_CODE || ')' AS BUSINESS_AREA,
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
    EXTRACT(YEAR FROM A_D.RC_Date + INTERVAL '9 months') AS RC_Fiscal,
    'Q' || CEIL(EXTRACT(MONTH FROM A_D.RC_Date - INTERVAL '3 months') / 3.0) AS RC_Quarter,
    A_D.DR_Date,
    EXTRACT(YEAR FROM A_D.DR_Date + INTERVAL '9 months') AS DR_Fiscal,
    'Q' || CEIL(EXTRACT(MONTH FROM A_D.DR_Date - INTERVAL '3 months') / 3.0) AS DR_Quarter,
    A_D.DVS_Date,
    A_S.DVS_Status,
    A_D.DVC_Date,
    EXTRACT(YEAR FROM A_D.DVC_Date + INTERVAL '9 months') AS DVC_Fiscal,
	'Q' || CEIL(EXTRACT(MONTH FROM A_D.DVC_Date - INTERVAL '3 months') / 3.0) AS DVC_Quarter,
    DF.DEFERRED_ACTIVITY,
    DF.DEFERRED_ACTIVITY_DATE,
    LDF.Latest_Deferral_Date,
    LRCT.Latest_Reactivated_Date,
    BS.SPATIAL_FLAG,
    B.CUTB_SEQ_NBR

FROM
    LRM_REPLICATION.V_BLOCK B
    INNER JOIN DF
    ON B.CUTB_SEQ_NBR=DF.CUTB_SEQ_NBR
    INNER JOIN LDF
    ON B.CUTB_SEQ_NBR=LDF.CUTB_SEQ_NBR
    INNER JOIN A_D
    ON B.CUTB_SEQ_NBR=A_D.CUTB_SEQ_NBR
    LEFT JOIN LRCT
    ON  B.CUTB_SEQ_NBR=LRCT.CUTB_SEQ_NBR
    LEFT JOIN A_S
    ON B.CUTB_SEQ_NBR=A_S.CUTB_SEQ_NBR
    LEFT JOIN LRM_REPLICATION.V_BLOCK_SPATIAL BS
    ON B.CUTB_SEQ_NBR=BS.CUTB_SEQ_NBR
    LEFT JOIN LRM_REPLICATION.V_LICENCE L
    ON B.LICN_SEQ_NBR = L.LICN_SEQ_NBR
    LEFT JOIN HI
    ON L.LICN_SEQ_NBR=HI.LICN_SEQ_NBR


WHERE COALESCE(L.TENURE,' ') <> 'B07'
    AND A_D.RC_Date Is Not Null
    AND A_D.DR_Date Is Not Null
    AND A_D.DVC_Date Is Not Null
    AND LDF.Latest_Deferral_Date >= A_D.DVC_Date
    AND LDF.Latest_Deferral_Date > COALESCE(LRCT.Latest_Reactivated_Date, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
    AND A_D.Write_Off_Date Is Null
    AND HI.LICN_SEQ_NBR Is Null

ORDER BY
    business_area_region,
    business_area,
    L.FIELD_TEAM,
    L.NAV_NAME,
    L.LICENCE_ID,
    B.PERMIT_ID,
    B.BLOCK_ID
;
