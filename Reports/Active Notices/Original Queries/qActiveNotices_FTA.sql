SELECT
    ts.forest_file_id,
    ts.BCTS_CATEGORY_CODE,
    ts.auction_date,
    ts.no_sale_rationale_code,
    Cast(ts.Sale_volume AS INTEGER) AS BCTS_Admin_Vol,
    Cast(hs.Sale_Volume AS INTEGER) AS FTA_Vol,
    Cast(
        Nvl(ads.net_cruise_volume, 0)
        + Nvl(ads.decked_volume, 0)
        + Nvl(ads.rw_volume, 0)
        + Nvl(ads.OBLIGATORY_DECIDUOUS_VOLUME, 0) AS INTEGER
    ) AS ECAS_TOTAL_VOL,
    Cast(ads.net_cruise_volume AS INTEGER) AS ECAS_cruise_vol,
    Cast(ads.OBLIGATORY_DECIDUOUS_VOLUME AS INTEGER) AS ECAS_DECIDUOUS_VOL,
    Cast(ads.decked_volume AS INTEGER) AS ECAS_decked_vol,
    Cast(ads.rw_volume AS INTEGER) AS ECAS_rw_vol,
    hs.SOLD_SB_CAT_CODE, c.DESCRIPTION AS BCTS_Admin_Category

FROM
    (
        SELECT
            ts0.forest_file_id,
            ts0.BCTS_CATEGORY_CODE,
            ts0.auction_date,
            ts0.no_sale_rationale_code,
            ts0.Sale_volume,
            Rank() Over (
                Partition By
                    ts0.forest_file_id
                Order By
                    ts0.auction_date Desc
                ) AS Auction_Rank
        FROM
            THE.BCTS_TIMBER_SALE ts0
        WHERE
            ts0.auction_date >= To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
    ) ts,

    THE.BCTS_CATEGORY_CODE c,
    the.harvest_sale hs,
    /* Find the maximum appraisal effective date for the licence
    where the appraisal status is not Scenario (SCN).
    If there are multiple non-scenario appraisals on the same date for the licence,
    choose the one with the largest ecas_id. */
    (
        select
            ads0.forest_file_id,
            max(ads0.ecas_id) as ecas_id,
            count(*) as total_non_scenario_appraisals_same_effective_date
        from
            the.appraisal_data_submission ads0
            join (
                select
                    ads_no_scn.forest_file_id,
                    max(ads_no_scn.appraisal_effective_date) as max_appraisal_effective_date
                from
                    /* ECAS data without scenario status */
                    (
                        select
                            *
                        from
                            the.appraisal_data_submission
                        WHERE
                            appraisal_status_code not in ('SCN')  -- Scenario
                    ) ads_no_scn
                group by
                    ads_no_scn.forest_file_id

            ) ads1
                on ads0.forest_file_id = ads1.forest_file_id
                and ads0.appraisal_effective_date = ads1.max_appraisal_effective_date
        where
            /* Again, remove scenario status for cases when there are
            multiple appraisals on the max_appraisal_effective_date. */
            ads0.appraisal_status_code not in ('SCN')
        group by ads0.forest_file_id
    ) ECAS_ID,
    the.appraisal_data_submission ads

WHERE
    ts.forest_file_id = hs.forest_file_id (+)
    AND ts.BCTS_CATEGORY_CODE = c.BCTS_CATEGORY_CODE (+)
    AND ts.forest_file_id = ECAS_ID.forest_file_id (+)
    AND ECAS_ID.forest_file_id = ads.forest_file_id (+)
    AND ECAS_ID.ECAS_ID = ads.ECAS_ID (+)
    AND ts.Auction_Rank = 1

ORDER BY 1
;