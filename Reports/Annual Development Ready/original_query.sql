SELECT
    case
        when
            D.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            D.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            D.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            D.DIVI_SHORT_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            D.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        D.DIVI_DIVISION_NAME,
        'Seaward',
        'Seaward-Tlasta',
        D.DIVI_DIVISION_NAME
    ) || ' (' || D.DIVI_SHORT_CODE || ')' AS BUSINESS_AREA,
    D.DIVI_SHORT_CODE AS BUSINESS_AREA_CODE,
    LKF.COLU_LOOKUP_DESC AS FIELD_TEAM,
    MU.MANU_ID,
    L.LICN_LICENCE_ID AS LICENCE,
    TN.TENT_TENURE_ID AS TENURE,
    CP.PERM_PERMIT_ID AS PERM,
    M.MARK_MARK_ID AS MARK,
    CB.CUTB_BLOCK_ID AS BLOCK_ID,
    CB.CUTB_SYSTEM_ID AS UBI,
    CB.CUTB_BLOCK_STATE AS BLOCK_STATE,
    BA.BLAL_CRUISE_M3_VOL AS CRUISE_VOLUME,
    BA.BLAL_RW_VOL AS RW_VOLUME,
    ACTB.DR_STATUS_DATE AS DR_DONE,
    ACTB.RC_STATUS,
    ACTB.RC_STATUS_DATE,
    ACTB.DVS_STATUS,
    ACTB.DVS_STATUS_DATE,
    ACTB.DVC_STATUS,
    ACTB.DVC_STATUS_DATE,
    L.LICN_SEQ_NBR,
    CB.CUTB_SEQ_NBR
FROM
    FOREST.DIVISION D,
    FOREST.BLOCK_ALLOCATION BA,
    FOREST.MANAGEMENT_UNIT MU,
    FOREST.LICENCE L,
    FOREST.TENURE_TYPE TN,
    FOREST.CODE_LOOKUP LKF,
    FOREST.MARK M,
    FOREST.CUT_PERMIT CP,
    FOREST.CUT_BLOCK CB,
    /* Block activity status and date ACTB */
    (
        SELECT
            A.CUTB_SEQ_NBR,
            MAX(DECODE(T.ACTT_KEY_IND, 'DR', A.ACTI_STATUS_IND, NULL)) AS DR_STATUS,
            MAX(DECODE(T.ACTT_KEY_IND, 'DR', TRUNC(A.ACTI_STATUS_DATE), NULL)) AS DR_STATUS_DATE,
            MAX(DECODE(T.ACTT_KEY_IND, 'RC', A.ACTI_STATUS_IND, NULL)) AS RC_STATUS,
            MAX(DECODE(T.ACTT_KEY_IND, 'RC', TRUNC(A.ACTI_STATUS_DATE), NULL)) AS RC_STATUS_DATE,
            MAX(DECODE(T.ACTT_KEY_IND, 'DVS', A.ACTI_STATUS_IND, NULL)) AS DVS_STATUS,
            MAX(DECODE(T.ACTT_KEY_IND, 'DVS', TRUNC(A.ACTI_STATUS_DATE), NULL)) AS DVS_STATUS_DATE,
            MAX(DECODE(T.ACTT_KEY_IND, 'DVC', A.ACTI_STATUS_IND, NULL)) AS DVC_STATUS,
            MAX(DECODE(T.ACTT_KEY_IND, 'DVC', TRUNC(A.ACTI_STATUS_DATE), NULL)) AS DVC_STATUS_DATE
        FROM
            FOREST.ACTIVITY_CLASS C,
            FOREST.ACTIVITY_TYPE T,
            FOREST.ACTIVITY A
        WHERE
            C.ACCL_SEQ_NBR = T.ACCL_SEQ_NBR
            AND T.ACTT_SEQ_NBR = A.ACTT_SEQ_NBR
            AND C.ACCL_DESCRIPTION = 'CMB'
            AND T.ACTT_KEY_IND IN ('RC', 'DR', 'DVS', 'DVC')
        GROUP BY
            A.CUTB_SEQ_NBR
    ) ACTB
WHERE
    D.DIVI_DIV_NBR = BA.DIVI_DIV_NBR
    AND BA.cutb_seq_nbr = ACTB.cutb_seq_nbr
    AND BA.LICN_SEQ_NBR = L.LICN_SEQ_NBR (+)
    AND L.LICN_FIELD_TEAM_ID = LKF.COLU_LOOKUP_ID(+)
    AND LKF.COLU_LOOKUP_TYPE(+) = 'FDTM'  -- Licence Field Team (FDTM)
    AND BA.CUTB_SEQ_NBR = CB.CUTB_SEQ_NBR
    AND L.TENT_SEQ_NBR = TN.TENT_SEQ_NBR(+)
    AND BA.MANU_SEQ_NBR = MU.MANU_SEQ_NBR (+)
    AND BA.MARK_SEQ_NBR = M.MARK_SEQ_NBR (+)
    AND BA.PERM_SEQ_NBR = CP.PERM_SEQ_NBR (+)
    AND ACTB.DR_STATUS = 'D'  -- Development Ready (DR) status is Done (D)
    AND ACTB.DR_STATUS_DATE
        BETWEEN TO_DATE('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
        AND TO_DATE('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    MU.MANU_ID,
    L.LICN_LICENCE_ID,
    M.MARK_MARK_ID,
    CB.CUTB_BLOCK_ID
;
 
 
