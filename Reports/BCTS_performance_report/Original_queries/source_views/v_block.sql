--------------------------------------------------------
--  File created - Tuesday-December-10-2024   
--------------------------------------------------------
-- Unable to render VIEW DDL for object FORESTVIEW.V_BLOCK with DBMS_METADATA attempting internal generator.
CREATE VIEW FORESTVIEW.V_BLOCK
AS SELECT D.DIVI_DIV_NBR,
             D.DIVI_SHORT_CODE                         AS TSO_CODE,
             D.DIVI_DIVISION_NAME                      AS TSO_NAME,
             COLU.COLU_LOOKUP_DESC                     AS FIELD_TEAM_DESC,
             M.MANU_ID                                 AS NAV_NAME,
             TN.TENT_TENURE_ID                         AS TENURE,
             L.LICN_LICENCE_ID                         AS LICENCE_ID,
             DECODE (UPPER (SUBSTR (P.PERM_PERMIT_ID, 1, 4)),
                     'APR-', NULL,
                     P.PERM_PERMIT_ID)                 AS PERMIT_ID,
             MK.MARK_MARK_ID                           AS MARK_ID,
             B.CUTB_BLOCK_ID                           AS BLOCK_ID,
             B.CUTB_BLOCK_NUMBER                       AS BLOCK_NBR,
             B.CUTB_SYSTEM_ID                          AS UBI,
             B.CUTB_OPENING                            AS OPENING,
             B.OPAR_OPERATING_AREA_ID                  AS OP_AREA,
             OA.OPAR_OPERATING_AREA_NAME,
             OA.OZON_OPERATING_ZONE_ID,
             B.SBLK_SUPPLY_BLOCK_ID                    AS SUPPLY_BLOCK,
             B.CUTB_EBM_IND                            AS EBM_INDICATOR,
             B.CUTB_PHOTOS                             AS PHOTO,
             TRIM (B.CUTB_LATITUDE)                    AS LATITUDE,
             TRIM (B.CUTB_LONGITUDE)                   AS LONGITUDE,
             B.CUTB_PROV_FOREST_CONFLICT               AS PROV_FRST_CONFLICT,
             B.CUTB_USER_MAPSHEET_ID                   AS MAPSHEET_ID,
             B.LSUN_LANDSCAPE_UNIT                     AS LANDSCAPE_UNIT,
             B.CUTB_SITE_PLAN_EXEMPT_IND               AS SP_EXEMPT,
             B.STTP_STAND_TYPE                         AS STAND_TYPE,
             B.TTAC_TIMBERTYPE_AGE_CLASS               AS AGE_CLASS,
             B.TTHC_TIMBERTYPE_HEIGHT_CLASS            AS HGT_CLASS,
             B.TTSC_TIMBERTYPE_STOCK_CLASS             AS STK_CLASS,
             SI.SITE_INDEX,
             --b.cutb_site_index site_index,
             B.SSSC_SOURCE_CODE                        AS source,
             B.FDPS_STATUS_ID                          AS FDP_STATUS,
             B.FUND_FUNDING_CODE                       AS FUNDING_CODE,
             B.CUTB_BLOCK_MEMO,
             BA.BLAL_GROSS_HA_AREA                     AS GROSS_AREA,
             BA.BLAL_ESTIMATED_AREA                    AS EST_AREA,
             BA.BLAL_MERCH_HA_AREA                     AS MERCH_AREA,
             BA.BLAL_HARVESTED_HA_AREA                 AS HARVEST_AREA,
             (  NVL (BA.BLAL_MERCH_HA_AREA, 0)
              - NVL (BA.BLAL_HARVESTED_HA_AREA, 0))    AS REMAINING_AREA,
             BA.BLAL_CRUISE_M3_VOL                     AS CRUISE_VOL,
             BA.BLAL_DATA_SOURCE                       AS DATA_SOURCE,
             BA.BLAL_HARVESTED_M3_VOL                  AS HARVEST_VOL,
             (  NVL (BA.BLAL_CRUISE_M3_VOL, 0)
              - NVL (BA.BLAL_HARVESTED_M3_VOL, 0))     AS REMAINING_VOL,
             BA.BLAL_USR_CRUISE_M3_VOL,
             BA.BLAL_RW_HA_AREA                        AS RW_AREA,
             BA.BLAL_RW_VOL,
             B.CUTB_FORMA_PRINT_DATE,
             B.CUTB_FORMA_PRINTED,
             B.CUTB_BLOCK_STATE,
             B.PMOD_MODIFIER_ID,
             B.CUTB_LOCATION,
             B.SUOP_SUBOP_AREA_ID,
             SUOP.SUOP_SUBOP_AREA_NAME,
             B.CUTB_OPENING_ID,
             l.LICN_LICENCE_STATE,
             SZ.SEED_ZONE,
             CUTB_FILE_ID,
             ELV.MIN_ELEVATION,
             ELV.MAX_ELEVATION,
             B.BCAT_CATEGORY_CODE,
             B.CUTB_ACCESS_RESTRICTION,
             per.PERS_DISPLAY_NAME                     AS REGIME_CREATED_BY,
             STR.TREG_REGIME_ID,
             STR.TREG_REGIME_NAME,
             STR.TREG_CREATE_DATE,
             STR.TREG_ACTIVE_IND,
             STR.TREG_DEF_IND,
             m.MANU_NAME                               AS NAV_ID,
             B.FINZ_FOREST_INVENTORY_ZONE_ID           AS FIZ,
             HV.HVS_STATUS,
             HV.HVS_TARGET_DATE,
             HV.HVS_STATUS_DATE,
             HV.HVC_STATUS,
             HV.HVC_TARGET_DATE,
             HV.HVC_STATUS_DATE,
             M.MANU_SEQ_NBR,
             L.LICN_SEQ_NBR,
             P.PERM_SEQ_NBR,
             MK.MARK_SEQ_NBR,
             B.CUTB_SEQ_NBR,
			 B.CUTB_CPRP_PROTECTION_IND,
			 B.CUTB_RC_RISK_RATING,
			 B.CUTB_RC_RISK_SOURCE
        FROM FOREST.CUT_BLOCK            B,
             FOREST.BLOCK_ALLOCATION     BA,
             FOREST.DIVISION             D,
             FOREST.MANAGEMENT_UNIT      M,
             FOREST.LICENCE              L,
             FOREST.CUT_PERMIT           P,
             FOREST.CODE_LOOKUP          COLU,
             FOREST.MARK                 MK,
             FOREST.TENURE_TYPE          TN,
             FOREST.OPERATING_AREA       OA,
             FOREST.SILV_TREATMENT_REGIME STR,
             FOREST.CUT_BLOCK_SILV_REGIME CBSR,        -- Upddate from Trimbel
             FOREST.SUB_OPERATING_AREA   SUOP,
             FOREST.PERSON               per,
             /* Elevation */
              (  SELECT EU.CUTB_SEQ_NBR,
                        MIN (EU.ECOU_ELEVATION_MIN)     AS MIN_ELEVATION,
                        MAX (EU.ECOU_ELEVATION_MAX)     AS MAX_ELEVATION
                   FROM FOREST.ECOLOGY_UNIT EU
               GROUP BY EU.CUTB_SEQ_NBR) elv,
             /* Logging Started */
              (  SELECT A0.CUTB_SEQ_NBR,
                        MAX (
                            DECODE (AT0.actt_key_ind,
                                    'HVC', A0.acti_status_ind,
                                    NULL))    AS HVC_STATUS,
                        MAX (
                            DECODE (AT0.actt_key_ind,
                                    'HVC', A0.acti_target_date,
                                    NULL))    AS HVC_TARGET_DATE,
                        MAX (
                            DECODE (AT0.actt_key_ind,
                                    'HVC', A0.acti_status_date,
                                    NULL))    AS HVC_STATUS_DATE,
                        MAX (
                            DECODE (AT0.actt_key_ind,
                                    'HVS', A0.acti_status_ind,
                                    NULL))    AS HVS_STATUS,
                        MAX (
                            DECODE (AT0.actt_key_ind,
                                    'HVS', A0.acti_target_date,
                                    NULL))    AS HVS_TARGET_DATE,
                        MAX (
                            DECODE (AT0.actt_key_ind,
                                    'HVS', A0.acti_status_date,
                                    NULL))    AS HVS_STATUS_DATE
                   FROM forest.activity_type AT0, forest.activity A0
                  WHERE     AT0.actt_seq_nbr = A0.actt_seq_nbr
                        AND AT0.actt_key_ind IN ('HVC', 'HVS')
                        AND A0.plan_seq_nbr IS NULL
               GROUP BY A0.CUTB_SEQ_NBR) HV,
             /* Seed Zone */
              (  SELECT SP.CUTB_SEQ_NBR,
                        LISTAGG (SP.BLSZ_ZONE_ID || '(' || SP.SPECIES || ')',
                                 ' ')
                        WITHIN GROUP (ORDER BY SP.BLSZ_ZONE_ID)    AS SEED_ZONE
                   FROM (  SELECT BSZ.CUTB_SEQ_NBR,
                                  BSZ.BLSZ_ZONE_ID,
                                  LISTAGG (
                                         BSZ.BLSZ_CLASS_ID
                                      || ':'
                                      || BSZ.BLSZ_SPECIES_ID,
                                      ', ')
                                  WITHIN GROUP (ORDER BY
                                                    BSZ.BLSZ_CLASS_ID,
                                                    BSZ.BLSZ_SPECIES_ID)    AS SPECIES
                             FROM FOREST.BLOCK_SEED_ZONE BSZ
                         GROUP BY BSZ.CUTB_SEQ_NBR, BSZ.BLSZ_ZONE_ID) SP
               GROUP BY SP.CUTB_SEQ_NBR) SZ,
             /* Area weighted site index */
              (  SELECT SILP.CUTB_SEQ_NBR,
                        ROUND (
                            DECODE (
                                SUM (
                                    DECODE (
                                        NVL (STUN.STUN_GROSS_HA_AREA, 0),
                                        0, 0,
                                        DECODE (NVL (STUN.STUN_SITE_INDEX, 0),
                                                0, 0,
                                                STUN.STUN_GROSS_HA_AREA))),
                                0, 0,
                                  SUM (
                                      DECODE (
                                          NVL (STUN.STUN_GROSS_HA_AREA, 0),
                                          0, 0,
                                          DECODE (
                                              NVL (STUN.STUN_SITE_INDEX, 0),
                                              0, 0,
                                                STUN.STUN_GROSS_HA_AREA
                                              * STUN.STUN_SITE_INDEX)))
                                / SUM (
                                      DECODE (
                                          NVL (STUN.STUN_GROSS_HA_AREA, 0),
                                          0, 0,
                                          DECODE (NVL (STUN.STUN_SITE_INDEX, 0),
                                                  0, 0,
                                                  STUN.STUN_GROSS_HA_AREA)))))    SITE_INDEX
                   FROM FOREST.SILVICULTURE_PRESCRIPTION SILP,
                        FOREST.STANDARD_UNIT          STUN
                  WHERE     SILP.SILP_SEQ_NBR = STUN.SILP_SEQ_NBR
                        AND STUN.SUTY_TYPE_ID = 'PROD'
               GROUP BY SILP.CUTB_SEQ_NBR) SI
       WHERE     B.DIVI_DIV_NBR = D.DIVI_DIV_NBR
             AND B.CUTB_SEQ_NBR = BA.CUTB_SEQ_NBR(+)
             AND B.SUOP_SUBOP_AREA_ID = SUOP.SUOP_SUBOP_AREA_ID(+)
             AND B.DIVI_DIV_NBR = SUOP.DIVI_DIV_NBR(+)
             AND B.OPAR_OPERATING_AREA_ID = SUOP.OPAR_OPERATING_AREA_ID(+)
             AND BA.MANU_SEQ_NBR = M.MANU_SEQ_NBR(+)
             AND BA.PERM_SEQ_NBR = P.PERM_SEQ_NBR(+)
             AND BA.MARK_SEQ_NBR = MK.MARK_SEQ_NBR(+)
             AND BA.LICN_SEQ_NBR = L.LICN_SEQ_NBR(+)
             AND L.TENT_SEQ_NBR = TN.TENT_SEQ_NBR(+)
             AND B.DIVI_DIV_NBR = OA.DIVI_DIV_NBR(+)
             AND B.OPAR_OPERATING_AREA_ID = OA.OPAR_OPERATING_AREA_ID(+)
             -- AND B.TREG_SEQ_NBR = STR.TREG_SEQ_NBR (+) -- Old link, replaced with b->cbsr->str.
             AND B.CUTB_SEQ_NBR = cbsr.CUTB_SEQ_NBR(+)  -- Update from Trimble
             AND CBSR.TREG_SEQ_NBR = STR.TREG_SEQ_NBR(+) -- Update from Trimble
             AND str.pers_seq_nbr = per.pers_seq_nbr(+)
             AND B.cutb_seq_nbr = HV.cutb_seq_nbr(+)
             -- And B.cutb_seq_nbr = HVC.cutb_seq_nbr (+)
             AND B.CUTB_SEQ_NBR = elv.CUTB_SEQ_NBR(+)
             AND B.CUTB_SEQ_NBR = SI.CUTB_SEQ_NBR(+)
             AND B.CUTB_SEQ_NBR = sz.CUTB_SEQ_NBR(+)
             AND L.LICN_FIELD_TEAM_ID = COLU.COLU_LOOKUP_ID(+)
             AND COLU.COLU_LOOKUP_TYPE(+) = 'FDTM'
    ORDER BY B.CUTB_SEQ_NBR
