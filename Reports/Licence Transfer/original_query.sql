SELECT DISTINCT
    CASE
        WHEN ou.org_unit_code IN ('TBA', 'TPL', 'TPG', 'TSK', 'TSN') THEN 'North Interior'
        WHEN ou.org_unit_code IN ('TCC', 'TKA', 'TKO', 'TOC') THEN 'South Interior'
        WHEN ou.org_unit_code IN ('TCH', 'TST', 'TSG') THEN 'Coast'
    END AS Business_Area_Region,
    replace(
        decode (
            ou.org_unit_name,
            'Seaward Timber Sales Office',
            'Seaward/Tlasta',
            ou.org_unit_name
        ) | | ' (' | | ou.org_unit_code | | ')',
        ' Timber Sales Office',
        ''
    ) AS Business_Area,
    decode (
        mutc.description,
        NULL,
        pfu.MGMT_UNIT_TYPE,
        mutc.description | | ' (' | | pfu.MGMT_UNIT_TYPE | | ')'
    ) AS Management_Unit_Type,
    pfu.mgmt_unit_id AS Management_Unit_ID,
    decode (
        pfu.mgmt_unit_type,
        'U',
        ta.DESCRIPTION,
        tf.DESCRIPTION
    ) AS Management_Unit,
    ts.forest_file_id,
    ts.BCTS_CATEGORY_CODE,
    c.DESCRIPTION AS Category,
    ts.auction_date,
    ts.sale_volume,
    tfsc.description | | ' (' | | pfu.file_status_st | | ')' AS FTA_File_Status,
    tt.legal_effective_dt AS legal_effective_date,
    CL.CLIENT_NUMBER,
    (
        decode (
            cl.legal_first_name,
            NULL,
            NULL,
            cl.legal_first_name | | ' '
        ) | | decode (
            cl.legal_middle_name,
            NULL,
            NULL,
            cl.legal_middle_name | | ' '
        ) | | cl.client_name
    ) AS CLIENT_NAME,
    decode (
        fctc.description,
        NULL,
        CL.FOREST_FILE_CLIENT_TYPE_CODE,
        fctc.description | | ' (' | | cl.forest_file_client_type_code | | ')'
    ) AS client_type,
    CL.REGISTRY_COMPANY_TYPE_CODE,
    CL.LICENSEE_START_DATE,
    CL.LICENSEE_END_DATE,
    CL.REVISION_COUNT,
    rank() OVER (
        PARTITION BY
            ts.forest_file_id
        ORDER BY
            CL.LICENSEE_START_DATE
    ) AS licensee_order
FROM
    bcts_timber_sale ts,
    BCTS_CATEGORY_CODE c,
    prov_forest_use pfu,
    tenure_file_status_code tfsc,
    file_client_type_code fctc,
    mgmt_unit_type_code mutc,
    org_unit ou,
    tenure_term tt,
    tsa_number_code ta,
    tfl_number_code tf,
    (
        SELECT
            ff.FOREST_FILE_ID,
            ff.CLIENT_NUMBER,
            ff.LICENSEE_START_DATE,
            ff.LICENSEE_END_DATE,
            ff.REVISION_COUNT,
            fc.legal_first_name,
            fc.legal_middle_name,
            fc.CLIENT_NAME,
            ff.FOREST_FILE_CLIENT_TYPE_CODE,
            FC.CLIENT_ACRONYM,
            fc.REGISTRY_COMPANY_TYPE_CODE
        FROM
            THE.FOREST_FILE_CLIENT ff,
            THE.FOREST_CLIENT FC
        WHERE
            ff.CLIENT_NUMBER = FC.CLIENT_NUMBER
            AND FC.CLIENT_NAME NOT LIKE ('TIMBER SALES MANAGER%')
    ) CL,
    (
        SELECT
            FF1.FOREST_FILE_ID,
            COUNT(DISTINCT FF1.CLIENT_NUMBER) CLIENT_COUNT
        FROM
            THE.FOREST_FILE_CLIENT FF1,
            THE.FOREST_CLIENT FC1,
            the.tenure_term TT1
        WHERE
            FF1.CLIENT_NUMBER = FC1.CLIENT_NUMBER
            AND ff1.forest_file_id = TT1.forest_file_id
            AND FC1.CLIENT_NAME NOT LIKE ('TIMBER SALES MANAGER%')
            AND FF1.FOREST_FILE_ID IN (
                SELECT
                    FF0.FOREST_FILE_ID
                FROM
                    THE.FOREST_FILE_CLIENT FF0
                WHERE
                    FF0.LICENSEE_START_DATE BETWEEN To_Date ('2024-04-01', 'YYYY-MM-DD') -- Report period start date
AND To_Date  ('2025-03-31', 'YYYY-MM-DD') -- Report period end date
            )
        GROUP BY
            FF1.FOREST_FILE_ID
        HAVING
            COUNT(*) > 1
            AND COUNT(DISTINCT FF1.FOREST_FILE_CLIENT_TYPE_CODE) > 1
            AND max(FF1.licensee_start_date) >= max(TT1.LEGAL_EFFECTIVE_DT) -- Latest licensee start date after licence issuance, indicating the previous licensee was not sold the licence.
    ) CC
WHERE
    ts.forest_file_id = pfu.forest_file_id
    AND ts.forest_file_id = CL.forest_file_id
    AND ts.forest_file_id = CC.forest_file_id
    AND pfu.bcts_org_unit = ou.org_unit_no
    AND pfu.file_status_st = tfsc.tenure_file_status_code (+)
    AND cl.forest_file_client_type_code = fctc.file_client_type_code (+)
    AND pfu.mgmt_unit_type = mgmt_unit_type_code (+)
    AND pfu.mgmt_unit_id = ta.tsa_number (+)
    AND pfu.mgmt_unit_id = tf.tfl_number (+)
    AND pfu.forest_file_id = tt.forest_file_id (+)
    AND pfu.file_status_st IN ('HI', 'HC', 'LC', 'HX', 'HS', 'HRS')
    AND ts.no_sale_rationale_code IS NULL
    AND ts.BCTS_CATEGORY_CODE = c.BCTS_CATEGORY_CODE (+)
ORDER BY
    length (business_area_region) DESC,
    business_area_region,
    business_area,
    ts.forest_file_id,
    CL.LICENSEE_START_DATE DESC;