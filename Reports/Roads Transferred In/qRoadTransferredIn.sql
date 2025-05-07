SELECT DISTINCT
    case
        when
            TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            TSO_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        DIVI_DIVISION_NAME,
        'Seaward',
        'Seaward-Tlasta',
        DIVI_DIVISION_NAME
    ) || ' (' || TSO_CODE || ')' AS BUSINESS_AREA,
    TSO_CODE as BUSINESS_AREA_CODE,
    ROAD_SEQ_NBR, URI,
    ROAD_ROAD_NAME,
	RCLS_ACCOUNTING_TYPE,
    RDST_STEWARD_NAME,
    POC,
    POT,
    ((POT-POC)/1000) AS Length,
    Trunc(RCOM_COMPLETION_DATE) AS TRANSFER_DATE,
    CONST_METHOD_TYPE
FROM
    FORESTVIEW.V_ROAD_GAP_ANALYSIS
WHERE
    upper(CONST_METHOD_TYPE) = 'TRANSFER IN'
    AND URI Is Not NULL
    AND RCLS_ACCOUNTING_TYPE In ('1 Sale = 5 yrs', 'S.Term = 10 yrs', 'Perm = 40 yrs')
    AND RDST_STEWARD_NAME = 'BCTS'
    AND RCOM_COMPLETION_DATE
        BETWEEN To_Date('2024-04-01', 'YYYY-MM-DD')  /* Date: beginning of reporting period (usually beginning of current fiscal) */
        AND To_Date('2025-03-31', 'YYYY-MM-DD')  /* Date: end of reporting period */
ORDER BY
    BUSINESS_AREA_REGION_CATEGORY desc,
    BUSINESS_AREA_REGION,
    BUSINESS_AREA,
    ROAD_ROAD_NAME
;