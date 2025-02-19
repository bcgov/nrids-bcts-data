/* qLicenceIssuedAdvertised_main */

SELECT
    official.Business_Area_Region_Category,
    official.Business_Area_Region,
    official.Business_Area,
    lrm.Management_Unit,
    lrm.District,
    Official.X_Axis_Date,
    Official.X_Axis_Fiscal,
    Official.X_Axis_Quarter,
    official.forest_file_id AS Licence,
    official.File_Type_Code,
    Official.Auction_Count_All_Time_to_Report_Period_End,
    Official.First_Auction_Date,
    Official.First_Auction_Fiscal,
    Official.First_Auction_Quarter,
    Official.First_BCTS_Category_Code,
    Official.First_Auction_Volume,
    Official.First_Auction_Category_A_and_1_Volume,
    Official.First_Auction_Category_2_and_4_Volume,
    Official.First_Auction_Volume_is_in_Report_Period,
    Official.First_Auction_Category_A_and_1_Volume_is_in_Report_Period,
    Official.First_Auction_Category_2_and_4_Volume_is_in_Report_Period,
    Official.Last_Auction_Date,
    Official.Last_Auction_Fiscal,
    Official.Last_Auction_Quarter,
    Official.Last_Auction_BCTS_Category_Code,
    Official.Last_Auction_Volume,
    Official.Last_Auction_Category_A_and_1_Volume,
    Official.Last_Auction_Category_2_and_4_Volume,
    Official.Original_Cat_2_and_4_Readvertised_Cat_A_and_1_Volume,
    Official.Original_Cat_A_and_1_Readvertised_Cat_2_and_4_Volume,
    Official.Last_Auction_No_Sale_Rationale,
    Official.Last_Auction_No_Sale_Volume,
    Official.Last_Auction_No_Sale_Category_A_1_Volume,
    Official.Last_Auction_No_Sale_Category_2_4_Volume,
    Official.Last_Auction_No_Sale,
    Official.Last_Auction_No_Sale_Cat_A,
    Official.Last_Auction_No_Sale_Cat_2_4,
    Official.Issued_Licence_Legal_Effective_Date,
    Official.Issued_Licence_Legal_Effective_Fiscal,
    Official.Issued_Licence_Legal_Effective_Quarter,
    Official.Issued_Licence_BCTS_Category_Code,
    Official.Issued_Licence_Volume,
    Official.Category_A_and_1_Issued_Volume,
    Official.Category_2_and_4_Issued_Volume,
    Official.Issued_Licence_Maximum_Value,
    Official.Issued_licence_maximum_value_Cat_A,
    Official.Issued_licence_maximum_value_Cat_2_4,
    Official.Issued_Licence_Client_Number,
    Official.Issued_Licence_Client_Name,
    official.Issued_in_Report_Period,
    Official.Issued_in_Report_Period_Cat_A,
    Official.Issued_in_Report_Period_Cat_2_4,
    official.Advertised_in_Report_Period,
    round(lrm.LRM_Total_Volume_Salvage_All_Fire_Years) AS Total_Volume_Salvage_All_Fire_Year_LRM,
    Official.FTA_File_Status,
    Official.FTA_File_Status_Date
FROM
    qLicenceIssuedAdvertised_Official AS official
    LEFT JOIN qLicenceIssuedAdvertised_LRM AS lrm
    ON official.forest_file_id = lrm.licence_id
;


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
                and to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: end of report period
        then
            advertised.first_auction_volume
        end as first_auction_volume_is_in_report_period,
    case
        when
            advertised.first_auction_date
                between to_date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of report period
                and to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: end of report period
        then
            advertised.first_auction_category_A_and_1_volume
        end as first_auction_category_A_and_1_volume_is_in_report_period,
    case
        when
            advertised.first_auction_date
                between to_date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of report period
                and to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: end of report period
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
                and To_Date('2024-08-31', 'YYYY-MM-DD')  -- Date: end of reporting period
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
                    and ts.auction_date <= To_Date('2024-08-31', 'YYYY-MM-DD')  -- Date: end of reporting period
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
                and to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: end of reporting period
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


/* qLicenceIssuedAdvertised_LRM */

select
    licence.business_area_region_category,
    licence.business_area_region,
    licence.business_area,
    licence.licence_id,
    licence.Management_Unit,
    licence.District,
    licence.Category_ID_LRM,
    total_licence_info.LRM_TOTAL_VOLUME,
    total_licence_info.count_all_blocks_in_licence,
    salvage_all_fire_year.LRM_TOTAL_VOLUME_SALVAGE_ALL_FIRE_YEARS,
    salvage_all_fire_year.count_blocks_salvage_any_fire_year,
    salvage21fire.LRM_TOTAL_VOLUME_SALVAGE_2021_FIRE,
    salvage21fire.count_blocks_salvage_21_fire,
    salvage22fire.LRM_TOTAL_VOLUME_SALVAGE_2022_FIRE,
    salvage22fire.count_blocks_salvage_22_fire,
    salvage23fire.LRM_TOTAL_VOLUME_SALVAGE_2023_FIRE,
    salvage23fire.count_blocks_salvage_23_fire,
    salvage24fire.LRM_TOTAL_VOLUME_SALVAGE_2024_FIRE,
    salvage24fire.count_blocks_salvage_24_fire,
    salvage25fire.LRM_TOTAL_VOLUME_SALVAGE_2025_FIRE,
    salvage25fire.count_blocks_salvage_25_fire,
    licence.licn_seq_nbr

from
    /* Licence Info */
    (
        select
            licn_seq_nbr,
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
                TSO_NAME,
                'Seaward',
                'Seaward-Tlasta',
                TSO_NAME
            ) || ' (' || TSO_CODE || ')' AS BUSINESS_AREA,
            Licence_ID,
            nav_name as Management_Unit,
            District_Name as District,
            Licn_Category_ID as Category_ID_LRM,
            Category as Category_LRM
        from
            forestview.v_licence
    ) licence,

    /* Total Licence Info -- Info about all blocks in licence */
    (
        select
            B.LICN_SEQ_NBR,
            count(*) as count_all_blocks_in_licence,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME
        from
            FORESTVIEW.V_BLOCK B
        group by
            b.licn_seq_nbr
    ) total_licence_info,

    /*
    salvage_all_fire_year

    Volume of blocks within licence that have any SFIRE## activities.
    If a block has multiple salvage fire years, the block volume is only
    included once in the total; no double-counting.
    */
    (
        select
            B.LICN_SEQ_NBR,
            count(*) as count_blocks_salvage_any_fire_year,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME_SALVAGE_ALL_FIRE_YEARS,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME_SALVAGE_ALL_FIRE_YEARS,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME_SALVAGE_ALL_FIRE_YEARS
        from
            FORESTVIEW.V_BLOCK B,
            (
                /*
                This distinct clause ensures each block is only counted once
                if it has any SFIRE activities.
                */
                select distinct
                    cutb_seq_nbr

                from
                    forestview.v_block_activity_all

                where
                    activity_class = 'CSB'
                    and actt_key_ind like 'SFIRE%'
            ) block_with_any_sfire_year
        where
            b.cutb_seq_nbr = block_with_any_sfire_year.cutb_seq_nbr
        group by
            B.TSO_CODE,
            B.TSO_NAME,
            licn_seq_nbr
    ) salvage_all_fire_year,

    /*
    salvage21fire

    Volume within licence that is salvage from a 2021 fire.
    Only blocks with SFIRE21 activity are included.

    */
    (
        SELECT
            B.LICN_SEQ_NBR,
            count(*) as count_blocks_salvage_21_fire,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME_SALVAGE_2021_FIRE,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME_SALVAGE_2021_FIRE,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME_SALVAGE_2021_FIRE
        FROM
            FORESTVIEW.V_BLOCK B,
            (
                /*
                The SFIRE21 activity can be entered multiple times for the same
                block. The SFIRE21 activity is meant to be present for
                blocks that are salvage from 2021 fires, and absent for those
                that are not. Multiple entries of the activity on one block are
                meaningless. For the purposes of this query, we assume that
                multiple entries are intended to indicate the block is salvage.
                This DISTINCT query ensures we only count the block volume once
                for each SFIRE21 activity on the block.
                */
                select distinct
                    cutb_seq_nbr
                from
                    forestview.v_block_activity_all
                where
                    activity_class = 'CSB'
                    and actt_key_ind = 'SFIRE21'
            ) block_with_sfire21
        where
            b.cutb_seq_nbr = block_with_sfire21.cutb_seq_nbr
        GROUP BY
            B.LICN_SEQ_NBR
    ) salvage21fire,

    /*
    salvage22fire

    Volume within licence that is salvage from a 2022 fire.
    Only blocks with SFIRE22 activity are included.

    */
    (
        SELECT
            B.LICN_SEQ_NBR,
            count(*) as count_blocks_salvage_22_fire,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME_SALVAGE_2022_FIRE,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME_SALVAGE_2022_FIRE,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME_SALVAGE_2022_FIRE
        FROM
            FORESTVIEW.V_BLOCK B,
            (
                /*
                The SFIRE22 activity can be entered multiple times for the same
                block. The SFIRE22 activity is meant to be present for
                blocks that are salvage from 2022 fires, and absent for those
                that are not. Multiple entries of the activity on one block are
                meaningless. For the purposes of this query, we assume that
                multiple entries are intended to indicate the block is salvage.
                This DISTINCT query ensures we only count the block volume once
                for each SFIRE22 activity on the block.
                */
                select distinct
                    cutb_seq_nbr
                from
                    forestview.v_block_activity_all
                where
                    activity_class = 'CSB'
                    and actt_key_ind = 'SFIRE22'
            ) block_with_sfire22
        where
            b.cutb_seq_nbr = block_with_sfire22.cutb_seq_nbr
        GROUP BY
            B.LICN_SEQ_NBR
    ) salvage22fire,

    /*
    salvage23fire

    Volume within licence that is salvage from a 2023 fire.
    Only blocks with SFIRE23 activity are included.
    */
    (
        SELECT
            B.LICN_SEQ_NBR,
            count(*) as count_blocks_salvage_23_fire,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME_SALVAGE_2023_FIRE,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME_SALVAGE_2023_FIRE,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME_SALVAGE_2023_FIRE
        FROM
            FORESTVIEW.V_BLOCK B,
            (
                /*
                The SFIRE23 activity can be entered multiple times for the same
                block. The SFIRE23 activity is meant to be present for
                blocks that are salvage from 2023 fires, and absent for those
                that are not. Multiple entries of the activity on one block are
                meaningless. For the purposes of this query, we assume that
                multiple entries are intended to indicate the block is salvage.
                This DISTINCT query ensures we only count the block volume once
                for each SFIRE23 activity on the block.
                */
                select distinct
                    cutb_seq_nbr
                from
                    forestview.v_block_activity_all
                where
                    activity_class = 'CSB'
                    and actt_key_ind = 'SFIRE23'
            ) block_with_sfire23
        where
            b.cutb_seq_nbr = block_with_sfire23.cutb_seq_nbr
        GROUP BY
            B.LICN_SEQ_NBR
    ) salvage23fire,

    /*
    salvage24fire

    Volume within licence that is salvage from a 2024 fire.
    Only blocks with SFIRE24 activity are included.

    As at 2024-02-13, this activity code has not been deployed;
    it is scripted here in anticipation of future deployment.
    */
    (
        SELECT
            B.LICN_SEQ_NBR,
            count(*) as count_blocks_salvage_24_fire,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME_SALVAGE_2024_FIRE,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME_SALVAGE_2024_FIRE,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME_SALVAGE_2024_FIRE
        FROM
            FORESTVIEW.V_BLOCK B,
            (
                /*
                The SFIRE24 activity can be entered multiple times for the same
                block. The SFIRE24 activity is meant to be present for
                blocks that are salvage from 2024 fires, and absent for those
                that are not. Multiple entries of the activity on one block are
                meaningless. For the purposes of this query, we assume that
                multiple entries are intended to indicate the block is salvage.
                This DISTINCT query ensures we only count the block volume once
                for each SFIRE24 activity on the block.
                */
                select distinct
                    cutb_seq_nbr
                from
                    forestview.v_block_activity_all
                where
                    activity_class = 'CSB'
                    and actt_key_ind = 'SFIRE24'
            ) block_with_sfire24
        where
            b.cutb_seq_nbr = block_with_sfire24.cutb_seq_nbr
        GROUP BY
            B.LICN_SEQ_NBR
    ) salvage24fire,

    /*
    salvage25fire

    Volume within licence that is salvage from a 2025 fire.
    Only blocks with SFIRE25 activity are included.

    As at 2024-02-13, this activity code has not been deployed;
    it is scripted here in anticipation of future deployment.
    */
    (
        SELECT
            B.LICN_SEQ_NBR,
            count(*) as count_blocks_salvage_25_fire,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME_SALVAGE_2025_FIRE,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME_SALVAGE_2025_FIRE,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME_SALVAGE_2025_FIRE
        FROM
            FORESTVIEW.V_BLOCK B,
            (
                /*
                The SFIRE25 activity can be entered multiple times for the same
                block. The SFIRE25 activity is meant to be present for
                blocks that are salvage from 2025 fires, and absent for those
                that are not. Multiple entries of the activity on one block are
                meaningless. For the purposes of this query, we assume that
                multiple entries are intended to indicate the block is salvage.
                This DISTINCT query ensures we only count the block volume once
                for each SFIRE25 activity on the block.
                */
                select distinct
                    cutb_seq_nbr
                from
                    forestview.v_block_activity_all
                where
                    activity_class = 'CSB'
                    and actt_key_ind = 'SFIRE25'
            ) block_with_sfire25
        where
            b.cutb_seq_nbr = block_with_sfire25.cutb_seq_nbr
        GROUP BY
            B.LICN_SEQ_NBR
    ) salvage25fire

where
    licence.licn_seq_nbr = total_licence_info.licn_seq_nbr (+)
    and licence.licn_seq_nbr = salvage_all_fire_year.licn_seq_nbr (+)
    and licence.licn_seq_nbr = salvage21fire.licn_seq_nbr (+)
    and licence.licn_seq_nbr = salvage22fire.licn_seq_nbr (+)
    and licence.licn_seq_nbr = salvage23fire.licn_seq_nbr (+)
    and licence.licn_seq_nbr = salvage24fire.licn_seq_nbr (+)
    and licence.licn_seq_nbr = salvage25fire.licn_seq_nbr (+)

order by
    business_area_region_category desc,
    business_area_region,
    business_area,
    licence_id
;


/*
qSold_detail
MS Access date format is #month/day/year#
*/
SELECT
    business_area AS [Business Area],
    Licence,
    iif(Sold_Licence_BCTS_Category_Code = '2', '2/4', Sold_Licence_BCTS_Category_Code) AS Category,
    iif(Total_Volume_Salvage_All_Fire_Year_LRM > 0, 'Yes', 'No') AS [Includes Fire Salvage],
    Last_Auction_Date AS Auction,
    Sold_Licence_Legal_Effective_Date AS Issued,
    Format(sold_licence_volume, "#,###") AS [Volume (cubic metres)],
    Format(sold_licence_maximum_value, "$#,###") AS [Max Value],
    sold_licence_client_name AS Client
FROM qSoldAdvertised_main
WHERE sold_in_report_period = 'Y'
and Sold_Licence_Legal_Effective_Date
    between #6/1/2024#
    and #6/15/2024#;


/*
qNotAwarded_detail
MS Access date format is #month/day/year#
*/

SELECT
    business_area AS [Business Area],
    Licence,
    iif(Last_Auction_BCTS_Category_Code = '2', '2/4', Last_Auction_BCTS_Category_Code) AS Category,
    iif(Total_Volume_Salvage_All_Fire_Year_LRM > 0, 'Yes', 'No') AS [Includes Fire Salvage],
    Last_Auction_Date AS Auction,
    Format(Last_Auction_No_Sale_Volume, "#,###") AS [Volume (cubic metres)],
    Last_Auction_No_Sale_Rationale AS [No Sale Rationale]
FROM qSoldAdvertised_main
WHERE
    Advertised_in_Report_Period = 'Y'
    and Last_Auction_No_Sale_Rationale is not null
    and Last_Auction_Date
        between #6/1/2024#
        and #6/15/2024#;



