
CREATE OR REPLACE VIEW BCTS_STAGING.V_BLOCK AS
SELECT D.DIVI_DIV_NBR,
             D.DIVI_SHORT_CODE                         AS TSO_CODE,
             D.DIVI_DIVISION_NAME                      AS TSO_NAME,
             COLU.COLU_LOOKUP_DESC                     AS FIELD_TEAM_DESC,
             M.MANU_ID                                 AS NAV_NAME,
             TN.TENT_TENURE_ID                         AS TENURE,
             L.LICN_LICENCE_ID                         AS LICENCE_ID,
			 CASE 
				 WHEN UPPER(SUBSTRING(P.PERM_PERMIT_ID FROM 1 FOR 4)) = 'APR-' THEN NULL 
				 ELSE P.PERM_PERMIT_ID 
			 END AS PERMIT_ID,
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
             (  COALESCE (BA.BLAL_MERCH_HA_AREA, 0)
              - COALESCE (BA.BLAL_HARVESTED_HA_AREA, 0))    AS REMAINING_AREA,
             BA.BLAL_CRUISE_M3_VOL                     AS CRUISE_VOL,
             BA.BLAL_DATA_SOURCE                       AS DATA_SOURCE,
             BA.BLAL_HARVESTED_M3_VOL                  AS HARVEST_VOL,
             (  COALESCE (BA.BLAL_CRUISE_M3_VOL, 0)
              - COALESCE (BA.BLAL_HARVESTED_M3_VOL, 0))     AS REMAINING_VOL,
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
        FROM LRM_REPLICATION.CUT_BLOCK            B
		 INNER JOIN LRM_REPLICATION.DIVISION             D
		 ON B.DIVI_DIV_NBR = D.DIVI_DIV_NBR
		 LEFT JOIN LRM_REPLICATION.BLOCK_ALLOCATION     BA
		 ON B.CUTB_SEQ_NBR = BA.CUTB_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.MANAGEMENT_UNIT      M
		 ON BA.MANU_SEQ_NBR = M.MANU_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.LICENCE              L
		 ON BA.LICN_SEQ_NBR = L.LICN_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.TENURE_TYPE          TN
		 ON L.TENT_SEQ_NBR = TN.TENT_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.CUT_PERMIT           P
		 ON BA.PERM_SEQ_NBR = P.PERM_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.MARK                 MK
		 ON BA.MARK_SEQ_NBR = MK.MARK_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.OPERATING_AREA       OA
		 ON B.DIVI_DIV_NBR = OA.DIVI_DIV_NBR
		 LEFT JOIN LRM_REPLICATION.CUT_BLOCK_SILV_REGIME CBSR
		 ON B.CUTB_SEQ_NBR = CBSR.CUTB_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.SILV_TREATMENT_REGIME STR
		 ON CBSR.TREG_SEQ_NBR = STR.TREG_SEQ_NBR
		 LEFT JOIN LRM_REPLICATION.CODE_LOOKUP          COLU
		 ON L.LICN_FIELD_TEAM_ID = COLU.COLU_LOOKUP_ID
             AND COLU.COLU_LOOKUP_TYPE = 'FDTM'
		 LEFT JOIN LRM_REPLICATION.SUB_OPERATING_AREA   SUOP
		 ON B.SUOP_SUBOP_AREA_ID = SUOP.SUOP_SUBOP_AREA_ID
             AND B.DIVI_DIV_NBR = SUOP.DIVI_DIV_NBR
             AND B.OPAR_OPERATING_AREA_ID = SUOP.OPAR_OPERATING_AREA_ID
		 LEFT JOIN LRM_REPLICATION.PERSON               PER
		 ON STR.PERS_SEQ_NBR = PER.PERS_SEQ_NBR
		 LEFT JOIN 
		 (
			   /* Logging Started */
              SELECT A0.CUTB_SEQ_NBR,
				MAX (
				CASE 
					WHEN AT0.actt_key_ind = 'HVC' THEN A0.acti_status_ind
					ELSE NULL
				END) AS HVC_STATUS,
				
				MAX(
				CASE 
					WHEN AT0.actt_key_ind = 'HVC' THEN A0.acti_target_date
					ELSE NULL
				END
				) AS HVC_TARGET_DATE,
			
				MAX(
				CASE 
					WHEN AT0.actt_key_ind = 'HVC' THEN A0.acti_status_date
					ELSE NULL
				END
				) AS HVC_STATUS_DATE,
			
				MAX(
				CASE 
					WHEN AT0.actt_key_ind = 'HVS' THEN A0.acti_status_ind
					ELSE NULL
				END
				) AS HVS_STATUS,
			
				MAX(
				CASE 
					WHEN AT0.actt_key_ind = 'HVS' THEN A0.acti_target_date
					ELSE NULL
				END
				) AS HVS_TARGET_DATE,
			
				MAX(
				CASE 
					WHEN AT0.actt_key_ind = 'HVS' THEN A0.acti_status_date
					ELSE NULL
				END
				) AS HVS_STATUS_DATE
			
			FROM LRM_REPLICATION.activity_type AT0
            INNER JOIN LRM_REPLICATION.activity A0
			ON AT0.actt_seq_nbr = A0.actt_seq_nbr
				AND AT0.actt_key_ind IN ('HVC', 'HVS')
				AND A0.plan_seq_nbr IS NULL
			GROUP BY A0.CUTB_SEQ_NBR) HV
		 ON B.cutb_seq_nbr = HV.cutb_seq_nbr
		 LEFT JOIN 
		 /* Elevation */
			(  SELECT EU.CUTB_SEQ_NBR,
					MIN (EU.ECOU_ELEVATION_MIN)     AS MIN_ELEVATION,
					MAX (EU.ECOU_ELEVATION_MAX)     AS MAX_ELEVATION
			   FROM LRM_REPLICATION.ECOLOGY_UNIT EU
			GROUP BY EU.CUTB_SEQ_NBR) ELV
		 ON B.CUTB_SEQ_NBR = ELV.CUTB_SEQ_NBR
		 LEFT JOIN
		  /* Area weighted site index */
		(  SELECT 
			SILP.CUTB_SEQ_NBR,
			ROUND(
			CASE
				WHEN SUM(
						CASE 
							WHEN COALESCE(STUN.STUN_GROSS_HA_AREA, 0) = 0 THEN 0
							WHEN COALESCE(STUN.STUN_SITE_INDEX, 0) = 0 THEN 0
							ELSE STUN.STUN_GROSS_HA_AREA
						END
					) = 0 THEN 0
				ELSE 
					SUM(
						CASE 
							WHEN COALESCE(STUN.STUN_GROSS_HA_AREA, 0) = 0 THEN 0
							WHEN COALESCE(STUN.STUN_SITE_INDEX, 0) = 0 THEN 0
							ELSE STUN.STUN_GROSS_HA_AREA * STUN.STUN_SITE_INDEX
						END
					)
					/ 
					SUM(
						CASE 
							WHEN COALESCE(STUN.STUN_GROSS_HA_AREA, 0) = 0 THEN 0
							WHEN COALESCE(STUN.STUN_SITE_INDEX, 0) = 0 THEN 0
							ELSE STUN.STUN_GROSS_HA_AREA
						END
					)
			END, 
			1
			) AS SITE_INDEX
		FROM LRM_REPLICATION.SILVICULTURE_PRESCRIPTION SILP
		INNER JOIN LRM_REPLICATION.STANDARD_UNIT          STUN
		ON     SILP.SILP_SEQ_NBR = STUN.SILP_SEQ_NBR
			AND STUN.SUTY_TYPE_ID = 'PROD'
		GROUP BY SILP.CUTB_SEQ_NBR) SI
		 ON B.CUTB_SEQ_NBR = SI.CUTB_SEQ_NBR
		 LEFT JOIN
		 /* Seed Zone */
             (
		SELECT SP.CUTB_SEQ_NBR,
		STRING_AGG(SP.BLSZ_ZONE_ID || '(' || SP.SPECIES || ')', ' ' ORDER BY SP.BLSZ_ZONE_ID) AS SEED_ZONE
		FROM (  SELECT BSZ.CUTB_SEQ_NBR,
			  BSZ.BLSZ_ZONE_ID,
			  STRING_AGG(
				BSZ.BLSZ_CLASS_ID::TEXT || ':' || BSZ.BLSZ_SPECIES_ID::TEXT,
				', '
				ORDER BY BSZ.BLSZ_CLASS_ID, BSZ.BLSZ_SPECIES_ID
				) AS SPECIES
		
		 FROM LRM_REPLICATION.BLOCK_SEED_ZONE BSZ
		 GROUP BY BSZ.CUTB_SEQ_NBR, BSZ.BLSZ_ZONE_ID) SP
		GROUP BY SP.CUTB_SEQ_NBR
			 ) SZ
		ON B.CUTB_SEQ_NBR = SZ.CUTB_SEQ_NBR

ORDER BY B.CUTB_SEQ_NBR;
