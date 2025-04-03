select
    pfu.forest_file_id,
    pfu.MGMT_UNIT_TYPE,
    pfu.mgmt_unit_id,
    Decode(pfu.mgmt_unit_type, 'U', ta.DESCRIPTION, tf.DESCRIPTION) AS DESCRIPTION,
    decode(bcts_admin.forest_file_id, null, 'N', 'Y') as Licence_In_BCTS_ADMIN,
    hs.plnd_sb_cat_code as FTA_Planned_Category_Code,
    case
        when
            sbcc1.description is null
        then
            hs.plnd_sb_cat_code
        else
            sbcc1.description || ' (' || hs.plnd_sb_cat_code || ')'
        end as FTA_PLANNED_CATEGORY,
    hs.sold_sb_cat_code as FTA_Sold_Category_Code,
    case
        when
            sbcc.description is null
        then
            hs.sold_sb_cat_code
        else
            sbcc.description || ' (' || hs.sold_sb_cat_code || ')'
        end as FTA_SOLD_CATEGORY,
    bcts_admin.bcts_category_code as BCTS_Admin_Category_Code,
    case
        when
            c.description is null
        then
            bcts_admin.bcts_category_code
        else
            c.DESCRIPTION || ' (' || bcts_admin.BCTS_CATEGORY_CODE || ')'
        end as BCTS_ADMIN_CATEGORY,
    pfu.FILE_TYPE_CODE as fta_tenure_type,
    pfu.file_status_st as FTA_File_Status_Code,
    case
        when
            tfsc.description is null
        then
            pfu.file_status_st
        else
            tfsc.description || ' (' || pfu.file_status_st || ')'
        end as FTA_File_Status,
    pfu.file_status_date AS FTA_File_Status_DATE,
    extract(year from add_months(pfu.file_status_date, 9)) as FTA_File_Status_Fiscal,
    fta_permittee_info.FTA_Permittee_Client_Number,
    fta_permittee_info.FTA_Permittee,
    case
        when
            smc.description is null
        then
            hs.sale_method_code
        else
            smc.description || ' (' || hs.sale_method_code || ')'
        end as FTA_Sale_Method,
    hs.planned_sale_date as FTA_Planned_Sale_Date,
    hs.tender_opening_dt as FTA_Tender_Opening_Date,
    tt.legal_effective_dt as FTA_Legal_Effective_Date,
    decode(
        tt.legal_effective_dt,
        null,
        null,
        'Q' || Ceil((EXTRACT(Month From Add_Months(tt.legal_effective_dt, -3))) / 3)
    ) AS FTA_Legal_Effective_Quarter,
    TT.TENURE_TERM as FTA_TENURE_TERM,
    TT.INITIAL_EXPIRY_DT as FTA_INITIAL_EXPIRY_DATE,
    TT.CURRENT_EXPIRY_DT as FTA_CURRENT_EXPIRY_DATE,
    hs.Total_Bidders as FTA_Total_Bidders,
    bcts_admin.bcts_admin_latest_auction_date,
    bcts_admin.BCTS_Admin_Approved_By,
    bcts_admin.BCTS_Admin_Approved_Date,
    bcts_admin.no_sale_rationale_code as BCTS_Admin_No_Sale_Rationale_Code,
    case
        when
            bcts_admin.forest_file_id is null
        then
            null
        when
            bcts_admin_sale_awarded.bcts_admin_sale_awarded = 'Y'
        then
            'Y'
        else
            'N'
        end as BCTS_Admin_Sale_Awarded,
    bcts_admin.BCTS_Admin_Eligible_Bidder_Count_Latest_Auction,
    bcts_admin.BCTS_Admin_Ineligible_Bidder_Count_Latest_Auction,
    bcts_admin.BCTS_Admin_Eligibility_Missing_Count_Latest_Auction,
    bcts_admin_ineligible.BCTS_Admin_Ineligible_Indicator_Missing

    FROM
        the.prov_forest_use pfu,
        the.tenure_term tt,
        the.harvest_sale hs,
        the.sb_category_code sbcc,
        the.sb_category_code sbcc1,
        the.tsa_number_code ta,
        the.tfl_number_code tf,
        the.BCTS_CATEGORY_CODE c,
        the.tenure_file_status_code tfsc,
        the.sale_method_code smc,
        (
            select
                ts.forest_file_id,
                bcts_admin_latest_auction.bcts_admin_latest_auction_date,
                ts.bcts_category_code,
                ts.approved_by as BCTS_Admin_Approved_By,
                ts.date_approved as BCTS_Admin_Approved_Date,
                ts.no_sale_rationale_code,
                tb.BCTS_Admin_Eligible_Bidder_Count as BCTS_Admin_Eligible_Bidder_Count_Latest_Auction,
                tb.BCTS_Admin_Ineligible_Bidder_Count as BCTS_Admin_Ineligible_Bidder_Count_Latest_Auction,
                tb.BCTS_Admin_Eligibility_Indicator_Missing_Bidder_Count as BCTS_Admin_Eligibility_Missing_Count_Latest_Auction

            from
                the.bcts_timber_sale ts,
                (
                    select
                        forest_file_id,
                        max(auction_date) as bcts_admin_latest_auction_date
                    from
                        the.bcts_timber_sale ts
                    group by
                        forest_file_id
                ) bcts_admin_latest_auction,
                (
                    select
                        forest_file_id,
                        auction_date,
                        count(
                            case
                                when
                                    upper(ineligible_ind) = 'N'
                                then
                                    client_number
                                end
                        ) as BCTS_Admin_Eligible_Bidder_Count,
                        count(
                            case
                                when
                                    upper(ineligible_ind) = 'Y'
                                then
                                    client_number
                                end
                        ) as BCTS_Admin_Ineligible_Bidder_Count,
                        count(
                            case
                                when
                                    ineligible_ind is null
                                then
                                    client_number
                                end
                        ) as BCTS_Admin_Eligibility_Indicator_Missing_Bidder_Count
                                from
                                bcts_tenure_bidder
                                group by
                                forest_file_id,
                                auction_date
                ) tb
            where
                ts.forest_file_id = bcts_admin_latest_auction.forest_file_id
                and ts.auction_date = bcts_admin_latest_auction.bcts_admin_latest_auction_date
                and ts.forest_file_id = tb.forest_file_id (+)
                and ts.auction_date = tb.auction_date (+)
        ) bcts_admin,
        (
            select
                forest_file_id,
                auction_date,
                upper(max(sale_awarded_ind)) as bcts_admin_sale_awarded
            from
                the.bcts_tenure_bidder tb
            where
                upper(sale_awarded_ind) = 'Y'
            group by
                forest_file_id,
                auction_date
        ) bcts_admin_sale_awarded,
        (
            select
                forest_file_id,
                'Ineligible Indicator missing for auction date: '
                || listagg(distinct to_char(auction_date, 'yyyy-mm-dd'), ', ')
                within group (order by auction_date) as BCTS_Admin_Ineligible_Indicator_Missing
            from
                the.bcts_tenure_bidder tb
            where
                ineligible_ind is null
            group by
                forest_file_id
        ) bcts_admin_ineligible,
        (
            select
                forest_file_id,
                ffc.FTA_Permittee_Client_Number,
                decode(fc.legal_first_name, null, null, fc.legal_first_name || ' ')
                || decode(fc.legal_middle_name, null, null, fc.legal_middle_name || ' ')
                || fc.client_name as FTA_Permittee
            from
                (
                    select
                        forest_file_id,
                        max(client_number) as FTA_Permittee_Client_Number
                    from
                        forest_file_client
                    where
                        forest_file_client_type_code = 'A'  -- Licensee (the.file_client_type_code)
                    group by
                        forest_file_id  -- Should be only one 'A' type client per licence; use Group By in case there are multiple type A clients for the licence.
                ) ffc,
                forest_client fc
            where
                ffc.FTA_Permittee_Client_Number = fc.client_number
        ) fta_permittee_info

    WHERE
        pfu.forest_file_id = tt.forest_file_id (+)
        and pfu.forest_file_id = bcts_admin.forest_file_id (+)
        and pfu.forest_file_id = hs.forest_file_id (+)
        and hs.sold_sb_cat_code = sbcc.sb_category_code (+)
        and hs.plnd_sb_cat_code = sbcc1.sb_category_code (+)
        AND bcts_admin.BCTS_CATEGORY_CODE = c.BCTS_CATEGORY_CODE (+)
        and pfu.forest_file_id = bcts_admin_sale_awarded.forest_file_id (+)
        and bcts_admin.bcts_admin_latest_auction_date = bcts_admin_sale_awarded.auction_date (+)
        and pfu.forest_file_id = bcts_admin_ineligible.forest_file_id (+)
        and pfu.forest_file_id = fta_permittee_info.forest_file_id (+)
        and pfu.mgmt_unit_id = ta.tsa_number (+)
        and pfu.mgmt_unit_id = tf.tfl_number (+)
        and pfu.file_status_st = tfsc.tenure_file_status_code (+)
        and hs.sale_method_code = smc.sale_method_code (+)
;