SELECT
    L.LICENCE_ID,
    L.CATEGORY,
    L.DISTRICT_NAME,
    L.FIELD_TEAM,
    L.NAV_NAME,
    CP.PERM_APPLICATION_DESCRIPTION AS GeographicLocation,
    LV.OperatingArea,
    AUC.Auction AS LRM_Auction_Date,
    AUC.Auction_Status AS LRM_Auction_Status,
    LV.LRM_CRUISE_VOLUME,
    LV.LRM_RW_VOLUME,
    LV.LRM_TOTAL_VOLUME,
    LRM_TOTAL_VOLUME_SALVAGE_ALL_FIRE_YEARS,
    LRM_TOTAL_VOLUME_SALVAGE_2021_FIRE,
    LRM_TOTAL_VOLUME_SALVAGE_2022_FIRE,
    LRM_TOTAL_VOLUME_SALVAGE_2023_FIRE,
    LRM_TOTAL_VOLUME_SALVAGE_2024_FIRE

FROM
    FORESTVIEW.V_LICENCE L,
    FORESTVIEW.V_CP CP,
    (
        SELECT
            B.LICN_SEQ_NBR,
            Max(B.OPAR_OPERATING_AREA_NAME) AS OperatingArea,
            Max(B.CUTB_LOCATION) AS BlockLocation,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME,
            Sum(Nvl(CRUISE_VOL,0) + Nvl(BLAL_RW_VOL,0)) AS LRM_TOTAL_VOLUME
        FROM
            FORESTVIEW.V_BLOCK B
        GROUP BY
            B.LICN_SEQ_NBR
        ORDER BY
            B.LICN_SEQ_NBR
    ) LV,
    (
        SELECT
            A.LICN_SEQ_NBR,
            A.ACTIVITY_DATE AS Auction,
            A.ACTI_STATUS_IND AS Auction_Status
        FROM
            FORESTVIEW.V_LICENCE_ACTIVITY_ALL A
        WHERE
            A.ACTIVITY_CLASS='CML'
            AND A.ACTT_KEY_IND='AUC'
        ORDER BY
            A.LICN_SEQ_NBR
    ) AUC,


    /*
    salvage_all_fire_year

    Volume of blocks within licence that have any SFIRE## activities.
    If a block has multiple salvage fire years, the block volume is only
    included once in the total; no double-counting.
    */
    (
        select
                B.LICN_SEQ_NBR,
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
    ) salvage24fire

WHERE
    L.LICN_SEQ_NBR = CP.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR = LV.LICN_SEQ_NBR (+)
    AND L.LICN_SEQ_NBR = AUC.LICN_SEQ_NBR (+)
    and l.licn_seq_nbr = salvage_all_fire_year.licn_seq_nbr (+)
    and l.licn_seq_nbr = salvage21fire.licn_seq_nbr (+)
    and l.licn_seq_nbr = salvage22fire.licn_seq_nbr (+)
    and l.licn_seq_nbr = salvage23fire.licn_seq_nbr (+)
    and l.licn_seq_nbr = salvage24fire.licn_seq_nbr (+)

ORDER BY
    L.LICENCE_ID
;