select distinct
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
        'Seaward/Tlasta',
        L.TSO_NAME
    ) || ' (' || L.TSO_CODE || ')' AS BUSINESS_AREA,
    L.FIELD_TEAM,
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
    L.Tenure as LRM_TENURE_TYPE,
    block_count.LRM_Block_Count_for_Licence,
    L.LICENCE_ID as LRM_LICENCE_ID_RAW,
    /*
    LRM Licence values sometimes have characters before or after the licence ID.
    Use regex substring (regexp_substr) to search for the licence id
    patterns and extract the substring containing just the licence id
    that matches one of those patterns.
    e.g., 'ZZZ_TA0413' matches to 'TA0413'; 'FG A29823' matches to 'A29823'

    About regular expressions in Oracle:
    * https://docs.oracle.com/cd/B13789_01/appdev.101/b10795/adfns_re.htm
    */
    case
        when
            regexp_substr(upper(l.licence_id), 'A[0-9]{5}') is not null  -- A or a followed by 5 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null  -- Does not contain TEST, test, Test, tEst, etc.
        then
            regexp_substr(upper(l.licence_id), 'A[0-9]{5}')
        when
            regexp_substr(upper(l.licence_id), 'D[0-9]{5}') is not null  -- D or d followed by 5 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'D[0-9]{5}')
        when
            regexp_substr(upper(l.licence_id), 'L[0-9]{5}') is not null  -- L or l followed by 5 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'L[0-9]{5}')
        when
            regexp_substr(upper(l.licence_id), 'R[0-9]{5}') is not null  -- R or r followed by 5 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'R[0-9]{5}')
        when
            regexp_substr(upper(l.licence_id), 'S[0-9]{5}') is not null  -- S or s followed by 5 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'S[0-9]{5}')
        when
            regexp_substr(upper(l.licence_id), 'TA[0-9]{4}') is not null  -- TA, ta, Ta, or tA followed by 4 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'TA[0-9]{4}')
        when
            regexp_substr(upper(l.licence_id), 'TA [0-9]{4}') is not null  -- TA, ta, Ta, or tA followed by a space, followed by 4 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            'TA' || regexp_substr(regexp_substr(upper(l.licence_id), 'TA [0-9]{4}'), '[0-9]{4}')  -- Get rid of the space between the TA and the 4 numerals.
        when
            regexp_substr(upper(l.licence_id), 'W[0-9]{4}') is not null  -- W or w followed by 4 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'W[0-9]{4}')
        when
            regexp_substr(upper(l.licence_id), 'X[0-9]{5}') is not null  -- X or x followed by 5 numeral characters
            and regexp_substr(upper(l.licence_id), 'TEST') is null
        then
            regexp_substr(upper(l.licence_id), 'X[0-9]{5}')
        end as lrm_licence_id_clean,
    case
        when
            regexp_substr(l.licence_id, '[0-9]{4}') is not null  -- At least 4 numeral characters in a row
            and regexp_substr(l.licence_id, '\$[0-9]{4}') is null  -- 4 numeral characters in a row are not preceded by a dollar sign
            and regexp_substr(l.licence_id, '^[0-9]{4}/[0-9]{2}$') is null  -- 4 numeral characters in a row at the beginning of the licence id are not followed by a slash and two more numerals at the end of the licence id, such as '2019/20'
            and regexp_substr(upper(l.licence_id), 'TEST') is null  -- Does not contain the word 'test' (any case)
        then
            l.licence_id
        end as lrm_possible_valid_licence_id,
    case
        when
            trst.trst_state_desc is null
        then
            l.licn_licence_state
        else
            trst.trst_state_desc || ' (' || L.LICN_LICENCE_STATE || ')'
        end as lrm_licence_state,
    LRM_S.LRM_Auction_Status,
    LRM_D.LRM_AUCTION_Date,
    LRM_S.LRM_AWARDED_Status,
    LRM_D.LRM_AWARDED_Date,
    LRM_S.LRM_ISSUED_Status,
    LRM_D.LRM_ISSUED_Date,
    Extract(Year from Add_Months(LRM_D.LRM_ISSUED_Date, 9)) as LRM_Issued_Fiscal,
    decode(
        LRM_D.LRM_ISSUED_Date,
        null,
        null,
        'Q' || Ceil((EXTRACT(Month From Add_Months(LRM_D.LRM_ISSUED_Date, -3))) / 3)
    ) AS LRM_Issued_Quarter,
    LRM_S.LRM_Expiry_Status,  -- Expiry statuses in the future will have a Planned (P) status
    LRM_D.LRM_Expiry_Date,
    LRM_S.LRM_Extend_Status,  -- Extension dates in the future will have a Planned (P) status
    LRM_D.LRM_Extend_Date,
    case
        when
            LRM_D.LRM_Extend_Date > LRM_D.LRM_Expiry_Date
            or LRM_D.LRM_Expiry_Date is null
        then
            LRM_D.LRM_Extend_Date
        else
            LRM_D.LRM_Expiry_Date
        end as LRM_Current_Expiry_Date,
    case
        when
            LRM_D.LRM_Extend_Date > sysdate
            or LRM_D.LRM_Expiry_Date > sysdate
        then
            0
        when
            LRM_D.LRM_Extend_Date > LRM_D.LRM_Expiry_Date
            or LRM_D.LRM_Expiry_Date is null
        then
            floor(sysdate - LRM_D.LRM_Extend_Date)
        else
            floor(sysdate - LRM_D.LRM_Expiry_Date)
        end as Days_Past_LRM_Current_Expiry_Date_At_Report_Date,
    case
        when
            LRM_D.LRM_Extend_Date > sysdate
            or LRM_D.LRM_Expiry_Date > sysdate
        then
            0
        when
            LRM_D.LRM_Extend_Date > LRM_D.LRM_Expiry_Date
            or LRM_D.LRM_Expiry_Date is null
        then
            floor(months_between(sysdate, LRM_D.LRM_Extend_Date))
        else
            floor(months_between(sysdate, LRM_D.LRM_Expiry_Date))
        end as Months_Past_LRM_Current_Expiry_Date_At_Report_Date,
    case
        when
            LRM_D.LRM_Extend_Date > sysdate
            or LRM_D.LRM_Expiry_Date > sysdate
        then
            0
        when
            LRM_D.LRM_Extend_Date > LRM_D.LRM_Expiry_Date
            or LRM_D.LRM_Expiry_Date is null
        then
            floor(months_between(sysdate, LRM_D.LRM_Extend_Date) / 12)
        else
            floor(months_between(sysdate, LRM_D.LRM_Expiry_Date) / 12)
        end as Years_Past_LRM_Current_Expiry_Date_At_Report_Date,
    LRM_S.LRM_Substantial_Completion_Status,
    LRM_D.LRM_Substantial_Completion_Date,
    LRM_S.LRM_Closed_Status,
    LRM_D.LRM_Closed_Date,
    Extract(Year from Add_Months(LRM_D.LRM_Closed_Date, 9)) as LRM_Closed_Fiscal,
    decode(
        LRM_D.LRM_Closed_Date,
        null,
        null,
        'Q' || Ceil((EXTRACT(Month From Add_Months(LRM_D.LRM_Closed_Date, -3))) / 3)
    ) AS LRM_Closed_Quarter,
    LRM_S.LRM_CANCELLED_Status,
    LRM_D.LRM_CANCELLED_Date,
    LRM_S.LRM_SURRENDERED_Status,
    LRM_D.LRM_SURRENDERED_Date,
    LRM_S.LRM_VCU_Rate_Calculation_Status,
    LRM_D.LRM_VCU_Rate_Calculation_Date,
    LRM_S.LRM_Tender_Posted_Status,
    LRM_D.LRM_Tender_Posted_Date,
    LRM_S.LRM_Change_Circumstance_Post_Award_Status,
    LRM_D.LRM_Change_Circumstance_Post_Award_Date,
    L.LICN_SEQ_NBR

FROM
    FORESTVIEW.V_LICENCE L,
    forest.treeitem_state trst,


    /* LRM Activity Status (LRM_S) */
    (
        SELECT *
        From
            (
                Select
                    LICN_SEQ_NBR,
                    ACTT_KEY_IND,
                    colu_lookup_desc
                FROM
                    (
                        select *
                        from FORESTVIEW.V_LICENCE_ACTIVITY_ALL la
                        left join forest.code_lookup cl
                        on la.acti_status_ind = cl.colu_lookup_id
                        where cl.colu_lookup_type = 'ACTS'
                    )

                WHERE
                    ACTIVITY_CLASS = 'CML'
                    AND ACTT_KEY_IND IN (
                        'AUC',
                        'CCP',
                        'EXPIRE',
                        'EXTEND',
                        'HA',
                        'HC',
                        'HI',
                        'HS',
                        'HSP',
                        'HX',
                        'LC',
                        'TENPOST',
                        'VCU'
                    )
            )
            Pivot (
                Max(colu_lookup_desc)
                FOR ACTT_KEY_IND In (
                    'AUC' AS LRM_AUCTION_Status,
                    'CCP' AS LRM_Change_Circumstance_Post_Award_Status,
                    'EXPIRE' AS LRM_Expiry_Status,
                    'EXTEND' AS LRM_EXTEND_Status,
                    'HA' AS LRM_AWARDED_Status,
                    'HC' AS LRM_CLOSED_Status,
                    'HI' AS LRM_ISSUED_Status,
                    'HS' AS LRM_SURRENDERED_Status,
                    'HSP' AS LRM_SUSPENDED_Status,
                    'HX' AS LRM_CANCELLED_Status,
                    'LC' As LRM_Substantial_Completion_Status,
                    'TENPOST' AS LRM_Tender_Posted_Status,
                    'VCU' AS LRM_VCU_Rate_Calculation_Status
                )
            )
    ) LRM_S,

    /* LRM Activity Date (LRM_D) */
    (
        SELECT *

        From
            (
                Select
                    LICN_SEQ_NBR,
                    ACTI_STATUS_DATE,
                    ACTT_KEY_IND
                FROM
                    FORESTVIEW.V_LICENCE_ACTIVITY_ALL
                WHERE
                    ACTIVITY_CLASS = 'CML'
                    AND ACTT_KEY_IND IN (
                        'AUC',
                        'CCP',
                        'EXPIRE',
                        'EXTEND',
                        'HA',
                        'HC',
                        'HI',
                        'HS',
                        'HSP',
                        'HX',
                        'LC',
                        'TENPOST',
                        'VCU'
                    )
            -- Don't filter by status.
            -- Expiry Date depends on this since LRM doesn't allow the Status to be set to 'D' when the date is in future.
            -- AND ACTI_STATUS_IND = 'D'
        )
        Pivot (
            Max(ACTI_STATUS_DATE)
            FOR ACTT_KEY_IND In (
                'AUC' AS LRM_AUCTION_Date,
                'CCP' AS LRM_Change_Circumstance_Post_Award_Date,
                'EXPIRE' AS LRM_Expiry_Date,
                'EXTEND' AS LRM_EXTEND_Date,
                'HA' AS LRM_AWARDED_Date,
                'HC' AS LRM_CLOSED_Date,
                'HI' AS LRM_ISSUED_Date,
                'HSP' AS LRM_SUSPENDED_Date,
                'HX' AS LRM_CANCELLED_Date,
                'HS' AS LRM_SURRENDERED_Date,
                'LC' As LRM_Substantial_Completion_Date,
                'TENPOST' AS LRM_Tender_Posted_Date,
                'VCU' AS LRM_VCU_Rate_Calculation_Date
            )
        )
    ) LRM_D,

    /* Number of Blocks in Licence */
    (
        select
            licn_seq_nbr,
            count(cutb_seq_nbr) as LRM_Block_Count_for_Licence
        from
            forestview.v_block
        group by
            licn_seq_nbr
    ) block_count

WHERE
    L.LICN_SEQ_NBR = LRM_S.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR = LRM_D.LICN_SEQ_NBR (+)
    and l.licn_licence_state = trst.trst_state_code (+)
    and trst.tree_object_type (+) = 'Licence'
    and L.LICN_SEQ_NBR = block_count.licn_seq_nbr (+)

order by
    length(business_area_region) desc,
    business_area_region,
    business_area,
    field_team,
    lrm_licence_id_clean,
    licence_id
;
