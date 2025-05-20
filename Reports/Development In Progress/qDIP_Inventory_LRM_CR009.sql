select distinct
    case
        when
            DIV.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            DIV.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            DIV.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            DIV.DIVI_SHORT_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            DIV.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        DIV.DIVI_DIVISION_NAME,
        'Seaward',
        'Seaward-Tlasta',
        DIV.DIVI_DIVISION_NAME
    ) || ' (' || DIV.DIVI_SHORT_CODE || ')' AS BUSINESS_AREA,
    DIV.DIVI_SHORT_CODE as BUSINESS_AREA_CODE,
    CL.COLU_LOOKUP_DESC AS FieldTeam,
    MANU.MANU_ID,
    LICN.LICN_LICENCE_ID AS LICENCE_ID,
--	LICN.BLAZ_ADMIN_ZONE_ID,
    TN.TENT_TENURE_ID AS TENURE_TYPE,
    PERM.PERM_PERMIT_ID,
    MARK.MARK_MARK_ID,
    CUTB.CUTB_BLOCK_ID AS BLOCK_ID,
    CUTB.CUTB_SYSTEM_ID AS UBI,
    B.BLOCK_NBR,
    B.SUOP_SUBOP_AREA_NAME as SUB_OPERATING_AREA,
    LICN.LICN_LICENCE_STATE,
    CUTB.CUTB_BLOCK_STATE,
    CASE
        WHEN
            (
                ACTB.Old_Growth_Strategy > Nvl(LRCT.LATEST_OGS_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
            )
            OR (LDF.LATEST_DEF > Nvl(ACTB.DEF_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD')))  -- Date: fixed (1900-01-01)
        THEN
            'Y'
        ELSE
            'N'
        END AS DEFERRED_AT_REPORT_DATE,
    CASE
        WHEN
            ACTB.Old_Growth_Strategy > Nvl(LRCT.LATEST_OGS_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
        THEN
            'Deferred-OGS'
        WHEN
            LDF.LATEST_DEF > Nvl(ACTB.DEF_REACTIVATED, To_Date('1900-01-01', 'YYYY-MM-DD'))  -- Date: fixed (1900-01-01)
        THEN
            'Deferred-Other'
        ELSE
            'No Deferral'
        END AS INVENTORY_CATEGORY,
    BLAL.BLAL_MERCH_HA_AREA AS MERCH_AREA,
    BLAL.BLAL_CRUISE_M3_VOL AS CRUISE_VOLUME,
    BLAL.BLAL_RW_VOL AS RW_VOLUME,
    ACTB_S.RC_Status,
    ACTB.RC_DATE,
    Extract(Year From Add_months(ACTB.RC_DATE, 9)) As RC_Fiscal,
    ACTB_S.DR_Status,
    ACTB.DR_DATE,
    Extract(Year From Add_months(ACTB.DR_DATE, 9)) As DR_Fiscal,
    ACTB_S.DVS_Status,
    ACTB.DVS_DATE,
    Extract(Year From Add_months(ACTB.DVS_DATE, 9)) As DVS_Fiscal,
    ACTB_S.DSC_Status,
    ACTB.DSC_DATE,
    ACTB_S.DVC_Status,
    ACTB.DVC_DATE,
    Extract(Year From Add_months(ACTB.DVC_DATE, 9)) As DVC_Fiscal,
    Round(
        DECODE(
            Sign(Current_Date - To_Date('2025-04-30', 'YYYY-MM-DD')),  -- Date: end of reporting period
            -1,
            Current_Date,
            To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
        - ACTB.DVS_DATE
    ) AS Days_in_DIP,
    ACTB_S.WOFF_Status,
    ACTB.WOFF_DATE,
    Extract(Year From Add_months(ACTB.WOFF_DATE, 9)) As WOFF_Fiscal,
    AUC.AUC_Status,
    AUC.AUC_DATE,
    HI.HI_Status,
    HI.HI_DATE,
    ACTB_S.HVS_Status,
    ACTB.HVS_DATE,
    ACTB_S.HVC_Status,
    ACTB.HVC_DATE,
    FG_Met_Status, FG_DATE,
    ACTB_S.DEF_Change_of_Op_Plan_Status,
    ACTB.DEF_Change_of_Op_Plan,
    ACTB_S.DEF_First_Nations_Status,
    ACTB.DEF_First_Nations,
    ACTB_S.DEF_Loss_of_Access_Status,
    ACTB.DEF_Loss_of_Access,
    ACTB_S.DEF_Other_Status,
    ACTB.DEF_Other,
    ACTB_S.DEF_Planning_Constraint_Status,
    ACTB.DEF_Planning_Constraint,
    ACTB_S.DEF_Returned_to_BCTS_Status,
    ACTB.DEF_Returned_to_BCTS,
    ACTB_S.DEF_Stale_dated_Fieldwork_Status,
    ACTB.DEF_Stale_dated_Fieldwork,
    ACTB_S.DEF_Stakeholder_Issue_Status,
    ACTB.DEF_Stakeholder_Issue,
    ACTB_S.DEF_Environmental_Stewardship_Initiative_Status,
    ACTB.DEF_Environmental_Stewardship_Initiative,
    ACTB_S.DEF_REACTIVATED_Status,
    ACTB.DEF_REACTIVATED,
    ACTB_S.Old_Growth_Strategy_Status,
    ACTB.Old_Growth_Strategy,
    ACTB_S.OGS_Reactivated_Forest_Health_Status,
    ACTB.OGS_Reactivated_Forest_Health,
    ACTB_S.OGS_Reactivated_FN_Proceed_Status,
    ACTB.OGS_Reactivated_FN_Proceed,
    ACTB_S.OGS_Reactivated_Field_Verified_Status,
    ACTB.OGS_Reactivated_Field_Verified,
    ACTB_S.OGS_Reactivated_Minor_Status,
    ACTB.OGS_Reactivated_Minor,
    ACTB_S.OGS_Reactivated_Road_Status,
    ACTB.OGS_Reactivated_Road,
    ACTB_S.OGS_Reactivated_Re_Engineered_Status,
    ACTB.OGS_Reactivated_Re_Engineered,
    DECODE(INSTR(UPPER(CUTB.CUTB_BLOCK_ID), 'XXX') + INSTR(UPPER(CUTB.CUTB_BLOCK_ID), 'ZZZ'), 0, 'NO', 'YES') AS XXX_ZZZ_FLAG,
    DECODE(BSH.CUTB_SEQ_NBR, NULL, 'NO', 'YES') AS SPATIAL_FLAG,
    DECODE(ACTB_F.HAS_RC, 'Y', 'YES', 'NO') AS RC_FLAG,
    DECODE(ACTB_F.HAS_DR, 'Y', 'YES', 'NO') AS DR_FLAG,
    DECODE(ACTB_F.HAS_DVS, 'Y', 'YES', 'NO') AS DVS_FLAG,
    DECODE(ACTB_F.HAS_DSC, 'Y', 'YES', 'NO') AS DSC_FLAG,
    DECODE(ACTB_F.HAS_DVC, 'Y', 'YES', 'NO') AS DVC_FLAG,
    BlockCount.Count_Of_Blocks,
    decode(
        SALVAGE_ANY_FIRE_YEAR.cutb_seq_nbr,
        null,
        'N',
        'Y'
    ) SALVAGE_ANY_FIRE_YEAR,
    SALVAGE_ANY_FIRE_YEAR.salvage_fire_years,
    decode(
        salvage21.actt_key_ind,
        null,
        null,
        salvage21.activity_type || ' (' || salvage21.activity_class || ' - ' || salvage21.actt_key_ind || ')'
    ) as salvage_2021_fire,
    decode(
        salvage22.actt_key_ind,
        null,
        null,
        salvage22.activity_type || ' (' || salvage22.activity_class || ' - ' || salvage22.actt_key_ind || ')'
    ) as salvage_2022_fire,
    decode(
        salvage23.actt_key_ind,
        null,
        null,
        salvage23.activity_type || ' (' || salvage23.activity_class || ' - ' || salvage23.actt_key_ind || ')'
    ) as salvage_2023_fire,
    decode(
        salvage24.actt_key_ind,
        null,
        null,
        salvage24.activity_type || ' (' || salvage24.activity_class || ' - ' || salvage24.actt_key_ind || ')'
    ) as salvage_2024_fire,
    decode(
        salvage25.actt_key_ind,
        null,
        null,
        salvage25.activity_type || ' (' || salvage25.activity_class || ' - ' || salvage25.actt_key_ind || ')'
    ) as salvage_2025_fire,
    BLAL.LICN_SEQ_NBR,
    BLAL.MARK_SEQ_NBR,
    CUTB.CUTB_SEQ_NBR

FROM
    FOREST.DIVISION DIV,
    FOREST.CUT_BLOCK CUTB,
    FOREST.BLOCK_ALLOCATION BLAL,
    FOREST.MANAGEMENT_UNIT MANU,
    FOREST.LICENCE LICN,
    FOREST.DIVISION_CODE_LOOKUP dcl,
    FOREST.CODE_LOOKUP cl,
    FOREST.TENURE_TYPE tn,
    FOREST.CUT_PERMIT PERM,
    FOREST.MARK MARK,
    FOREST.CUT_BLOCK_SHAPE BSH,
    forestview.v_block B,  -- Todo: replace other tables in this query with v_block where possible, to simplify this query.

    /* Block Activity (ACTB) */
    (
        Select *
        From
            (
                SELECT
                    a.cutb_seq_nbr,
                    atype.actt_key_ind,
                    a.acti_status_date
                FROM
                    forest.activity_class ac,
                    forest.activity_type atype,
                    forest.activity a
                WHERE
                    ac.accl_seq_nbr = atype.accl_seq_nbr
                    AND ac.divi_div_nbr = atype.divi_div_nbr
                    AND atype.actt_seq_nbr =  a.actt_seq_nbr
                    AND (
                        /* Corporate Mandatory Block Activities (CMB) */
                        (
                            atype.actt_key_ind In (
                                'DSC',
                                'DVC',
                                'DVS',
                                'FG',
                                'HVC',
                                'HVS',
                                'RC',
                                'DR',
                                'WO'
                            )
                            AND ac.accl_key_ind = 'CMB'
                        ) OR (
                            /* Corporate Standard Block Activities (CSB) */
                            atype.actt_key_ind IN (
                                'DEL', 	-- Deletion Approval
                                'DCP',
                                'DFN',
                                'DLA',
                                'DOG',
                                'DOR',
                                'DPC',
                                'DRB',
                                'DSD',
                                'DSI',
                                'DESI',
                                'DRD',
                                'RFH',
                                'RFN',
                                'RFV',
                                'RMN',
                                'RRD',
                                'RRE'
                            )
                            AND ac.accl_key_ind = 'CSB'
                        )
                    ) AND a.plan_seq_nbr Is Null
        )
        Pivot (
            Max(acti_status_date)
            FOR ACTT_KEY_IND In (
                'DEL' AS DEL_DATE,
                'DSC' AS DSC_DATE,
                'DVC' AS DVC_DATE,
                'DVS' AS DVS_DATE,
                'FG' AS FG_DATE,
                'HVC' AS HVC_DATE,
                'HVS' AS HVS_DATE,
                'RC' AS RC_DATE,
                'DR' AS DR_DATE,
                'WO' As WOFF_DATE,
                'DCP' AS DEF_Change_of_Op_Plan,
                'DFN' AS DEF_First_Nations,
                'DLA' AS DEF_Loss_of_Access,
                'DOR' AS DEF_Other,
                'DPC' AS DEF_Planning_Constraint,
                'DRB' AS DEF_Returned_to_BCTS,
                'DSD' AS DEF_Stale_dated_Fieldwork,
                'DSI' As DEF_Stakeholder_Issue,
                'DESI' AS DEF_Environmental_Stewardship_Initiative,
                'DRD' AS DEF_REACTIVATED,
                'DOG' AS Old_Growth_Strategy,
                'RFH' AS OGS_Reactivated_Forest_Health,
                'RFN' AS OGS_Reactivated_FN_Proceed,
                'RFV' AS OGS_Reactivated_Field_Verified,
                'RMN' AS OGS_Reactivated_Minor,
                'RRD' AS OGS_Reactivated_Road,
                'RRE' AS OGS_Reactivated_Re_Engineered
            )
        )
    ) ACTB,

    /* Block Activity Status (ACTB_S) */
    (
        Select *
        From
            (
                SELECT
                    a.cutb_seq_nbr,
                    atype.actt_key_ind,
                    a.acti_status_ind
                FROM
                    forest.activity_class ac,
                    forest.activity_type atype,
                    forest.activity a
                WHERE
                    ac.accl_seq_nbr = atype.accl_seq_nbr
                    AND ac.divi_div_nbr = atype.divi_div_nbr
                    AND atype.actt_seq_nbr =  a.actt_seq_nbr
                    AND (
                    (
                        /* Corporate Mandatory Block Activities (CMB) */
                        atype.actt_key_ind In (
                            'DSC',
                            'DVC',
                            'DVS',
                            'FG',
                            'HVC',
                            'HVS',
                            'RC',
                            'DR',
                            'WO'
                        )
                        AND ac.accl_key_ind = 'CMB'
                    )
                    OR (
                        atype.actt_key_ind IN (
                            'DEL', 	-- Deletion Approval
                            'DCP',
                            'DFN',
                            'DLA',
                            'DOG',
                            'DOR',
                            'DPC',
                            'DRB',
                            'DSD',
                            'DSI',
                            'DESI',
                            'DRD',
                            'RFH',
                            'RFN',
                            'RFV',
                            'RMN',
                            'RRD',
                            'RRE'
                        )
                        AND ac.accl_key_ind = 'CSB'
                    )
            )
            AND a.plan_seq_nbr Is Null
        )
        Pivot (
            Max(acti_status_ind)
            FOR ACTT_KEY_IND In (
                'DEL' AS DEL_Status,
                'DSC' AS DSC_Status,
                'DVC' AS DVC_Status,
                'DVS' AS DVS_Status,
                'FG' AS FG_Met_Status,
                'HVC' AS HVC_Status,
                'HVS' AS HVS_Status,
                'RC' AS RC_Status,
                'DR' AS DR_Status,
                'WO' As WOFF_Status,
                'DCP' AS DEF_Change_of_Op_Plan_Status,
                'DFN' AS DEF_First_Nations_Status,
                'DLA' AS DEF_Loss_of_Access_Status,
                'DOR' AS DEF_Other_Status,
                'DPC' AS DEF_Planning_Constraint_Status,
                'DRB' AS DEF_Returned_to_BCTS_Status,
                'DSD' AS DEF_Stale_dated_Fieldwork_Status,
                'DSI' As DEF_Stakeholder_Issue_Status,
                'DESI' As DEF_Environmental_Stewardship_Initiative_Status,
                'DRD' AS DEF_REACTIVATED_Status,
                'DOG' AS Old_Growth_Strategy_Status,
                'RFH' AS OGS_Reactivated_Forest_Health_Status,
                'RFN' AS OGS_Reactivated_FN_Proceed_Status,
                'RFV' AS OGS_Reactivated_Field_Verified_Status,
                'RMN' AS OGS_Reactivated_Minor_Status,
                'RRD' AS OGS_Reactivated_Road_Status,
                'RRE' AS OGS_Reactivated_Re_Engineered_Status
            )
        )
    ) ACTB_S,

    /* Latest non-old-growth deferral activity (LDF) */
    (
        /* Excluding DOG */
        SELECT
            A2.CUTB_SEQ_NBR,
            Max(A2.ACTIVITY_DATE) AS LATEST_DEF
        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A2
        WHERE
            A2.ACTIVITY_CLASS='CSB'
            AND A2.ACTT_KEY_IND In (
                'DCP',
                'DFN',
                'DLA',
                'DOR',
                'DPC',
                'DRB',
                'DSD',
                'DSI',
                'DESI'
            )
            AND A2.ACTI_STATUS_IND='D'
            AND A2.ACTIVITY_DATE <= To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period

        GROUP BY
            A2.CUTB_SEQ_NBR
    ) LDF,

    /*
    Latest reactivation activity,
    except for Deferred - Reactivated(non-OGS) (DRD)
    (LRCT)
    */
    (
        SELECT DISTINCT
            A4.CUTB_SEQ_NBR,
            MAX(A4.ACTIVITY_DATE) AS LATEST_OGS_REACTIVATED

        FROM
            FORESTVIEW.V_BLOCK_ACTIVITY_ALL A4

        WHERE
            A4.ACTIVITY_CLASS='CSB'
            AND A4.ACTT_KEY_IND IN ('RFH', 'RFN', 'RFV', 'RMN', 'RRD', 'RRE')
            AND A4.ACTI_STATUS_IND='D'
            AND A4.ACTIVITY_DATE <= To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period

        GROUP BY
            A4.CUTB_SEQ_NBR,
            A4.ACTI_STATUS_IND
    ) LRCT,

    /*
    Block Activity Flags (ACTB_F)
    For each cutblock sequence number (cutb_seq_nbr),
    indicated 'Y' if the block has each activity associated with it,
    and Null if not.
    */
    (
        Select * From
        (
            SELECT
                a.cutb_seq_nbr,
                a.acti_seq_nbr,
                atype.actt_key_ind
            FROM
                forest.activity_class ac,
                forest.activity_type atype,
                forest.activity a
            WHERE
                ac.accl_seq_nbr = atype.accl_seq_nbr
                AND ac.divi_div_nbr = atype.divi_div_nbr
                AND atype.actt_seq_nbr =  a.actt_seq_nbr
                AND atype.actt_key_ind In ('DSC', 'DVC', 'DVS', 'FG', 'HVC', 'HVS', 'RC', 'DR', 'WO')
                AND a.plan_seq_nbr Is Null
                AND ac.accl_key_ind = 'CMB'
        )
        Pivot (
            Max(Decode(acti_seq_nbr, Null, Null, 'Y'))
            FOR ACTT_KEY_IND In (
                'DSC' AS HAS_DSC,
                'DVC' AS HAS_DVC,
                'DVS' AS HAS_DVS,
                'FG' AS HAS_FG,
                'HVC' AS HAS_HVC,
                'HVS' AS HAS_HVS,
                'RC' AS HAS_RC,
                'DR' AS HAS_DR,
                'WO' As HAS_WOFF
            )
        )
    ) ACTB_F,

    /* Auction status and date for licence (AUC) */
    (
        SELECT
            A.LICN_SEQ_NBR,
            A.ACTI_STATUS_IND AS AUC_Status,
            A.ACTI_STATUS_DATE AS AUC_DATE

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity A

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind = 'AUC'
            AND ac.accl_key_ind = 'CML'
    ) AUC,

    /* Licence Issued status and date for licence (HI) */
    (
        SELECT
            A.LICN_SEQ_NBR,
            A.ACTI_STATUS_IND AS HI_Status,
            A.ACTI_STATUS_DATE AS HI_DATE
        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity A

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind = 'HI'
            AND ac.accl_key_ind = 'CML'
    ) HI,

        /* Salvage - Any fire year */
    (
        select
            cutb_seq_nbr,
            listagg( distinct
                substr(
                    activity_type,
                    instr(activity_type, '2'),  -- find the first number '2' in the activity description
                    4  -- take the 4 characters starting with the first 2 in the string to find the four-character fire yera
                ),
                ', '
            ) within group (order by actt_key_ind) as salvage_fire_years

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind like 'SFIRE%'

          group by cutb_seq_nbr
    ) SALVAGE_ANY_FIRE_YEAR,

    /* Salvage - 2021 Fire (calendar year of fire) */
    (
        select distinct  -- Staff can enter multiple CSB SFIRE21 activity for a block; use DISTINCT to include the SFIRE21 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE21'
    ) SALVAGE21,

    /* Salvage - 2022 Fire (calendar year of fire) */
    (
        select distinct  -- Stafff can enter multiple CSB SFIRE22 activity for a block; use DISTINCT to include the SFIRE22 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE22'
    ) SALVAGE22,

    /* Salvage - 2023 Fire (calendar year of fire) */
    (
        select distinct   -- Staff can enter multiple CSB SFIRE23 activity for a block; use DISTINCT to include the SFIRE23 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE23'
    ) SALVAGE23,

    /* Salvage - 2024 Fire (calendar year of fire) */
    (
        select distinct   -- Staff can enter multiple CSB SFIRE24 activity for a block; use DISTINCT to include the SFIRE23 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE24'
    ) SALVAGE24,

    /* Salvage - 2025 Fire (calendar year of fire) */
    (
        select distinct   -- Staff can enter multiple CSB SFIRE25 activity for a block; use DISTINCT to include the SFIRE23 activity only once per block.
            cutb_seq_nbr,
            activity_class,
            actt_key_ind,
            activity_type

        from
            forestview.v_block_activity_all

        where
            activity_class = 'CSB'
            and actt_key_ind = 'SFIRE25'
    ) SALVAGE25,

    
    /*
    Number of Licences Per Block (BlockCount)
    (
    */
    (
        SELECT
            BL0.LICN_SEQ_NBR,
            Count(DISTINCT BL0.CUTB_SEQ_NBR) AS Count_Of_Blocks

        FROM
            FOREST.BLOCK_ALLOCATION BL0

        GROUP BY
            BL0.LICN_SEQ_NBR
    ) BlockCount

WHERE
    DIV.DIVI_DIV_NBR = CUTB.DIVI_DIV_NBR
    AND CUTB.CUTB_SEQ_NBR = BLAL.CUTB_SEQ_NBR (+)
    and cutb.cutb_seq_nbr = b.cutb_seq_nbr (+)
    and licn.licn_seq_nbr = b.licn_seq_nbr (+)
    and div.divi_div_nbr = b.divi_div_nbr (+)
    AND BLAL.MANU_SEQ_NBR = MANU.MANU_SEQ_NBR (+)
    AND BLAL.LICN_SEQ_NBR = LICN.LICN_SEQ_NBR (+)
    AND LICN.LICN_FIELD_TEAM_ID = dcl.COLU_LOOKUP_ID (+)
    AND LICN.DIVI_DIV_NBR = dcl.DIVI_DIV_NBR (+)
    AND dcl.COLU_LOOKUP_TYPE = cl.COLU_LOOKUP_TYPE (+)
    AND dcl.COLU_LOOKUP_ID = cl.COLU_LOOKUP_ID (+)
    AND LICN.TENT_SEQ_NBR = tn.TENT_SEQ_NBR (+)
    AND BLAL.PERM_SEQ_NBR = PERM.PERM_SEQ_NBR (+)
    AND BLAL.MARK_SEQ_NBR = MARK.MARK_SEQ_NBR (+)
    AND BLAL.CUTB_SEQ_NBR = BSH.CUTB_SEQ_NBR (+)
    AND BLAL.CUTB_SEQ_NBR = ACTB.CUTB_SEQ_NBR (+)
    AND BLAL.CUTB_SEQ_NBR = ACTB_S.CUTB_SEQ_NBR (+)
    AND BLAL.CUTB_SEQ_NBR = LDF.CUTB_SEQ_NBR (+)
    AND BLAL.CUTB_SEQ_NBR = LRCT.CUTB_SEQ_NBR (+)
    AND BLAL.CUTB_SEQ_NBR = ACTB_F.CUTB_SEQ_NBR (+)
    AND BLAL.LICN_SEQ_NBR = AUC.LICN_SEQ_NBR (+)
    AND BLAL.LICN_SEQ_NBR = HI.LICN_SEQ_NBR (+)
    and b.cutb_seq_nbr = SALVAGE_ANY_FIRE_YEAR.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage21.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage22.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage23.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage24.cutb_seq_nbr (+)
    and b.cutb_seq_nbr = salvage25.cutb_seq_nbr (+)
    AND Nvl(TN.TENT_TENURE_ID, ' ') <> 'B07'
    AND (
        ACTB_S.DVS_Status = 'D'
        AND ACTB.DVS_DATE <= To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period
    )
    AND (
        Nvl(ACTB_S.DEL_Status, ' ') <> 'D'
        OR ACTB.DEL_DATE Is Null
        OR (
            ACTB_S.DEL_Status = 'D'
            AND ACTB.DEL_DATE > To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
        )
    AND (
        Nvl(ACTB_S.DVC_Status, ' ') <> 'D'
        OR ACTB.DVC_DATE Is Null
        OR (
            ACTB_S.DVC_Status = 'D'
            AND ACTB.DVC_DATE > To_Date('2025-04-30', 'YYYY-MM-DD') -- Date: end of reporting period
        )
    )
    AND (
        Nvl(ACTB_S.WOFF_Status, ' ') <> 'D'
        OR ACTB.WOFF_DATE Is Null
        OR (
            ACTB_S.WOFF_Status = 'D'
            AND ACTB.WOFF_DATE > To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
    )
    AND (
        Nvl(AUC.AUC_Status, ' ') <> 'D'
        OR AUC.AUC_DATE Is Null
        OR (
            AUC.AUC_Status = 'D'
            AND AUC.AUC_DATE > To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
    )
    AND (
        Nvl(HI.HI_Status, ' ') <> 'D'
        OR HI.HI_DATE Is Null
        OR (
            HI.HI_Status = 'D'
            AND HI.HI_DATE > To_Date('2025-04-30', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
    )
    AND BLAL.LICN_SEQ_NBR = BlockCount.LICN_SEQ_NBR (+)

Order By
    length(business_area_region) desc,
    business_area_region,
    business_area,
    fieldteam,
    manu_id,
    licence_id,
    CUTB.CUTB_SYSTEM_ID
;
