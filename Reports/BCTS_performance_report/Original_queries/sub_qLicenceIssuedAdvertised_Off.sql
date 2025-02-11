/* qLicenceIssuedAdvertised_Official */

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
    decode(
        ou.org_unit_code,
        null,
        null,
        replace(
            decode(
                ou.org_unit_name,
                'Seaward Timber Sales Office',
                'Seaward-Tlasta',
                ou.org_unit_name
            ) || ' (' || ou.org_unit_code || ')',
            ' Timber Sales Office',
            ''
        )
    ) as Business_Area,
    ou.org_unit_code as Business_Area_Code,
    ts.forest_file_id,
    /*
    Date for report axis:
    Legal effective date for issued licences,
    auction date for unsuccessful auctions.
    */
    decode(
        issued.issued_licence_legal_effective_date,
        null,
        advertised.last_auction_date,
        issued.issued_licence_legal_effective_date
    ) as x_axis_date,
    decode(
        issued.Issued_Licence_Legal_Effective_Fiscal,
        null,
        advertised.Last_Auction_Fiscal,
        issued.Issued_Licence_Legal_Effective_Fiscal
    ) as x_axis_fiscal,
    decode(
        issued.Issued_Licence_Legal_Effective_Quarter,
        null,
        advertised.Last_Auction_Quarter,
        issued.Issued_Licence_Legal_Effective_Quarter
    ) as x_axis_quarter,

    pfu.file_type_code,
    advertised.auction_count_all_time_to_report_period_end,
    advertised.first_auction_date,
    advertised.First_Auction_Fiscal,
    advertised.First_Auction_Quarter,
    advertised.first_bcts_category_code,
    advertised.first_auction_volume,
    advertised.first_auction_category_A_and_1_volume,
    advertised.first_auction_category_2_and_4_volume,
    case
        when
            advertised.first_auction_date
                between to_date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of report period
                and to_date('2024-09-30', 'YYYY-MM-DD')  -- Date: end of report period
        then
            advertised.first_auction_volume
        end as first_auction_volume_is_in_report_period,
    case
        when
            advertised.first_auction_date
                between to_date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of report period
                and to_date('2024-09-30', 'YYYY-MM-DD')  -- Date: end of report period
        then
            advertised.first_auction_category_A_and_1_volume
        end as first_auction_category_A_and_1_volume_is_in_report_period,
    case
        when
            advertised.first_auction_date
                between to_date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of report period
                and to_date('2024-09-30', 'YYYY-MM-DD')  -- Date: end of report period
        then
            advertised.first_auction_category_2_and_4_volume
        end as first_auction_category_2_and_4_volume_is_in_report_period,
    advertised.last_auction_date,
    advertised.Last_Auction_Fiscal,
    advertised.Last_Auction_Quarter,
    advertised.last_auction_bcts_category_code,
    advertised.last_auction_volume,
    advertised.last_auction_category_A_and_1_volume,
    advertised.last_auction_category_2_and_4_volume,
    advertised.original_cat_2_and_4_readvertised_cat_A_and_1_volume,
    advertised.original_cat_A_and_1_readvertised_cat_2_and_4_volume,
    advertised.last_auction_no_sale_rationale,
    advertised.Last_Auction_No_Sale_Volume,
    advertised.last_auction_no_sale_category_A_1_volume,
    advertised.last_auction_no_sale_category_2_4_volume,
    decode(
        advertised.last_auction_no_sale_rationale,
        null,
        null,
        'Y'
    ) as Last_Auction_No_Sale,
    decode(
        advertised.last_auction_no_sale_rationale,
        null,
        null,
        decode(
            advertised.last_auction_no_sale_category_A_1_volume,
            null,
            null,
            'Y'
        )
    ) as Last_Auction_No_Sale_Cat_A,
    decode(
        advertised.last_auction_no_sale_rationale,
        null,
        null,
        decode(
            advertised.last_auction_no_sale_category_2_4_volume,
            null,
            null,
            'Y'
        )
    ) as Last_Auction_No_Sale_Cat_2_4,
    issued.issued_licence_legal_effective_date,
    issued.Issued_Licence_Legal_Effective_Fiscal,
    issued.Issued_Licence_Legal_Effective_Quarter,
    issued.issued_licence_bcts_category_code,
    issued.issued_licence_volume,
    issued.category_A_and_1_issued_volume,
    issued.category_2_and_4_issued_volume,
    issued.issued_licence_maximum_value,
    case
        when
            issued.issued_licence_bcts_category_code in ('A')
        then
            issued.issued_licence_maximum_value
        end as issued_licence_maximum_value_Cat_A,
    case
        when
            issued.issued_licence_bcts_category_code in ('2', '4')
        then
            issued.issued_licence_maximum_value
        end as issued_licence_maximum_value_Cat_2_4,
    issued.issued_licence_client_number,
    issued.issued_licence_client_name,
    decode(
        issued.forest_file_id,
        null,
        null,
        'Y'
    ) as Issued_in_Report_Period,
    decode(
        issued.forest_file_id,
        null,
        null,
        decode(
            issued.category_A_and_1_issued_volume,
            null,
            null,
            'Y'
        )
    ) as Issued_in_Report_Period_Cat_A,
    decode(
        issued.forest_file_id,
        null,
        null,
        decode(
            issued.category_2_and_4_issued_volume,
            null,
            null,
            'Y'
        )
    ) as Issued_in_Report_Period_Cat_2_4,
    decode(
        advertised_in_report_period.forest_file_id,
        null,
        null,
        'Y'
    ) as Advertised_in_Report_Period,
    case
        when
            tfsc.description is not NULL
        THEN
            tfsc.description || ' (' || pfu.file_status_st || ')'
        else
            pfu.file_status_st
        end as FTA_File_Status,
    pfu.file_status_date as FTA_File_Status_Date

FROM
    the.tenure_term tt,
    the.bcts_timber_sale ts,
    the.prov_forest_use pfu,
    the.tenure_file_status_code tfsc,
    the.org_unit ou,

    /* Issued Licence Details (Licences issued within reporting period) */
    (
        select
            ts0.forest_file_id,
            tt.legal_effective_dt as issued_licence_legal_effective_date,
            decode(
                tt.legal_effective_dt,
                null,
                null,
                'Fiscal '
                || to_number(extract(
                    year from(add_months(tt.legal_effective_dt, 9))
                ) - 1)
                || '/'
                || extract(
                    year from(add_months(tt.legal_effective_dt, 9))
                )
            ) as Issued_Licence_Legal_Effective_Fiscal,
            decode(
                tt.legal_effective_dt,
                null,
                null,
                'Q' || Ceil((EXTRACT(Month From Add_Months(tt.legal_effective_dt, -3)))/3)
            ) AS Issued_Licence_Legal_Effective_Quarter,
            ts0.auction_date,
            ts0.bcts_category_code as issued_licence_bcts_category_code,
            ts0.sale_volume as issued_licence_volume,
            case
                when
                    ts0.bcts_category_code in ('2', '4')
                then
                    ts0.sale_volume
                end as category_2_and_4_issued_volume,
            case
                when
                    ts0.bcts_category_code in ('A', '1')
                then
                    ts0.sale_volume
                end as category_A_and_1_issued_volume,
            ts0.total_upset_value as cruise_total_upset_value,
            ts0.UPSET_RATE as scale_upset_rate,
            tb.bonus_bid AS issued_licence_bonus_bid,
            tb.bonus_offer AS issued_licence_bonus_offer,
            case
                when
                    ts0.TOTAL_UPSET_VALUE > 0
                then
                        round(
                            ts0.TOTAL_UPSET_VALUE + tb.bonus_offer,  -- Cruise-based licence pricing
                            2
                        )
                else
                        round(
                            (ts0.UPSET_RATE + tb.BONUS_BID) * ts0.sale_volume,  -- Scale-based licence pricing
                            2
                        )
                end as issued_licence_maximum_value,
            tb.client_number as issued_licence_client_number,
            (
                decode(fc.legal_first_name, null, null, fc.legal_first_name || ' ')
                || decode(fc.legal_middle_name, null, null, fc.legal_middle_name || ' ')
                || fc.client_name
            ) as issued_licence_client_name

        from
            the.bcts_timber_sale ts0,
            the.bcts_tenure_bidder tb,
            the.prov_forest_use pfu,
            the.tenure_term tt,
            the.v_client_public fc

        where
            pfu.forest_file_id = ts0.forest_file_id
            and pfu.forest_file_id = tt.forest_file_id
            and ts0.forest_file_id = tb.forest_file_id
            and ts0.auction_date = tb.auction_date
            and tb.client_number = fc.client_number
            and upper(tb.sale_awarded_ind) = 'Y'  -- Only look at the winning bid
            and ts0.no_sale_rationale_code is null

            AND pfu.file_status_st IN (
                'HI',  -- Issued
                'HC',  -- Closed
                'LC',  -- Logging Complete
                'HX',  -- Cancelled
                'HS',  -- Suspended
                'HRS'  -- Harvesting Rights Surrendered
            )

            /* Tenure term legal effective date in reporting period*/
            AND tt.legal_effective_dt
                between To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and To_Date('2024-09-30', 'YYYY-MM-DD')  -- Date: end of reporting period
    ) issued,

    /* Advertised Licence Details */
    (
        select
            ts.forest_file_id,
            all_auctions_to_date.first_auction_date,
            decode(
                all_auctions_to_date.first_auction_date,
                null,
                null,
                'Fiscal '
                || to_number(extract(
                    year from(add_months(all_auctions_to_date.first_auction_date, 9))
                ) - 1)
                || '/'
                || extract(
                    year from(add_months(all_auctions_to_date.first_auction_date, 9))
                )
            ) as First_Auction_Fiscal,
            decode(
                all_auctions_to_date.first_auction_date,
                null,
                null,
                'Q' || Ceil((EXTRACT(Month From Add_Months(all_auctions_to_date.first_auction_date, -3)))/3)
            ) AS First_Auction_Quarter,
            all_auctions_to_date.last_auction_date,
            decode(
                all_auctions_to_date.last_auction_date,
                null,
                null,
                'Fiscal '
                || to_number(extract(
                    year from(add_months(all_auctions_to_date.last_auction_date, 9))
                ) - 1)
                || '/'
                || extract(
                    year from(add_months(all_auctions_to_date.last_auction_date, 9))
                )
            ) as Last_Auction_Fiscal,
            decode(
                all_auctions_to_date.last_auction_date,
                null,
                null,
                'Q' || Ceil((EXTRACT(Month From Add_Months(all_auctions_to_date.last_auction_date, -3)))/3)
            ) AS Last_Auction_Quarter,
            all_auctions_to_date.auction_count_all_time_to_report_period_end,
            first_auction.bcts_category_code as first_bcts_category_code,
            ts.bcts_category_code as last_auction_bcts_category_code,
            decode(
                first_auction.bcts_category_code,
                ts.bcts_category_code,
                'No category change',
                'Category change'
            ) as category_change,
            decode(
                nsrc.description,
                null,
                ts.no_sale_rationale_code,
                nsrc.description || ' (' || ts.no_sale_rationale_code || ')'
            ) as last_auction_no_sale_rationale,
            to_number(decode(
                ts.no_sale_rationale_code,
                null,
                null,
                ts.sale_volume
            )) as Last_Auction_No_Sale_Volume,
            case
                when
                    ts.no_sale_rationale_code is not null
                    and ts.bcts_category_code in ('2', '4')
                then
                    ts.sale_volume
                end as last_auction_no_sale_category_2_4_volume,
            case
                when
                    ts.no_sale_rationale_code is not null
                    and ts.bcts_category_code in ('A', '1')
                then
                    ts.sale_volume
                end as last_auction_no_sale_category_A_1_volume,
            first_auction.sale_volume as first_auction_volume,
            ts.sale_volume as last_auction_volume,
            case
                when
                    first_auction.bcts_category_code in ('2', '4')
                then
                    first_auction.sale_volume
                end as first_auction_category_2_and_4_volume,
            case
                when
                    first_auction.bcts_category_code in ('A', '1')
                then
                    first_auction.sale_volume
                end as first_auction_category_A_and_1_volume,
            case
                when
                    ts.bcts_category_code in ('2', '4')
                then
                    ts.sale_volume
                end as last_auction_category_2_and_4_volume,
            case
                when
                    ts.bcts_category_code in ('A', '1')
                then
                    ts.sale_volume
                end as last_auction_category_A_and_1_volume,
            case
                when
                    first_auction.bcts_category_code in ('2', '4')
                    and ts.bcts_category_code in ('A', '1')
                then
                    ts.sale_volume
                end as original_cat_2_and_4_readvertised_cat_A_and_1_volume,
            case
                when
                    first_auction.bcts_category_code in ('A', '1')
                    and ts.bcts_category_code in ('2', '4')
                then
                    ts.sale_volume
                end as original_cat_A_and_1_readvertised_cat_2_and_4_volume
        from
            the.bcts_timber_sale ts,
            the.no_sale_rationale_code nsrc,
            (
                select
                    ts.forest_file_id,
                    count(ts.auction_date) as auction_count_all_time_to_report_period_end,
                    min(ts.auction_date) as first_auction_date,
                    max(ts.auction_date) as last_auction_date
                from
                    the.bcts_timber_sale ts
                where
                    Nvl(no_sale_rationale_code, ' ') <> 'TB'
                    and ts.auction_date <= To_Date('2024-09-30', 'YYYY-MM-DD')  -- Date: end of reporting period
                group by
                    ts.forest_file_id
            ) all_auctions_to_date,
            (
                select
                    forest_file_id,
                    auction_date,
                    bcts_category_code,
                    sale_volume
                from
                    the.bcts_timber_sale ts
            ) first_auction
        where
            ts.no_sale_rationale_code = nsrc.no_sale_rationale_code (+)
            and ts.forest_file_id = all_auctions_to_date.forest_file_id
            and ts.auction_date = all_auctions_to_date.last_auction_date
            and ts.forest_file_id = first_auction.forest_file_id
            and all_auctions_to_date.first_auction_date = first_auction.auction_date
    ) advertised,

    /* Advertised in report period */
    (
        select distinct
            forest_file_id
        from
            the.bcts_timber_sale
        where
            auction_date
                between to_date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and to_date('2024-09-30', 'YYYY-MM-DD')  -- Date: end of reporting period
    ) advertised_in_report_period


WHERE
    pfu.bcts_org_unit = ou.org_unit_no
    and pfu.forest_file_id = ts.forest_file_id (+)
    and pfu.forest_file_id = tt.forest_file_id (+)
    AND pfu.file_status_st = tfsc.tenure_file_status_code (+)
    AND ts.forest_file_id = issued.forest_file_id (+)
    and ts.forest_file_id = advertised.forest_file_id (+)
    and ts.forest_file_id = advertised_in_report_period.forest_file_id (+)
    and ts.forest_file_id is not null
    and (
        /* Criteria for Licences Issued in reporting period*/
        issued.forest_file_id is not null
        /* Criteria for auctions within the reporting period */
        or advertised_in_report_period.forest_file_id is not null
    )

union select
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
    decode(
        ou.org_unit_code,
        null,
        null,
        replace(
            decode(
                ou.org_unit_name,
                'Seaward Timber Sales Office',
                'Seaward-Tlasta',
                ou.org_unit_name
            ) || ' (' || ou.org_unit_code || ')',
            ' Timber Sales Office',
            ''
        )
    ) as Business_Area,
    ou.org_unit_code as Business_Area_Code,
    null as forest_file_id,
    null as x_axis_date,
    null as x_axis_fiscal,
    null as x_axis_quarter,
    null as file_type_code,
    null as auction_count_all_time_to_report_period_end,
    null as first_auction_date,
    null as First_Auction_Fiscal,
    null as First_Auction_Quarter,
    null as first_bcts_category_code,
    null as first_auction_volume,
    null as first_auction_category_A_and_1_volume,
    null as first_auction_category_2_and_4_volume,
    null as first_auction_volume_is_in_report_period,
    null as first_auction_category_A_and_1_volume_is_in_report_period,
    null as first_auction_category_2_and_4_volume_is_in_report_period,
    null as last_auction_date,
    null as Last_Auction_Fiscal,
    null as Last_Auction_Quarter,
    null as last_auction_bcts_category_code,
    null as last_auction_volume,
    null as last_auction_category_A_and_1_volume,
    null as last_auction_category_2_and_4_volume,
    null as original_cat_2_and_4_readvertised_cat_A_and_1_volume,
    null as original_cat_A_and_1_readvertised_cat_2_and_4_volume,
    null as last_auction_no_sale_rationale,
    null as Last_Auction_No_Sale_Volume,
    null as last_auction_no_sale_category_A_1_volume,
    null as last_auction_no_sale_category_2_4_volume,
    null as Last_Auction_No_Sale,
    null as Last_Auction_No_Sale_Cat_A,
    null as Last_Auction_No_Sale_Cat_2_4,
    null as issued_licence_legal_effective_date,
    null as Issued_Licence_Legal_Effective_Fiscal,
    null as Issued_Licence_Legal_Effective_Quarter,
    null as issued_licence_bcts_category_code,
    null as issued_licence_volume,
    null as category_A_and_1_issued_volume,
    null as category_2_and_4_issued_volume,
    null as issued_licence_maximum_value,
    null as issued_licence_maximum_value_cat_a,
    null as issued_licence_maximum_value_cat_2_4,
    null as issued_licence_client_number,
    null as issued_licence_client_name,
    null as Issued_in_Report_Period,
    null as Issued_in_Report_Period_Cat_A,
    null as Issued_in_Report_Period_Cat_2_4,
    null as Advertised_in_Report_Period,
    null as FTA_File_Status,
    null as FTA_File_Status_Date

    from
        org_unit ou

    where
        /* BCTS Business Area org unit numbers in the org_unit table */
        ou.org_unit_no in (
            1808,
            1812,
            1816,
            1813,
            1815,
            1814,
            1810,
            1811,
            1817,
            1807,
            1809,
            1818
        )

ORDER BY
    business_area_region_category desc,
    business_area_region,
    business_area,
    x_axis_fiscal desc,  -- list empty business area rows before rows with licences for each business area
    forest_file_id
;
