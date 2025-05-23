--------------------------------------------------------
--  File created - Tuesday-December-10-2024   
--------------------------------------------------------
-- Unable to render VIEW DDL for object FORESTVIEW.V_LICENCE with DBMS_METADATA attempting internal generator.
CREATE VIEW FORESTVIEW.V_LICENCE
AS SELECT DISTINCT
--MXIAN  2022-09-22 SQ19820 update logic of REMAIN_COMMIT_VOLUME
           L.LICN_SEQ_NBR,
           L.TENT_SEQ_NBR,
           L.CTOR_SEQ_NBR,
           L.CLOC_SEQ_NBR,
           D.DIVI_SHORT_CODE
               TSO_CODE,
           D.DIVI_DIVISION_NAME
               TSO_NAME,
           M.MANU_ID
               NAV_NAME,
           L.LICN_LICENCE_ID
               LICENCE_ID,
           LK.COLU_LOOKUP_DESC
               CATEGORY,
           TN.TENT_TENURE_ID
               TENURE,
           L.LSEE_LICENSEE_ID
               LICENSEE,
           CT.CTOR_NAME
               REGISTRANT,
           CL.CLOC_CITY
               REGISTRANT_CITY,
           LKF.COLU_LOOKUP_DESC
               FIELD_TEAM,
           P.DISTRICT_NAME,
           L.DIVI_DIV_NBR,
           L.LICN_CATEGORY_ID,
           L.BLAZ_ADMIN_ZONE_ID,
           BZ.BLAZ_ADMIN_ZONE_DESC,
           L.LICN_LICENCE_STATE,
           L.LICN_LICENCE_DESC,
           L.LICN_LICENCE_TO_CUT_CODE,
           L.LINC_CERT_LEVEL_ID,
           L.LICN_DIGI_IND,
           L.LICN_SALVAGE_IND,
           L.LICN_APPORTION_TENURE_TYPE,
           (SELECT CASE
                       WHEN DISPO_AGREEMENT IS NOT NULL
                       THEN
                              APPO_TENURE_TYPE
                           || '-'
                           || DISPO_AGREEMENT
                       ELSE
                           APPO_TENURE_TYPE
                   END
              FROM FOREST.APPORTIONMENT
             WHERE CM.COPA_COMMIT_APPO = APPO_SEQ_NBR(+))
               AS APPORTION_TYPE,
           PRTN.COLU_LOOKUP_DESC
               AS PARTITION_TYPE,
           (SELECT DESCRIPTION
              FROM FOREST.LRM_VT_COMMIT_LIC_TYPE
             WHERE CM.COPA_COMMIT_LIC_TYPE = CODE(+))
               AS COMMIT_LICENCE_TYPE,
           P.SUM_COPA_COMMIT_M3_VOL
               AS COMMIT_VOLUME,
           ROUND (BLAL_CALC.CRUISE_VOLUME + BLAL_CALC.REMAIN_VOLUME - SL.SUM_LIC_COPA_COMMIT_M3_VOL)
               AS REMAIN_COMMIT_VOLUME,
           HH.BCHH_BILLING_YEAR  AS BCHH_BILLING_YEAR,
           M.MANU_SEQ_NBR
      FROM FOREST.DIVISION                  D,
           FOREST.MANAGEMENT_UNIT           M,
           FOREST.LICENCE                   L,
           FOREST.LICENCE_ALLOCATION        LA,
           FOREST.TENURE_TYPE               TN,
           FOREST.CTOR_CONTRACTOR           CT,
           FOREST.CTOR_CONTRACTOR_LOCATION  CL,
           FOREST.CODE_LOOKUP               LK,
           FOREST.CODE_LOOKUP               LKF,
           FOREST.CODE_LOOKUP               PRTN,
           (  SELECT B.LICN_SEQ_NBR,
                     MAX (A.ADMIN_DSCT_DISTRICT_NAME)     AS DISTRICT_NAME
                FROM FOREST.CUT_PERMIT A, FOREST.PERMIT_ALLOCATION B
               WHERE A.PERM_SEQ_NBR = B.PERM_SEQ_NBR
            GROUP BY B.LICN_SEQ_NBR) P,
           FOREST.BLOCK_ADMIN_ZONE          BZ,
           FOREST.V_LRM_COMMITMENTS         CM,
           (  SELECT  LISTAGG( BHH.BCHH_BILLING_YEAR,', ') WITHIN GROUP (ORDER BY MA.LICN_SEQ_NBR ) BCHH_BILLING_YEAR,
                     MA.LICN_SEQ_NBR                 AS LICN_SEQ_NBR
                FROM (SELECT DISTINCT BCHH_BILLING_YEAR, MARK_SEQ_NBR FROM FOREST.BCTS_HARVEST_HISTORY) BHH,
                     FOREST.MARK                M,
                     FOREST.MARK_ALLOCATION     MA
               WHERE     BHH.MARK_SEQ_NBR = M.MARK_SEQ_NBR
                     AND M.MARK_SEQ_NBR = MA.MARK_SEQ_NBR
                     GROUP BY MA.LICN_SEQ_NBR
           ) HH,
           (  SELECT SUM (COPA_COMMIT_M3_VOL)     SUM_LIC_COPA_COMMIT_M3_VOL,
                     LICN_SEQ_NBR
                FROM FOREST.COMMITMENT_PARTITION CP, FOREST.COMMITMENTS C
               WHERE CP.COMMIT_SEQ_NBR = C.COMMIT_SEQ_NBR
            GROUP BY LICN_SEQ_NBR) SL,
           (  SELECT SUM (NVL (BLAL_CRUISE_M3_VOL, 0))     CRUISE_VOLUME,
                     SUM (NVL (BLAL_RW_VOL,0)) REMAIN_VOLUME,
                     LICN_SEQ_NBR
                FROM FOREST.BLOCK_ALLOCATION
            GROUP BY LICN_SEQ_NBR) BLAL_CALC,
           (  SELECT SUM (COPA_COMMIT_M3_VOL)     SUM_COPA_COMMIT_M3_VOL,
                     COMMIT_SEQ_NBR
                FROM FOREST.COMMITMENT_PARTITION
            GROUP BY COMMIT_SEQ_NBR) P
     WHERE     D.DIVI_DIV_NBR = L.DIVI_DIV_NBR
           AND L.LICN_SEQ_NBR = LA.LICN_SEQ_NBR
           AND LA.MANU_SEQ_NBR = M.MANU_SEQ_NBR(+)
           AND L.LICN_CATEGORY_ID = LK.COLU_LOOKUP_ID(+)
           AND LK.COLU_LOOKUP_TYPE(+) = 'LICA'
           AND L.TENT_SEQ_NBR = TN.TENT_SEQ_NBR(+)
           AND L.CTOR_SEQ_NBR = CT.CTOR_SEQ_NBR(+)
           AND L.CLOC_SEQ_NBR = CL.CTOR_SEQ_NBR(+)
           AND L.CTOR_SEQ_NBR = CL.CLOC_SEQ_NBR(+)
           AND L.LICN_FIELD_TEAM_ID = LKF.COLU_LOOKUP_ID(+)
           AND LKF.COLU_LOOKUP_TYPE(+) = 'FDTM'
           AND LA.LICN_SEQ_NBR = P.LICN_SEQ_NBR(+)
           AND L.DIVI_DIV_NBR = BZ.DIVI_DIV_NBR(+)
           AND L.BLAZ_ADMIN_ZONE_ID = BZ.BLAZ_ADMIN_ZONE_ID(+)
           AND L.LICN_SEQ_NBR = CM.LICN_SEQ_NBR(+)
           AND PRTN.COLU_LOOKUP_TYPE(+) = 'PRTN'
           AND CM.COPA_PARTITION = PRTN.COLU_LOOKUP_ID(+)
           AND L.LICN_SEQ_NBR = HH.LICN_SEQ_NBR(+)
           AND L.LICN_SEQ_NBR = SL.LICN_SEQ_NBR(+)
           AND L.LICN_SEQ_NBR = BLAL_CALC.LICN_SEQ_NBR(+)
           AND CM.COMMIT_SEQ_NBR = P.COMMIT_SEQ_NBR(+)
