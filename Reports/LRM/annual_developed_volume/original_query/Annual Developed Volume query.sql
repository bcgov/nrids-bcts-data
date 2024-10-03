select distinct
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
    D.DIVI_SHORT_CODE as BUSINESS_AREA_CODE,
    cl.COLU_LOOKUP_DESC AS "Field Team",
    mu.MANU_ID,
    l.LICN_LICENCE_ID AS LICENCE, tn.TENT_TENURE_ID AS "File Type",
    l.BLAZ_ADMIN_ZONE_ID AS Agreement_Type_Code,
    z.BLAZ_ADMIN_ZONE_DESC AS Agreement_Type,
    cp.PERM_PERMIT_ID AS PERMIT,
    m.MARK_MARK_ID AS MARK,
    b.CUTB_BLOCK_ID AS BLOCK,
    b.CUTB_SYSTEM_ID AS UBI,
    b.cutb_block_state AS block_state,
    ba.BLAL_CRUISE_M3_VOL AS cruise_volume,
    ba.BLAL_RW_VOL AS rw_volume,
    actb.RC_Done,
    Extract(Year From Add_months(actb.RC_Done, 9)) as RC_Done_Fiscal,
    actb.DR_Done,
    Extract(Year From Add_months(actb.DR_Done, 9)) as DR_Done_Fiscal,
    actb.DVS_DONE,
    Extract(Year From Add_months(actb.DVS_DONE, 9)) as DVS_Done_Fiscal,
    actb.DVC_DONE,
    Extract(Year From Add_months(actb.DVC_DONE, 9)) as DVC_Done_Fiscal,
    b.CUTB_SEQ_NBR
FROM
    FOREST.DIVISION d,
    FOREST.BLOCK_ALLOCATION ba,
    FOREST.MANAGEMENT_UNIT mu,
    FOREST.LICENCE l,
    FOREST.BLOCK_ADMIN_ZONE z,
    FOREST.DIVISION_CODE_LOOKUP dcl,
    FOREST.CODE_LOOKUP cl,
    FOREST.TENURE_TYPE tn,
    FOREST.CUT_PERMIT cp,
    FOREST.MARK m,
    FOREST.CUT_BLOCK b,
    (
        SELECT *
        FROM
            (
                SELECT
                    A.CUTB_SEQ_NBR,
                    T.ACTT_KEY_IND,
                    A.ACTI_STATUS_DATE
            FROM
                FOREST.ACTIVITY_CLASS C,
                FOREST.ACTIVITY_TYPE T,
                FOREST.ACTIVITY A
            WHERE
                C.ACCL_SEQ_NBR = T.ACCL_SEQ_NBR
                AND T.ACTT_SEQ_NBR = A.ACTT_SEQ_NBR
                AND C.ACCL_DESCRIPTION = 'CMB'
                AND T.ACTT_KEY_IND In ('RC', 'DR', 'DVS', 'DVC')
                AND A.ACTI_STATUS_IND = 'D'
            )
            Pivot(
                Max(Trunc(ACTI_STATUS_DATE))
                FOR ACTT_KEY_IND In (
                    'RC' AS RC_Done,
                    'DR' AS DR_Done,
                    'DVS' AS DVS_Done,
                    'DVC' AS DVC_Done)
                )
    ) ACTB
WHERE
    d.DIVI_DIV_NBR = ba.DIVI_DIV_NBR
    AND ba.MANU_SEQ_NBR = mu.MANU_SEQ_NBR
    AND ba.LICN_SEQ_NBR = l.LICN_SEQ_NBR
    AND l.DIVI_DIV_NBR = z.DIVI_DIV_NBR (+)
    AND l.BLAZ_ADMIN_ZONE_ID = z.BLAZ_ADMIN_ZONE_ID (+)
    AND l.LICN_FIELD_TEAM_ID = dcl.COLU_LOOKUP_ID (+)
    AND l.DIVI_DIV_NBR = dcl.DIVI_DIV_NBR (+)
    AND dcl.COLU_LOOKUP_TYPE = cl.COLU_LOOKUP_TYPE (+)
    AND dcl.COLU_LOOKUP_ID = cl.COLU_LOOKUP_ID (+)
    AND l.TENT_SEQ_NBR = tn.TENT_SEQ_NBR (+)
    AND ba.PERM_SEQ_NBR = cp.PERM_SEQ_NBR (+)
    AND ba.MARK_SEQ_NBR = m.MARK_SEQ_NBR (+)
    AND ba.CUTB_SEQ_NBR = b.CUTB_SEQ_NBR
    AND ba.CUTB_SEQ_NBR = actb.CUTB_SEQ_NBR
    AND actb.DVC_DONE
        BETWEEN TO_DATE('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
        AND TO_DATE('2024-09-30', 'YYYY-MM-DD')  -- Date: end of reporting period


ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    cl.COLU_LOOKUP_DESC,
    mu.MANU_ID,
    l.LICN_LICENCE_ID,
    cp.PERM_PERMIT_ID,
    m.MARK_MARK_ID,
    b.CUTB_BLOCK_ID
;