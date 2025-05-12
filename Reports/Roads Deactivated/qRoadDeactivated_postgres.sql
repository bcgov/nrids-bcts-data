Select
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
    (CASE 
			WHEN divi_division_name = 'Seaward' THEN 'Seaward-Tlasta' 
			ELSE divi_division_name 
	END) || ' (' || TSO_CODE || ')' AS BUSINESS_AREA,
    TSO_CODE as BUSINESS_AREA_CODE,
    FIELD_TEAM_DESC,
    ROAD_SEQ_NBR,
    ROAD_ROAD_NAME,
    URI,
    Min(POC) AS POC,
    Max(POT) AS POT,
    (Max(POT) - Min(POC)) / 1000 AS LENGTH,
    RCLS_ACCOUNTING_TYPE,
    RDST_STEWARD_NAME,
    DEAC_END_DATE,
    DEAC_LEVEL_TYPE,
    DEAC_METHOD_TYPE
From
    (
        SELECT
            a.DIVI_DIVISION_NAME,
            a.TSO_CODE,
            a.FIELD_TEAM_DESC,
            a.ROAD_SEQ_NBR, a.ROAD_ROAD_NAME, a.URI,
            a.POC,
            a.POT,
            Lead(a.POC, 1) Over (
                PARTITION BY
                    a.ROAD_SEQ_NBR
                ORDER BY
                    a.ROAD_SEQ_NBR,
                    a.POC
            ) AS POC_Next,
            Lag(a.POT, 1) Over (
                PARTITION BY
                    a.ROAD_SEQ_NBR
                ORDER BY
                    a.ROAD_SEQ_NBR,
                    a.POC
            ) AS POT_Prev,
            a.RCLS_ACCOUNTING_TYPE,
            RDST_STEWARD_NAME,
            DATE_TRUNC('DAY', a.DEAC_END_DATE) AS DEAC_END_DATE,
            a.DEAC_LEVEL_TYPE,
            a.DEAC_METHOD_TYPE
        FROM
            LRM_REPLICATION.V_ROAD_GAP_ANALYSIS a
        WHERE
            URI Is Not NULL
            AND a.RDST_STEWARD_NAME IN ('BCTS', 'former BCTS')
            AND a.RCLS_ACCOUNTING_TYPE In (
                '1 Sale = 5 yrs',
                'S.Term = 10 yrs',
                'Perm = 40 yrs'
            )
            AND a.DEAC_END_DATE
                BETWEEN To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of report period (usually start of current fiscal)
                AND To_Date('2025-03-31', 'YYYY-MM-DD')  -- Date: end of report period
    --        AND UPPER(a.DEAC_LEVEL_TYPE) = 'PERMANENT'
            AND a.DEAC_METHOD_TYPE IN ('DEACT', 'REHAB')
        ORDER BY
            a.ROAD_SEQ_NBR,
            a.POC
    ) RGA
 
Group By
    DIVI_DIVISION_NAME,
    TSO_CODE,
    FIELD_TEAM_DESC,
    ROAD_SEQ_NBR, ROAD_ROAD_NAME, URI,
    RCLS_ACCOUNTING_TYPE, RDST_STEWARD_NAME,
    DEAC_END_DATE,
    DEAC_LEVEL_TYPE,
    DEAC_METHOD_TYPE,
	Case
        When
            POC_Next Is Null
            And POT_PREV Is Null
        Then
            'N'
		When
            POT < POC_Next
        Then
            'Before'
		When
            POC > POT_Prev
        Then
            'After'
		When
            POC = POC_Next Or POC = POT_PREV
			Or POT = POC_NEXT Or POT = POT_PREV
        Then
            'Y'
		Else
            'G'
	End
 
order by
    BUSINESS_AREA_REGION_CATEGORY desc,
    BUSINESS_AREA_REGION,
    BUSINESS_AREA,
    FIELD_TEAM_DESC,
    ROAD_ROAD_NAME,
    POC,
    POT
;