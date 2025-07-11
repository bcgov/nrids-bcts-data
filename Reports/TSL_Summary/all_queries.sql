SELECT official.Business_Area_Region_Category, official.Business_Area_Region, official.Business_Area_Code, official.Business_Area, lrm.LICENCE_ID AS Licence_Number, lrm.GEOGRAPHIC_LOCATION, lrm.field_team AS Field_Team, lrm.species AS Species, official.Volume_Advertised_m3, official.Volume_ReAdvertised_m3, official.last_auction_bcts_category_code AS Auctioned_BCTS_Category_Code, official.AUCTION_COUNT_ALL_TIME_TO_REPORT_PERIOD_END AS Total_Auction_Count, official.Readvertised_Auction, official.Last_Auction_Date AS Auction_Closing_Date, official.bidder_COUNT AS Number_of_bidders, official.No_Bid, official.Upset_Rate_Value AS Upset_Rate_or_Upset_Value, official.Bonus_Bid_offer AS Bonus_Bid_or_Bonus_Value, official.Upset_Rate_Value + official.Bonus_Bid_offer AS Total_Stumpage_or_Total_Stumpage_Value, official.no_bid_info

FROM qBCTS_TSL_Summary_LRM AS lrm LEFT JOIN qBCTS_TSL_Summary_Official AS official ON official.forest_file_id = lrm.LICENCE_ID

ORDER BY official.Last_Auction_Date DESC;
 
qBCTS_TSL_Dummary_Official
 
select DISTINCT qLicenceIssuedAdvertised_Official_original.BUSINESS_AREA_REGION_CATEGORY, qLicenceIssuedAdvertised_Official_original.BUSINESS_AREA_REGION,

qLicenceIssuedAdvertised_Official_original.BUSINESS_AREA, qLicenceIssuedAdvertised_Official_original.BUSINESS_AREA_CODE, qLicenceIssuedAdvertised_Official_original.FOREST_FILE_ID,

qLicenceIssuedAdvertised_Official_original.status,

     CASE

        WHEN qLicenceIssuedAdvertised_Official_original.auction_count_all_time_to_report_period_end = 1

        THEN qLicenceIssuedAdvertised_Official_original.last_auction_volume

        ELSE NULL

    END AS Volume_Advertised_m3,

     CASE

        WHEN qLicenceIssuedAdvertised_Official_original.auction_count_all_time_to_report_period_end > 1

        THEN qLicenceIssuedAdvertised_Official_original.last_auction_volume

        ELSE NULL

    END AS Volume_ReAdvertised_m3,

qLicenceIssuedAdvertised_Official_original.last_auction_date,

qLicenceIssuedAdvertised_Official_original.last_auction_bcts_category_code,

qLicenceIssuedAdvertised_Official_original.last_auction_volume,

AUCTION_COUNT_ALL_TIME_TO_REPORT_PERIOD_END,

    CASE

        WHEN  COALESCE(bidder_count.bidder_COUNT, 0) > 0 THEN TO_CHAR(bidder_count.bidder_COUNT)

        WHEN  COALESCE(bidder_count.bidder_COUNT, 0) = 0 THEN TO_CHAR(0)

        ELSE ''

    END AS bidder_count,

    CASE

        WHEN qLicenceIssuedAdvertised_Official_original.auction_count_all_time_to_report_period_end > 1 THEN 'Y'

        WHEN qLicenceIssuedAdvertised_Official_original.auction_count_all_time_to_report_period_end = 1 THEN 'N'

        WHEN auction_count_all_time_to_report_period_end IS NULL THEN ''

    END AS Readvertised_Auction,

    CASE

        WHEN COALESCE(bidder_count.bidder_COUNT, 0) > 0 THEN ''

        WHEN ts_max.AUCTION_DATE > sysdate

        OR auction_count_all_time_to_report_period_end IS NULL

        THEN ''

        ELSE 'Y'

    END AS No_Bid,

        CASE

        WHEN COALESCE(bidder_count.bidder_COUNT, 0) > 0 THEN 'N'

        WHEN ts_max.AUCTION_DATE > sysdate

        OR auction_count_all_time_to_report_period_end IS NULL

        THEN ''

        ELSE 'Y'

    END AS No_Bid_Info,

    CASE

        WHEN qLicenceIssuedAdvertised_Official_original.CRUISE_BASED = 'N' THEN ts_max.Upset_Rate

        ELSE ts_max.TOTAL_UPSET_VALUE

    END AS Upset_Rate_Value,

    CASE

        WHEN qLicenceIssuedAdvertised_Official_original.CRUISE_BASED = 'N' THEN qLicenceIssuedAdvertised_Official_original.BONUS_BID

        ELSE qLicenceIssuedAdvertised_Official_original.BONUS_OFFER

    END AS Bonus_Bid_offer

from

(

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

    PFU.forest_file_id,

    NULL AS STATUS,

    ts.auction_date,

    ts.UPSET_RATE AS Upset_Rate,

    tb.BONUS_BID AS Bonus_Bid,

    tm.CRUISE_BASED_IND AS CRUISE_BASED,

    ts.TOTAL_UPSET_VALUE,

    tb1.BONUS_OFFER as Bonus_Offer,

    advertised.auction_count_all_time_to_report_period_end,

    advertised.first_auction_date,

    advertised.first_bcts_category_code,

    advertised.first_auction_volume,

    advertised.last_auction_date,

    advertised.last_auction_bcts_category_code,

    advertised.last_auction_volume,

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

    the.prov_forest_use pfu,

    the.bcts_timber_sale ts,

    (SELECT FOREST_FILE_ID, MAX(BONUS_BID) AS Bonus_Bid

    FROM bcts_tenure_bidder

    GROUP BY FOREST_FILE_ID, AUCTION_DATE

    )tb,

    (SELECT FOREST_FILE_ID, MAX(BONUS_OFFER) AS Bonus_offer

    FROM bcts_tenure_bidder

    GROUP BY FOREST_FILE_ID, AUCTION_DATE

    )tb1,

    the.TIMBER_MARK tm,

    the.tenure_term tt,

    the.tenure_file_status_code tfsc,

    the.org_unit ou,

    /* Advertised Licence Details */

    (

        select

            ts.forest_file_id,

            all_auctions_to_date.first_auction_date,

            last_auction.last_auction_date,

            all_auctions_to_date.auction_count_all_time_to_report_period_end,

            first_auction.bcts_category_code as first_bcts_category_code,

            ts.bcts_category_code as last_auction_bcts_category_code,

            first_auction.sale_volume as first_auction_volume,

            ts.sale_volume as last_auction_volume

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

                 and AUCTION_DATE <= to_date('2025-06-20', 'YYYY-MM-DD')

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

            ) first_auction,

             (

                select

                    ts.forest_file_id,

                    max(ts.auction_date) as last_auction_date

                from

                    the.bcts_timber_sale ts

                where

                    Nvl(no_sale_rationale_code, ' ') <> 'TB'

                and AUCTION_DATE between To_Date('2025-06-16', 'YYYY-MM-DD') -- Date: beginning of reporting period

      AND To_Date('2025-06-20', 'YYYY-MM-DD') -- Date: end of reporting period

                group by

                    ts.forest_file_id

            ) last_auction

        where

            ts.no_sale_rationale_code = nsrc.no_sale_rationale_code (+)

            and ts.forest_file_id = all_auctions_to_date.forest_file_id

            and ts.forest_file_id = last_auction.forest_file_id

            and ts.auction_date = all_auctions_to_date.last_auction_date

            and ts.forest_file_id = first_auction.forest_file_id

            and all_auctions_to_date.first_auction_date = first_auction.auction_date

    ) advertised

WHERE

    pfu.forest_file_id = ts.forest_file_id (+)

    AND pfu.bcts_org_unit = ou.org_unit_no

    AND pfu.forest_file_id = tm.forest_file_id (+)

    AND ts.forest_file_id = tb.FOREST_FILE_ID (+)

    AND ts.forest_file_id = tb1.FOREST_FILE_ID (+)

    AND pfu.forest_file_id = tt.forest_file_id (+)

    AND pfu.file_status_st = tfsc.tenure_file_status_code (+)

    AND ts.forest_file_id = advertised.forest_file_id (+)

--    AND ts.forest_file_id is not null

--     AND TS.forest_file_id IN (

--    

--     'TA2643','A60644','TA1244','TA0525','TA2684'

--    

--     )

) qLicenceIssuedAdvertised_Official_original

/* LEFT JOIN to get count of bidders 2025-05-14 BD */

LEFT JOIN

(

SELECT

    FOREST_FILE_ID,

    AUCTION_DATE,

    COUNT(DISTINCT CLIENT_NUMBER) AS bidder_count

FROM

    the.bcts_tenure_bidder

--WHERE AUCTION_DATE between To_Date('2025-06-09', 'YYYY-MM-DD') -- Date: beginning of reporting period

--      AND To_Date('2025-06-13', 'YYYY-MM-DD') -- Date: end of reporting period

GROUP BY

    FOREST_FILE_ID, AUCTION_DATE

) bidder_count

ON qLicenceIssuedAdvertised_Official_original.forest_file_id = bidder_count.FOREST_FILE_ID

AND  qLicenceIssuedAdvertised_Official_original.LAST_AUCTION_DATE = bidder_count.AUCTION_DATE

LEFT JOIN

(

SELECT

    FOREST_FILE_ID,

    AUCTION_DATE,

    UPSET_RATE AS Upset_Rate,

    TOTAL_UPSET_VALUE


FROM

    the.bcts_timber_sale ts

) ts_max

ON qLicenceIssuedAdvertised_Official_original.forest_file_id = ts_max.FOREST_FILE_ID

AND  qLicenceIssuedAdvertised_Official_original.LAST_AUCTION_DATE = ts_max.AUCTION_DATE;
 
qBCTS_TSL_Dummary_lrm
 
WITH

SPLIT_SPECIES AS (

    SELECT

        LICENCE_ID,

        BLOCK_ID,

        BLOCK_VOLUME,

        GEOGRAPHIC_LOCATION,

        FIELD_TEAM,

        TRIM(REGEXP_SUBSTR(SPECIES_COMPOSITION, '[^;]+', 1, LEVEL)) AS SPECIES_DETAIL

    FROM

        forestview.SV_SALES_SCHEDULE

    CONNECT BY

        REGEXP_SUBSTR(SPECIES_COMPOSITION, '[^;]+', 1, LEVEL) IS NOT NULL

        AND PRIOR BLOCK_ID = BLOCK_ID

        AND PRIOR LICENCE_ID = LICENCE_ID

        AND PRIOR DBMS_RANDOM.VALUE IS NOT NULL

),

PARSED_SPECIES AS (

    SELECT

        LICENCE_ID,

        BLOCK_ID,

        BLOCK_VOLUME,

        REGEXP_SUBSTR(TRIM(SPECIES_DETAIL), '^[A-Z]+') AS SPECIES_CD,

        TO_NUMBER(REGEXP_SUBSTR(SPECIES_DETAIL, '[0-9.]+')) AS SPECIES_PCT

    FROM

        SPLIT_SPECIES

    WHERE

        BLOCK_VOLUME IS NOT NULL AND BLOCK_VOLUME > 0

),

LICENCE_VOLUME AS (

    SELECT

        LICENCE_ID,

        SUM(BLOCK_VOLUME) AS TOTAL_VOLUME

    FROM

        forestview.SV_SALES_SCHEDULE

    WHERE

        BLOCK_VOLUME IS NOT NULL AND BLOCK_VOLUME > 0

    GROUP BY

        LICENCE_ID

),

CALC_WEIGHT AS (

    SELECT

        p.LICENCE_ID,

        p.SPECIES_CD,

        SUM(p.BLOCK_VOLUME * p.SPECIES_PCT) AS WEIGHTED_PCT_NUMERATOR,

        lv.TOTAL_VOLUME,

        CASE

            WHEN lv.TOTAL_VOLUME = 0 THEN 0

            ELSE SUM(p.BLOCK_VOLUME * p.SPECIES_PCT) / lv.TOTAL_VOLUME

        END AS FINAL_PCT

    FROM

        PARSED_SPECIES p

    JOIN LICENCE_VOLUME lv

        ON p.LICENCE_ID = lv.LICENCE_ID

    GROUP BY

        p.LICENCE_ID, p.SPECIES_CD, lv.TOTAL_VOLUME

),

SPECIES AS (

    SELECT

        LICENCE_ID,

        LISTAGG(

            SPECIES_CD || ' ' || ROUND(FINAL_PCT, 0) || '%',

            ', '

        ) WITHIN GROUP (ORDER BY FINAL_PCT DESC) AS SPECIES

    FROM

        CALC_WEIGHT

    WHERE ROUND(FINAL_PCT,0) > 0  

    GROUP BY

        LICENCE_ID

)


SELECT DISTINCT

    AUC_DATA.LICENCE_ID,

    ss.GEOGRAPHIC_LOCATION,

    ss.FIELD_TEAM,

    species.SPECIES

FROM

    forestview.SV_SALES_SCHEDULE ss

LEFT JOIN SPECIES

    ON species.LICENCE_ID = ss.LICENCE_ID

RIGHT JOIN (

    SELECT DISTINCT LICENCE_ID

    FROM forestview.V_LICENCE_ACTIVITY_ALL

    WHERE LICENCE_ID IN (


        'TA2643', 'A60644', 'TA1244', 'TA0525', 'TA2684'


    )

) AUC_DATA

    ON AUC_DATA.LICENCE_ID = ss.LICENCE_ID;
 