select distinct
    case
        when
            ou.org_unit_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            ou.org_unit_code in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as Business_Area_Region_Category,
    case
        when
            ou.org_unit_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            ou.org_unit_code in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            ou.org_unit_code in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as Business_Area_Region,
    replace(
        decode(
            ou.org_unit_name,
            'Seaward Timber Sales Office',
            'Seaward-Tlasta',
            ou.org_unit_name
        ) || ' (' || ou.org_unit_code || ')',
        ' Timber Sales Office',
        ''
    ) as Business_Area,
    ou.org_unit_code as Business_Area_Code,
    ts.forest_file_id,
    decode(
        ts.BCTS_CATEGORY_CODE,
        null,
        ts.BCTS_CATEGORY_CODE,
        c.DESCRIPTION || ' (' || ts.BCTS_CATEGORY_CODE || ')'
    ) AS BCTS_Category,
    ts.auction_date,
    ts.sale_volume,
    bid_info.client_count,
    bid_info.eligible_client_count,
    bid_info.ineligible_client_count,
    bid_info.client_count_eligibility_indicator_missing,
    ts.no_sale_rationale_code,
    decode(
        tfsc.tenure_file_status_code, null, pfu.file_status_st, tfsc.description || ' (' || pfu.file_status_st || ')') as fta_file_status,
    pfu.file_status_date as fta_file_status_date,
    tt.legal_effective_dt as fta_legal_effective_date

FROM
    bcts_timber_sale ts,
    BCTS_CATEGORY_CODE c,
    prov_forest_use pfu,
    tenure_term tt,
    org_unit ou,
    (
        select
            forest_file_id,
            auction_date,
            count(
                client_number
            ) as client_count,
            count(
                case
                    when
                    upper(ineligible_ind) = 'N'
                then
                    client_number
                end
            ) as eligible_client_count,
            count(
                case
                    when
                        upper(ineligible_ind) = 'Y'
                    then
                        client_number
                    end
            ) as ineligible_client_count,
            count(
                case
                    when
                        ineligible_ind is null
                    then
                        client_number
                    end
            ) as client_count_eligibility_indicator_missing
            FROM
                bcts_tenure_bidder
            WHERE
                auction_date
                    BETWEEN To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
                    AND To_Date('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
            GROUP BY
                forest_file_id,
                auction_date
    ) bid_info,
    tenure_file_status_code tfsc

WHERE
    ts.auction_date
        BETWEEN To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
        AND To_Date('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
    AND ts.forest_file_id = bid_info.forest_file_id (+)
    AND ts.BCTS_CATEGORY_CODE = c.BCTS_CATEGORY_CODE (+)
    AND ts.auction_date = bid_info.auction_date (+)
    AND ts.forest_file_id = pfu.forest_file_id
    AND ts.no_sale_rationale_code Is Null  -- Only look at successful auctions
    AND pfu.bcts_org_unit = ou.org_unit_no
    AND pfu.forest_file_id = tt.forest_file_id (+)
    AND pfu.file_status_st = tfsc.tenure_file_status_code (+)
    AND not (
        pfu.file_status_st IN ('HI', 'HC', 'LC', 'HX', 'HS', 'HRS')  -- FTA categories associated with issued licences
        AND tt.legal_effective_dt <= To_Date('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
    )

ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    ts.forest_file_id,
    ts.auction_date
;