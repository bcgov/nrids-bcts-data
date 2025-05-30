/*
Query: qCurrentlyInMarket
Purpose: Query to identify which licences are posted on BC Bid as of midnight on
the report end date (time of interest).

* This query has a known flaw: it is unable to identify licences that were
open at the time of interest that have since been reauctioned.
The instructions for data entry in case of failed auctions, usually
no-bid sales, is to set the Tender Posted (TENPOST) activitiy back from Done
to Planned, and update the auction date. However, there is not a reliable way
in LRM to determine whether the licence was actively posted at the time of
interest. If the time of interest is very close to the actual query run date,
this flaw can be avoided. In general, persons will be more interested in
licences currently in the market close to the time of running the report,
so this flaw is a non-issue. However, this data model means the query results
may not always be reliably replicated at a later date.

Best practice is to run this query, and compare results against BC Bid:
https://bcbid.gov.bc.ca/page.aspx/en/rfp/request_browse_public
Set:
    Opportunity Type: Timber Auction
    Organization: BC Timber Sales Branch
    Issue Date (To): Day before date of interest (End of reporting period).
        Corresponds to Tender Posted Done date.
    Closing Date (From): Date of interest (Day after end of reporting period)
        Corresponds to auction date, usually the same day the licence is
        awarded, if applicable.

Manually include or exclude results accordingly.
*/

select
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
    ) || ' (' || L.TSO_CODE || ')' AS BUSINESS_AREA,
    L.TSO_CODE as business_area_code,
    L.NAV_NAME,
    L.FIELD_TEAM,
    L.LICENCE_ID,
    L.TENURE,
    l.licn_category_id as LRM_Category_Code,
    l.category as LRM_Category_Description,
    case
        when
            l.category is null
        then
            l.licn_category_id
        else
            L.CATEGORY || ' (' || L.licn_category_id || ')'
        end as LRM_CATEGORY,
    TENPOST.LRM_Tender_Posted_Done_Status,
    TENPOST.LRM_Tender_Posted_Done_Date,
    HA.LRM_Licence_Awarded_Done_Date,
    AUC.LRM_Auction_Done_Date,
    LV.LRM_TOTAL_VOLUME,
    case
        when
            l.licn_category_id not in ('2', '4')
        then
            LV.LRM_TOTAL_VOLUME
        end as LRM_TOTAL_VOLUME_CAT_A,
    case
                when
            l.licn_category_id in ('2', '4')
        then
            LV.LRM_TOTAL_VOLUME
        end as LRM_TOTAL_VOLUME_CAT_2_4,
    L.LICN_SEQ_NBR,
    null as Include_in_Currently_in_Market_report,  -- Populate this column manually with 'Include' or 'Exclude' based on validation with BC Bid website
    'Y' as In_CurrentlyInMarket_query,
    null as On_BC_Bid,  -- Populate this column manually, according to what is open on BC Bid at the time of interest.
    null as Data_Error  -- Populate this column manually if there are data errors that cause licences to be incorrectly included or excluded in the query results.

from
    forest.division d,
    FORESTVIEW.V_LICENCE L,

    /* Tender Posted Activity Done Date (TENPOST) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Tender_Posted_Done_Status,
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Tender_Posted_Done_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN (
                'TENPOST'
            )
            AND ac.accl_key_ind IN ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) = 'D'

        ORDER BY 1
    ) TENPOST,

    /* Licence Awarded Activity Done Date (HA) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'HA', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Licence_Awarded_Status,
            Max(DECODE(atype.actt_key_ind, 'HA', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Licence_Awarded_Done_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN (
                'HA'
            )
            AND ac.accl_key_ind IN ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            Max(DECODE(atype.actt_key_ind, 'HA', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) = 'D'

        ORDER BY 1
    ) HA,

    /* Auction Activity Done Date (AUC) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Auction_Status,
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Auction_Done_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN (
                'AUC'
            )
            AND ac.accl_key_ind IN ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) = 'D'

        ORDER BY 1
    ) AUC,


    /* Licence Volumes (LV) */
    (
        SELECT
            B.LICN_SEQ_NBR,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME,  -- Right of Way volume
            Sum(Nvl(CRUISE_VOL, 0) + Nvl(BLAL_RW_VOL, 0)) AS LRM_TOTAL_VOLUME  -- LRM Total Volume is the sum of cruise and right-of-way volumes.
        FROM
            FORESTVIEW.V_BLOCK B
        GROUP BY
            B.LICN_SEQ_NBR
        ORDER BY
            B.LICN_SEQ_NBR
    ) LV

    WHERE
        d.divi_short_code = L.TSO_CODE (+)
        and L.LICN_SEQ_NBR = TENPOST.LICN_SEQ_NBR (+)
        and L.LICN_SEQ_NBR = HA.LICN_SEQ_NBR (+)
        and l.LICN_SEQ_NBR = auc.licn_seq_nbr (+)
        AND L.LICN_SEQ_NBR = LV.LICN_SEQ_NBR (+)
        and TENPOST.licn_seq_nbr is not null  -- TENPOST (CML) must be Done. If a licence does not sell at auction, TENPOST must be set back to Planned.
        and tenpost.LRM_Tender_Posted_Done_Date <= to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: report period end. Tender posted before the time of interest.
        and (
                HA.LICN_SEQ_NBR is null  -- HA (CML) must not be Done; the licence has not been awarded.
                or HA.LRM_Licence_Awarded_Done_Date > to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: report period end. Licences not yet awarded at time of interest.
        ) and (
            not AUC.LRM_Auction_Done_Date
                between tenpost.LRM_Tender_Posted_Done_Date
                and to_date('2024-08-31', 'YYYY-MM-DD')  -- Date: report period end. Auction date not done after the tender is posted and before the end of the report period.
            or AUC.LRM_Auction_Done_Date is null
        )
/*
This union select adds a blank row
for each business area, so that if there
are no licences currently in market for that
business area, it will show up as a zero
in the  table report, rather than be excluded.
*/
union select
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
    CASE 
    WHEN D.DIVI_DIVISION_NAME = 'Seaward' THEN 'Seaward-Tlasta'
    ELSE D.DIVI_DIVISION_NAME
END || ' (' || D.DIVI_SHORT_CODE || ')' AS BUSINESS_AREA,

    D.DIVI_SHORT_CODE as business_area_code,
    null as nav_name,
    null as FIELD_TEAM,
    null as LICENCE_ID,
    null as TENURE,
    null as LRM_Category_Code,
    null as LRM_Category_Description,
    null as LRM_CATEGORY,
    null as LRM_Tender_Posted_Done_Status,
    null as LRM_Tender_Posted_Done_Date,
    null as LRM_Licence_Awarded_Done_Date,
    null as LRM_Auction_Done_Date,
    null as LRM_TOTAL_VOLUME,
    null as LRM_TOTAL_VOLUME_CAT_A,
    null as LRM_TOTAL_VOLUME_CAT_2_4,
    null as LICN_SEQ_NBR,
    'Include' as Include_in_Currently_in_Market_report,  -- Include all the blank rows from this UNION SELECT in the pivot table
    'Y' as In_CurrentlyInMarket_query,
    'Not applicable' as On_BC_Bid,  -- n/a for these blank rows in the UNION SELECT
    'Not applicable' as Data_Error  -- n/a for these blank rows in the UNION SELECT

from
    forest.division d

ORDER BY
    BUSINESS_AREA_REGION_CATEGORY desc,
    BUSINESS_AREA_REGION,  -- List 'North Interior' ahead of 'South Interior' (alphabetical)
    BUSINESS_AREA,  -- List business areas alphabetically within larger region
    NAV_NAME,
    FIELD_TEAM,
    LICENCE_ID
;
