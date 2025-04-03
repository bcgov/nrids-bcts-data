select
    case
        when
            L.TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            L.TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            L.TSO_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            L.TSO_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            L.TSO_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        L.TSO_NAME,
        'Seaward', -- See https://apps.nrs.gov.bc.ca/int/jira/projects/SD/queues/issue/SD-74878 to track whether this DECODE statement still needs to be in this report
        'Seaward-Tlasta',
        L.TSO_NAME
    ) || ' (' || L.TSO_CODE || ')' AS BUSINESS_AREA,
L.TSO_CODE as BUSINESS_AREA_CODE,
    L.FIELD_TEAM,
    L.NAV_NAME,
    L.CATEGORY,
    L.DISTRICT_NAME,
    CP.PERM_APPLICATION_DESCRIPTION AS GeographicLocation,
    L.BLAZ_ADMIN_ZONE_ID AS Agreement_Type_Code,
    L.BLAZ_ADMIN_ZONE_DESC AS Agreement_Type,
    L.LICENCE_ID,
    L.LICN_LICENCE_STATE AS LRM_LICENCE_STATE,
    AD.LRM_Tender_Posted_Status,
    AD.LRM_Tender_Posted_Date,
    AD.LRM_Auction_Status,
    AD.LRM_Auction_Date,
    LRM_CRUISE_VOLUME,
    LV.LRM_RW_VOLUME,
    LRM_TOTAL_VOLUME,
    AD.LICN_SEQ_NBR

From
    /* Activity Done Date (AD) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Tender_Posted_Status,
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Tender_Posted_Date,
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Auction_Status,
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Auction_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN ('AUC', 'TENPOST')
            and ac.accl_key_ind in ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            (
                /* Tender posted done in current fiscal (between April 1st and end of reporting period) */
                Max(DECODE(atype.actt_key_ind, 'TENPOST', a.acti_status_ind, Null)) = 'D'
                AND Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null))
                    BETWEEN To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
                    AND To_Date('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
            )
            OR (
                /*
                Auction done in current fiscal (between April 1st and end of reporting period).
                Tender posted may have any status and date, or be missing.
                */
                Max(DECODE(atype.actt_key_ind, 'AUC', a.acti_status_ind, Null)) = 'D'
                AND Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null))
                    BETWEEN To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
                    AND To_Date('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
            )
            OR (
                /* Tender posted done previous fiscal, and auction date after reporting period.
                Includes auction dates with any associated status (Planned, Done, etc.) */
                (
                    Max(DECODE(atype.actt_key_ind, 'TENPOST', a.acti_status_ind, Null)) = 'D'
                    AND Max(
                        DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)
                    ) < To_Date('2024-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
                )
                AND (
                    Max(
                        DECODE(atype.actt_key_ind, 'AUC', a.acti_status_date, Null)
                    ) > To_Date('2025-02-28', 'YYYY-MM-DD')  -- Date: end of reporting period
                )
            )
        ORDER BY 1
    ) AD,

    FORESTVIEW.V_LICENCE L,
    FORESTVIEW.V_CP CP,

    /* Licence Volumes (LV) */
    (
        SELECT
            B.LICN_SEQ_NBR,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME,  -- Right of Way volume
            Sum(Nvl(CRUISE_VOL, 0) + Nvl(BLAL_RW_VOL, 0)) AS LRM_TOTAL_VOLUME
        FROM
            FORESTVIEW.V_BLOCK B
        GROUP BY
            B.LICN_SEQ_NBR
        ORDER BY
            B.LICN_SEQ_NBR
    ) LV

WHERE
    AD.LICN_SEQ_NBR = L.LICN_SEQ_NBR
    AND AD.LICN_SEQ_NBR = CP.LICN_SEQ_NBR
    AND AD.LICN_SEQ_NBR = LV.LICN_SEQ_NBR

ORDER BY
    length(BUSINESS_AREA_REGION) desc,
    BUSINESS_AREA_REGION,
    BUSINESS_AREA,
    L.FIELD_TEAM,
    L.LICENCE_ID
;
 