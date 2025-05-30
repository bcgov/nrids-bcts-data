SELECT
    case
        when
            FD.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            FD.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            FD.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            FD.DIVI_SHORT_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            FD.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        FD.DIVI_DIVISION_NAME,
        'Seaward',
        'Seaward-Tlasta',
        FD.DIVI_DIVISION_NAME
    ) || ' (' || FD.DIVI_SHORT_CODE || ')' AS BUSINESS_AREA,
    FD.DIVI_ABBREVIATION_CODE AS BUSINESS_AREA_CODE,
    LKF.COLU_LOOKUP_DESC AS FIELD_TEAM,
    MU.MANU_ID,
    TENT.TENT_TENURE_ID AS TENURE,
    LICN.LICN_LICENCE_ID AS LICENCE,
    LS.HBS_FIRST_BILLING,
    LS.HBS_VOLUME_BILLED,
    CB.CUTB_BLOCK_ID AS BLOCK_ID,
    CB.CUTB_BLOCK_NUMBER AS BLOCK_NBR,
    CB.CUTB_SYSTEM_ID AS UBI,
    CB.CUTB_BLOCK_STATE AS BLOCK_STATE,
    CB.CUTB_OPENING,
    CB.CUTB_SITE_PLAN_EXEMPT_IND AS SP_EXEMPT,
    BLAL.BLAL_CRUISE_M3_VOL AS CRUISE_VOLUME,
    NAR.NAR_AREA,
    BIO.LARGEST_ECO_AREA,
    BIO.COUNT_BEC_WITH_LARGEST_ECO_AREA,
    BIO.BEC,
    BIO.BIO_ZONE,
    BIO.BIO_SUBZONE,
    BIO.BIO_VARIANT,
    HV.HVS_STATUS,
    HV.HVS_DATE,
    EXTRACT(YEAR FROM ADD_MONTHS(HV.HVS_DATE, 9)) AS HVS_FISCAL,
    HV.HVC_STATUS, HV.HVC_DATE,
    EXTRACT(YEAR FROM ADD_MONTHS(HV.HVC_DATE, 9)) AS HVC_FISCAL,
    S.SILA_TREATMENT_UNIT_ID AS TREATMENT_UNIT,
    CB.FUND_FUNDING_CODE AS BLOCK_FUNDING,
    S.ACTIVITY_FUNDING,
    S.SIAB_BASE_CODE AS BASE,
    S.SIAT_TECHNIQUE_CODE AS TECHNIQUE,
    S.SIAM_METHOD_CODE AS METHOD,
    S.SICA_ACTIVITY_NAME AS ACTIVITY,
    DECODE (
        S.SILA_STATUS,
        'P',
        'PLANNED',
        'D',
        'DONE',
        S.SILA_STATUS
    ) AS STATUS,
    S.SILA_START_DATE AS START_DATE,
    EXTRACT(YEAR FROM ADD_MONTHS(S.SILA_START_DATE, 9)) AS START_FISCAL,
    S.SILA_COMPLETION_DATE AS COMPLETE_DATE,
    EXTRACT(YEAR FROM ADD_MONTHS(S.SILA_COMPLETION_DATE, 9)) AS COMPLETE_FISCAL,
    DECODE(
        SILA_RANK,
        1,
        S.SILA_GROSS_HA_AREA,
        NULL
    ) AS TREATMENT_AREA,
    DECODE(
        SILA_RANK,
        1,
        TO_CHAR (ROUND (S.SILA_GROSS_HA_AREA, 1)),
        NULL
    ) AS SILA_GROSS_AREA_CHAR,
    DECODE(
        SILA_RANK,
        1,
        CASE
            WHEN
                S.ITEMS_TOTAL_PLANNED > 0
                AND S.SILA_GROSS_HA_AREA > 0
            THEN
                ROUND(S.ITEMS_TOTAL_PLANNED/S.SILA_GROSS_HA_AREA, 2)
            ELSE
                S.SILA_COST_PER_HA_PLAN
            END,
        NULL
    ) AS COST_PER_HA_PLAN,
    DECODE(
        SILA_RANK,
        1,
        CASE
            WHEN
                S.ITEMS_TOTAL_ACTUAL > 0
                AND S.SILA_GROSS_HA_AREA > 0
            THEN
                ROUND(S.ITEMS_TOTAL_ACTUAL / S.SILA_GROSS_HA_AREA, 2)
            ELSE
                S.SILA_COST_PER_HA
            END,
        NULL
    ) AS COST_PER_HA,
    DECODE(
        SILA_RANK,
        1,
        ROUND(
            DECODE(
                NVL(S.ITEMS_TOTAL_PLANNED, 0),
                0,
                S.SILA_COST_PER_HA_PLAN * S.SILA_GROSS_HA_AREA,
                S.ITEMS_TOTAL_PLANNED
            ), 2
        ),
        NULL
    ) AS PLANNED_TOTAL_COST,
    DECODE(
        SILA_RANK,
        1,
        ROUND(S.SILA_GROSS_HA_AREA * S.SILA_COST_PER_HA_PLAN, 2),
        NULL
    ) AS COST_PER_HA_PLAN_x_HA,
    DECODE(
        SILA_RANK,
        1,
        ROUND(
            DECODE(
                NVL(S.ITEMS_TOTAL_ACTUAL, 0),
                0,
                S.SILA_COST_PER_HA * S.SILA_GROSS_HA_AREA,
                S.ITEMS_TOTAL_ACTUAL
            ),
            2
        ),
        NULL
    ) AS ACTUAL_TOTAL_COST,
    DECODE(
        SILA_RANK,
        1,
        ROUND(S.SILA_GROSS_HA_AREA * S.SILA_COST_PER_HA, 2),
        NULL
    ) AS COST_PER_HA_x_HA,
    S.PLANNED_SERVICE_LINE,
    S.PLANNED_SL_DESCRIPTION,
    DECODE(
        SILA_RANK,
        1,
        S.ITEMS_TOTAL_PLANNED,
        NULL
    ) AS ITEMS_PLANNED_TOTAL_COST,
    S.ACTUAL_SERVICE_LINE,
    S.ACTUAL_SL_DESCRIPTION,
    DECODE(
        SILA_RANK,
        1,
        S.ITEMS_TOTAL_ACTUAL,
        NULL
    ) AS ITEMS_ACTUAL_TOTAL_COST,
    S.PLUN_PLANTING_UNIT_ID AS PLANTING_UNIT,
    S.PLUN_DIGITISED_IND,
    S.PLUN_PLANTING_PLAN_COST AS PLUN_PLANNED_TOTAL_COST,
    DECODE(
        S.SIAB_BASE_CODE,
        'PL',
        S.ITEM_TOTAL_PLANNED,
        NULL
    ) AS PLUN_ITEM_PLANNED_TOTAL_COST,
    S.PLUN_PLANTING_COST AS PLUN_ACTUAL_TOTAL_COST,
    DECODE(
        S.SIAB_BASE_CODE,
        'PL',
        S.ITEM_TOTAL_ACTUAL,
        NULL
    ) AS PLUN_ITEM_ACTUAL_TOTAL_COST,
    S.PLUN_HA_AREA,
    S.PLUN_NET_AREA,
    S.PLUN_DENSITY,
    S.TOTAL_TREES,
    S.SEEDLING_REQUEST,
    S.SICA_KEY_IND,
    S.PLUN_MODIFIEDBY,
    S.PLUN_MODIFIEDON,
    S.PLUN_MODIFIEDUSING,
    S.MODIFIEDBY,
    S.MODIFIEDON,
    DECODE(
        SILA_RANK,
        1,
        'Y',
        'N'
    ) AS PRIMARY_RECORD,
    Decode(
        art.cutb_seq_nbr,
        Null,
        'N',
        'Y'
    ) Need_Planting,
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
    FG.FG_Done,
    S.PLUN_SEQ_NBR,
    S.SILA_SEQ_NBR,
    S.SICA_SEQ_NBR,
    BLAL.CUTB_SEQ_NBR,
    LICN.LICN_SEQ_NBR

FROM
    FOREST.DIVISION FD,
    FOREST.BLOCK_ALLOCATION BLAL,
    FOREST.MANAGEMENT_UNIT MU,
    FOREST.CUT_BLOCK CB,
    FOREST.LICENCE LICN,
    FOREST.TENURE_TYPE TENT,
    FOREST.CODE_LOOKUP LKF,

    /* Licence Selection */
    (
        Select
            ba.licn_seq_nbr,
            Max(m.HBS_VOLUME_BILLED) AS HBS_VOLUME_BILLED,
            Min(m.FIRST_BILLING) AS HBS_FIRST_BILLING
        From
            FOREST.BLOCK_ALLOCATION ba,
            (
                SELECT
                    A.CUTB_SEQ_NBR

                FROM
                    FOREST.ACTIVITY_CLASS AC,
                    FOREST.ACTIVITY_TYPE AT,
                    FOREST.ACTIVITY A

                WHERE
                    AC.ACCL_SEQ_NBR = AT.ACCL_SEQ_NBR
                    AND AC.DIVI_DIV_NBR = AT.DIVI_DIV_NBR
                    AND AT.ACTT_SEQ_NBR = A.ACTT_SEQ_NBR
                    AND AC.ACCL_DESCRIPTION = 'CMB'
                    AND AT.ACTT_KEY_IND IN ('HVC', 'HVS')
                    AND A.PLAN_SEQ_NBR IS NULL
                    AND A.ACTI_STATUS_IND = 'D'
                    AND A.ACTI_STATUS_DATE >= TO_DATE('1994-04-01','YYYY-MM-DD')  -- Date: Fixed (1994-04-01)

                GROUP BY
                    A.CUTB_SEQ_NBR
            ) BL,
            (
                SELECT
                    hv.MARK_SEQ_NBR,
                    Sum(hv.BCHH_VOLUME_BILLED) AS HBS_VOLUME_BILLED,
                    Min(hv.BCHH_BILLING_PERIOD) AS FIRST_BILLING
                FROM
                    Forest.BCTS_HARVEST_HISTORY hv
                GROUP BY
                    hv.MARK_SEQ_NBR
                ORDER BY
                    hv.MARK_SEQ_NBR
            ) m
        WHERE
            ba.CUTB_SEQ_NBR = BL.CUTB_SEQ_NBR (+)
            AND ba.MARK_SEQ_NBR = m.MARK_SEQ_NBR (+)
            AND (
                BL.CUTB_SEQ_NBR IS NOT NULL
                OR m.MARK_SEQ_NBR IS NOT NULL
            )
        GROUP BY
        ba.licn_seq_nbr
    ) LS,

    /* HARVEST STARTED AND COMPLETED */
    (
        SELECT
            A.CUTB_SEQ_NBR,
            MAX(DECODE(AT.ACTT_KEY_IND, 'HVC', A.ACTI_STATUS_IND, NULL)) AS HVC_STATUS,
            MAX(DECODE(AT.ACTT_KEY_IND, 'HVC', A.ACTI_STATUS_DATE, NULL)) AS HVC_DATE,
            MAX(DECODE(AT.ACTT_KEY_IND, 'HVS', A.ACTI_STATUS_IND, NULL)) AS HVS_STATUS,
            MAX(DECODE(AT.ACTT_KEY_IND, 'HVS', A.ACTI_STATUS_DATE, NULL)) AS HVS_DATE

        FROM
            FOREST.ACTIVITY_CLASS AC,
            FOREST.ACTIVITY_TYPE AT,
            FOREST.ACTIVITY A

        WHERE
            AC.ACCL_SEQ_NBR = AT.ACCL_SEQ_NBR
            AND AC.DIVI_DIV_NBR = AT.DIVI_DIV_NBR
            AND AT.ACTT_SEQ_NBR = A.ACTT_SEQ_NBR
            AND AC.ACCL_DESCRIPTION = 'CMB'
            AND AT.ACTT_KEY_IND IN ('HVC', 'HVS')
            AND A.PLAN_SEQ_NBR IS NULL

        GROUP BY
            A.CUTB_SEQ_NBR
    ) HV,

    /* NAR */
    (
        SELECT
            SILP.CUTB_SEQ_NBR,
            SUM( STUN_GROSS_HA_AREA ) AS NAR_AREA

        FROM
            FOREST.STANDARD_UNIT SU,
            FOREST.SU_TYPE SUTY,
            FOREST.SILVICULTURE_PRESCRIPTION SILP

        WHERE
            SU.SILP_SEQ_NBR = SILP.SILP_SEQ_NBR
            AND SU.SUTY_TYPE_ID = SUTY.SUTY_TYPE_ID
            AND SUTY.SUTY_KEY_IND = 'PRODV'

        GROUP BY
            SILP.CUTB_SEQ_NBR
    ) NAR,

    /* Need Planting - ART */
    (
        Select
            m.CUTB_SEQ_NBR

        From
            forest.SILVICULTURE_STRATUM m,
            forest.silviculture_stocking_status k

        Where
            m.SIST_SEQ_NBR = k.SIST_SEQ_NBR
            And k.STTP_STOCKING_TYPE_ID = 'ART'

        Group By
            m.CUTB_SEQ_NBR
    ) ART,

    /*
    Largest BEC in Block
    The area of each matching BEC variant (Zone, Subzone, and Variant must match)
    is summed together. The summed area of each BEC variant is compared; the
    variant with the largest area is identified. If multiple variants tie for
    maximum summed area, each BEC variant is listed.
    */
    (
        select
            cutb_seq_nbr,
            max(GROSS_AREA_BEC) as LARGEST_ECO_AREA,
            count (distinct BEC) as COUNT_BEC_WITH_LARGEST_ECO_AREA,
            listagg(distinct BEC, ', ') within group (order by BEC) as BEC,
            listagg(distinct BIO_ZONE, ', ') within group (order by BEC) as BIO_ZONE,
            listagg(distinct BIO_SUBZONE, ', ') within group (order by BEC) as BIO_SUBZONE,
            listagg(distinct BIO_VARIANT, ', ') within group (order by BEC) as BIO_VARIANT
        from
            (
                select
                    cutb_seq_nbr,
                    GROSS_AREA_BEC,
                    BEC,
                    BIO_ZONE,
                    BIO_SUBZONE,
                    BIO_VARIANT,
                    rank() over (
                        partition by
                            cutb_seq_nbr
                        order by
                            GROSS_AREA_BEC desc
                    ) as bec_rank
                from
                    (
                        SELECT
                            e.CUTB_SEQ_NBR,
                            sum(e.GROSS_AREA) AS GROSS_AREA_BEC,
                            e.BIOZ_ZONE_ID || e.BIOS_SUBZONE_ID || e.BIOV_VARIANT_ID AS BEC,
                            decode(
                                bioz_zone_name,
                                null,
                                e.BIOZ_ZONE_ID,
                                bioz_zone_name || ' (' || e.BIOZ_ZONE_ID || ')'
                            ) as BIO_ZONE,
                            case
                                when
                                    bios_subzone_name is not null
                                then
                                    bios_subzone_name || ' (' || e.BIOZ_ZONE_ID || e.BIOS_SUBZONE_ID || ')'
                                when
                                    e.BIOS_SUBZONE_ID is not null
                                then
                                    e.BIOZ_ZONE_ID || e.BIOS_SUBZONE_ID
                                end as bio_subzone,
                            case
                                when
                                    biov_variant_name is not null
                                then
                                    biov_variant_name || ' (' || e.BIOZ_ZONE_ID || e.BIOS_SUBZONE_ID || e.BIOV_VARIANT_ID || ')'
                                when
                                    e.BIOS_SUBZONE_ID is not null
                                    and e.BIOV_VARIANT_ID is not null
                                then
                                    e.BIOZ_ZONE_ID || e.BIOS_SUBZONE_ID || e.BIOV_VARIANT_ID
                                end as BIO_VARIANT
                        FROM
                            FORESTVIEW.V_ECOLOGY e,
                            forest.biogeoclimatic_zone bz,
                            forest.biogeoclimatic_subzone bsz,
                            forest.biogeoclimatic_variant bv
                        where
                            e.BIOZ_ZONE_ID = bz.BIOZ_ZONE_ID (+)
                            and e.BIOZ_ZONE_ID = bsz.BIOZ_ZONE_ID (+)
                            and e.BIOS_SUBZONE_ID = bsz.BIOS_SUBZONE_ID (+)
                            and e.BIOZ_ZONE_ID = bv.BIOZ_ZONE_ID (+)
                            and e.BIOS_SUBZONE_ID = bv.BIOS_SUBZONE_ID (+)
                            and e.BIOV_VARIANT_ID = bv.BIOV_VARIANT_ID(+)
                        group by
                            e.cutb_seq_nbr,
                            e.BIOZ_ZONE_ID,
                            e.BIOS_SUBZONE_ID,
                            e.BIOV_VARIANT_ID,
                            bz.bioz_zone_name,
                            bsz.bios_subzone_name,
                            bv.biov_variant_name
                    ) area_each_bec
            )
        where
            bec_rank = 1
        group by
            cutb_seq_nbr
    ) BIO,

    /* Silviculture */
    (
        SELECT
            SA.SILA_TREATMENT_UNIT_ID,
            SA.ACTIVITY_FUNDING,
            SCA.SIAB_BASE_CODE,
            SCA.SIAT_TECHNIQUE_CODE,
            SCA.SIAM_METHOD_CODE,
            SCA.SIAO_OBJECTIVE_CODE AS OBJECTIVE1,
            SCA.SIAO_OBJECTIVE_CODE2 AS OBJECTIVE2,
            SCA.SIAO_OBJECTIVE_CODE3 AS OBJECTIVE3,
            SCA.SICA_KEY_IND,
            SCA.SICA_ACTIVITY_NAME,
            SA.SILA_STATUS,
            SA.RESP_RESPONSIBILITY_CODE,
            SA.SILA_START_DATE,
            SA.SILA_COMPLETION_DATE,
            SA.SILA_GROSS_HA_AREA,
            SA.SILA_COST_PER_HA_PLAN,
            SA.SILA_COST_PER_HA,
            SAC.PLANNED_SERVICE_LINE,
            SAC.PLANNED_SL_DESCRIPTION,
            SACT.ITEMS_TOTAL_PLANNED,
            SAC.ITEM_TOTAL_PLANNED,
            SAC.ACTUAL_SERVICE_LINE,
            SAC.ACTUAL_SL_DESCRIPTION,
            SACT.ITEMS_TOTAL_ACTUAL,
            SAC.ITEM_TOTAL_ACTUAL,
            SA.PLUN_PLANTING_UNIT_ID,
            SA.PLUN_DIGITISED_IND,
            SA.PLUN_PLANTING_PLAN_COST,
            SA.PLUN_PLANTING_COST,
            SA.PLUN_HA_AREA,
            SA.PLUN_NET_AREA,
            SA.PLUN_DENSITY,
            SA.TOTAL_TREES,
            RK.SEEDLING_REQUEST,
            SA.PLUN_MODIFIEDBY,
            SA.PLUN_MODIFIEDON,
            SA.PLUN_MODIFIEDUSING,
            DS.DSAS_APPLY_RATE AS APPLY_RATE,
            DS.PMPL_PMP_NBR AS PMP_NBR,
            SP.TARGET_SPECIES AS TARGET_SPECIES,
            SA.COMMENTS,
            SA.SILA_FORMB_DATE,
            SA.SILA_FORMB_PRINTED,
            SA.MODIFIEDBY,
            SA.MODIFIEDON,
            RANK() OVER (
                PARTITION BY
                    SA.SILA_SEQ_NBR
                ORDER BY
                    SA.PLUN_PLANTING_UNIT_ID,
                    SA.PLUN_SEQ_NBR,
                    SAC.ACTUAL_COST_ITEM_ID,
                    SAC.PLANNED_COST_ITEM_ID
                ) AS SILA_RANK,
            DECODE(
                SA.PLUN_SEQ_NBR,
                0,
                NULL,
                SA.PLUN_SEQ_NBR
            ) AS PLUN_SEQ_NBR,
            SA.SILA_SEQ_NBR,
            SA.SICA_SEQ_NBR,
            SA.CUTB_SEQ_NBR
        FROM
            FOREST.SILVICULTURE_COMPANY_ACTIVITY SCA,
            FOREST.DETAILED_SITE_ASSESSMENT DS,
            (
                SELECT
                    SA0.SILA_TREATMENT_UNIT_ID,
                    SA0.FUND_FUNDING_CODE AS ACTIVITY_FUNDING,
                    SA0.SILA_STATUS, SA0.RESP_RESPONSIBILITY_CODE,
                    SA0.SILA_START_DATE,
                    SA0.SILA_COMPLETION_DATE,
                    SA0.SILA_GROSS_HA_AREA,
                    SA0.SILA_COST_PER_HA_PLAN,
                    SA0.SILA_COST_PER_HA,
                    SUBSTR(SA0.SILA_COMMENTS, 1, 4000) AS COMMENTS,
                    SA0.SILA_FORMB_DATE,
                    SA0.SILA_FORMB_PRINTED,
                    SA0.MODIFIEDBY,
                    SA0.MODIFIEDON,
                    PLU.PLUN_PLANTING_UNIT_ID,
                    PLU.PLUN_DIGITISED_IND,
                    PLU.PLUN_PLANTING_PLAN_COST,
                    PLU.PLUN_PLANTING_COST,
                    PLU.PLUN_HA_AREA,
                    PLU.PLUN_NET_AREA,
                    PLU.PLUN_DENSITY,
                    PLU.TOTAL_TREES,
                    PLU.MODIFIEDBY AS PLUN_MODIFIEDBY,
                    PLU.MODIFIEDON AS PLUN_MODIFIEDON,
                    PLU.MODIFIEDUSING AS PLUN_MODIFIEDUSING,
                    NVL(PLU.PLUN_SEQ_NBR, 0) AS PLUN_SEQ_NBR,
                    SA0.SILA_SEQ_NBR,
                    SA0.SICA_SEQ_NBR,
                    SA0.CUTB_SEQ_NBR
                FROM
                    FOREST.SILVICULTURE_ACTIVITY SA0,
                    FOREST.PLANTING_UNIT PLU

                WHERE
                    SA0.SILA_SEQ_NBR = PLU.SILA_SEQ_NBR (+)
            ) SA,

            /* SPECIES */
            (
                SELECT
                    BTS.SILA_SEQ_NBR,
                    LISTAGG(BTS.SISP_SPECIES_ID, ', ') WITHIN GROUP (ORDER BY BTS.SISP_SPECIES_ID) AS TARGET_SPECIES

                FROM
                    FOREST.BRUSHING_TARGET_SPECIES BTS

                GROUP BY
                    BTS.SILA_SEQ_NBR
            ) SP,

            /* TOTAL BY ITEMS AND GET SERVICE LINE RANKED BY THE TOTAL COST. */
            (
                SELECT
                    SAC0.SILA_SEQ_NBR,
                    NVL(SAC0.PLUN_SEQ_NBR, 0) AS PLUN_SEQ_NBR,
                    SAC0.ITEM_TOTAL_PLANNED,
                    SAC0.ITEM_TOTAL_ACTUAL,
                    CI0.CSTI_COST_ITEM_ACCOUNT_CODE AS PLANNED_SERVICE_LINE,
                    CI0.CSTI_COST_ITEM_DESCRIPTION AS PLANNED_SL_DESCRIPTION,
                    CI1.CSTI_COST_ITEM_ACCOUNT_CODE AS ACTUAL_SERVICE_LINE,
                    CI1.CSTI_COST_ITEM_DESCRIPTION AS ACTUAL_SL_DESCRIPTION,
                    SCAC0.CSTI_COST_ITEM_ID AS PLANNED_COST_ITEM_ID,
                    SCAC1.CSTI_COST_ITEM_ID AS ACTUAL_COST_ITEM_ID

                FROM
                    FOREST.SILV_COMPANY_ACTIVITY_COST SCAC0,
                    FOREST.FRST_COST_ITEM CI0,
                    FOREST.SILV_COMPANY_ACTIVITY_COST SCAC1,
                    FOREST.FRST_COST_ITEM CI1,
                    (
                        SELECT
                            C0.SILA_SEQ_NBR,
                            C0.PLUN_SEQ_NBR,
                            MAX(
                                CASE
                                    WHEN
                                        C0.SL_RANK = 1
                                        AND UPPER(C0.SACC_SERIES) = 'PLANNED'
                                    THEN
                                        C0.SCAC_SEQ_NBR
                                    END
                            ) AS P_SCAC_SEQ_NBR,
                            MAX(
                                CASE
                                    WHEN
                                        C0.SL_RANK = 1
                                        AND UPPER(C0.SACC_SERIES) = 'ACTUAL'
                                    THEN
                                        C0.SCAC_SEQ_NBR
                                    END
                            ) AS A_SCAC_SEQ_NBR,
                            SUM(DECODE(UPPER(C0.SACC_SERIES), 'PLANNED', C0.SUB_COST, 0)) AS ITEM_TOTAL_PLANNED,
                            SUM(DECODE(UPPER(C0.SACC_SERIES), 'ACTUAL', C0.SUB_COST, 0)) AS ITEM_TOTAL_ACTUAL
                        FROM
                            (
                                SELECT
                                    C.SILA_SEQ_NBR,
                                    C.PLUN_SEQ_NBR,
                                    C.SCAC_SEQ_NBR,
                                    SUM(C.SACC_ITEM_COST) AS SUB_COST,
                                    RANK() OVER (
                                        PARTITION BY
                                            C.SILA_SEQ_NBR,
                                            C.PLUN_SEQ_NBR,
                                            C.SACC_SERIES
                                        ORDER BY
                                            SUM(NVL(C.SACC_ITEM_COST, 0))
                                    ) AS SL_RANK,
                                    C.SACC_SERIES
                                FROM
                                    FOREST.SILV_ACTIVITY_COST C,

                                    /* PLANTING ACTIVITIES */
                                    (
                                        SELECT
                                            SILA_SEQ_NBR
                                        FROM
                                            FOREST.SILV_ACTIVITY_COST
                                        GROUP BY
                                            SILA_SEQ_NBR
                                        HAVING
                                            MAX(PLUN_SEQ_NBR) IS NOT NULL
                                        ORDER BY 1
                                    ) SPL

                                WHERE
                                    C.SILA_SEQ_NBR = SPL.SILA_SEQ_NBR (+)

                                    /* Filter out hidden planting records without PLUN_SEQ_NBR */
                                    AND (
                                        SPL.SILA_SEQ_NBR IS NULL /* Non-planting */
                                        OR (
                                            SPL.SILA_SEQ_NBR IS NOT NULL
                                            AND C.PLUN_SEQ_NBR IS NOT NULL
                                        ) /* Planting with planting unit */
                                    )

                                GROUP BY
                                    C.SILA_SEQ_NBR,
                                    C.PLUN_SEQ_NBR,
                                    C.SCAC_SEQ_NBR,
                                    C.SACC_SERIES
                            ) C0
                        GROUP BY
                            C0.SILA_SEQ_NBR,
                            C0.PLUN_SEQ_NBR
                    ) SAC0

                WHERE
                    SAC0.P_SCAC_SEQ_NBR = SCAC0.SCAC_SEQ_NBR (+)
                    AND SCAC0.DIVI_DIV_NBR = CI0.DIVI_DIV_NBR (+)
                    AND SCAC0.CSTI_COST_ITEM_ID = CI0.CSTI_COST_ITEM_ID (+)
                    AND SAC0.A_SCAC_SEQ_NBR = SCAC1.SCAC_SEQ_NBR (+)
                    AND SCAC1.DIVI_DIV_NBR = CI1.DIVI_DIV_NBR (+)
                    AND SCAC1.CSTI_COST_ITEM_ID = CI1.CSTI_COST_ITEM_ID (+)
            ) SAC,

            /* ALL ITEMS TOTAL */
            (
                SELECT
                    C.SILA_SEQ_NBR,
                    SUM(DECODE(UPPER(C.SACC_SERIES), 'PLANNED', C.SACC_ITEM_COST, 0)) AS ITEMS_TOTAL_PLANNED,
                    SUM(DECODE(UPPER(C.SACC_SERIES), 'ACTUAL', C.SACC_ITEM_COST, 0)) AS ITEMS_TOTAL_ACTUAL

                FROM
                    FOREST.SILV_ACTIVITY_COST C,

                    /* PLANTING ACTIVITIES */
                    (
                        SELECT
                            SILA_SEQ_NBR

                        FROM
                            FOREST.SILV_ACTIVITY_COST

                        GROUP BY
                            SILA_SEQ_NBR

                        HAVING
                            MAX(PLUN_SEQ_NBR) IS NOT NULL

                        ORDER BY 1
                    ) SPL

                WHERE
                    C.SILA_SEQ_NBR = SPL.SILA_SEQ_NBR (+)
                    AND (
                        SPL.SILA_SEQ_NBR IS NULL  /* Non-planting */
                        OR (
                            SPL.SILA_SEQ_NBR IS NOT NULL
                            AND C.PLUN_SEQ_NBR IS NOT NULL
                        )  /* Planting with planting unit */
                    )

                GROUP BY
                    C.SILA_SEQ_NBR
            ) SACT,

        /* Reqeust Key */
        (
            SELECT DISTINCT
                PS.PLUN_SEQ_NBR,
                LISTAGG(
                    PS.SISP_SPECIES_ID
                    || '/Lot:'
                    || PS.SISL_SEED_LOT_NUMBER
                    || '/$'
                    || PS.PLSP_PRICE_PER_TREE
                    || '/Trees:'
                    || PS.PLSP_NUMBER_TREES
                    || '/Req_Key:'
                    || PS.SIRK_REQUEST_KEY,
                    ' '
                ) WITHIN GROUP (
                    ORDER BY
                        PS.SISP_SPECIES_ID,
                        PS.SIRK_REQUEST_KEY,
                        PS.SISL_SEED_LOT_NUMBER
                ) OVER (
                    PARTITION BY
                        PS.PLUN_SEQ_NBR
                ) AS SEEDLING_REQUEST

            FROM
                FOREST.PLANTING_SPECIES PS
        ) RK

    WHERE
        SCA.SICA_SEQ_NBR = SA.SICA_SEQ_NBR
        AND SA.PLUN_SEQ_NBR = RK.PLUN_SEQ_NBR(+)
        AND SA.SILA_SEQ_NBR = SAC.SILA_SEQ_NBR (+)
        AND SA.PLUN_SEQ_NBR = SAC.PLUN_SEQ_NBR (+)
        AND SA.SILA_SEQ_NBR = SACT.SILA_SEQ_NBR(+)
        AND SA.SILA_SEQ_NBR = DS.SILA_SEQ_NBR(+)
        AND SA.SILA_SEQ_NBR = SP.SILA_SEQ_NBR(+)
        AND NVL(SCA.SICA_KEY_IND, ' ') <> 'HV'
        AND SCA.SIAB_BASE_CODE Is Not Null
    ) S,     /* Salvage - Any fire year */
    (
        select
            cutb_seq_nbr,
            listagg( distinct -- Possible to enter same activity multiple times; only want year listed once
                substr(
                    activity_type,
                    instr(activity_type, '2'),  -- find the first number '2' in the activity description
                    4  -- take the 4 characters starting with the first 2 in the string to find the four-character fire year
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
        select distinct   -- Staff can enter multiple CSB SFIRE23 activity for a block; use DISTINCT to include the SFIRE23 activity only once per block.
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
        select distinct   -- Staff can enter multiple CSB SFIRE25 activity for a block; use DISTINCT to include the SFIRE25 activity only once per block.
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

        /* Free Growing Met, Done (FG) */
    (
        SELECT
            af.cutb_seq_nbr,
            af.acti_status_date AS FG_DONE

        FROM
            forest.activity_class acf,
            forest.activity_type atypef,
            forest.activity af

        WHERE
            acf.accl_seq_nbr = atypef.accl_seq_nbr
            AND acf.divi_div_nbr = atypef.divi_div_nbr
            AND atypef.actt_seq_nbr =  af.actt_seq_nbr
            AND atypef.actt_key_ind = 'FG'  -- Free Growing Met
            AND acf.accl_description = 'CMB'  -- Corporate Mandatory Block (CMB) activity class
            AND af.Acti_status_ind = 'D'  -- Done (D)
    ) FG

WHERE
    FD.DIVI_DIV_NBR = BLAL.DIVI_DIV_NBR
    AND BLAL.MANU_SEQ_NBR = MU.MANU_SEQ_NBR
    AND BLAL.LICN_SEQ_NBR = LS.LICN_SEQ_NBR
    AND BLAL.LICN_SEQ_NBR = LICN.LICN_SEQ_NBR(+)
    AND LICN.TENT_SEQ_NBR = TENT.TENT_SEQ_NBR(+)
    AND LICN.LICN_FIELD_TEAM_ID = LKF.COLU_LOOKUP_ID(+)
    AND LKF.COLU_LOOKUP_TYPE(+) = 'FDTM'
    AND BLAL.CUTB_SEQ_NBR = CB.CUTB_SEQ_NBR
    AND BLAL.CUTB_SEQ_NBR = HV.CUTB_SEQ_NBR(+)
    AND BLAL.CUTB_SEQ_NBR = NAR.CUTB_SEQ_NBR(+)
    AND BLAL.CUTB_SEQ_NBR = ART.CUTB_SEQ_NBR(+)
    AND BLAL.CUTB_SEQ_NBR = BIO.CUTB_SEQ_NBR(+)
    AND BLAL.CUTB_SEQ_NBR = S.CUTB_SEQ_NBR
    and blal.cutb_seq_nbr = SALVAGE_ANY_FIRE_YEAR.cutb_seq_nbr (+)
    and blal.cutb_seq_nbr = salvage21.cutb_seq_nbr (+)
    and blal.cutb_seq_nbr = salvage22.cutb_seq_nbr (+)
    and blal.cutb_seq_nbr = salvage23.cutb_seq_nbr (+)
    and blal.cutb_seq_nbr = salvage24.cutb_seq_nbr (+)
    and blal.cutb_seq_nbr = salvage25.cutb_seq_nbr (+)
    AND BLAL.CUTB_SEQ_NBR = FG.CUTB_SEQ_NBR (+)

ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    MU.MANU_ID,
    LICN.LICN_LICENCE_ID,
    CB.CUTB_BLOCK_ID,
    S.SILA_SEQ_NBR,
    S.SILA_RANK
;
