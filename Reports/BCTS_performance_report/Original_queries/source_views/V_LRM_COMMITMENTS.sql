-- Unable to render VIEW DDL for object FOREST.V_LRM_COMMITMENTS with DBMS_METADATA attempting internal generator.
CREATE VIEW FOREST.V_LRM_COMMITMENTS
AS SELECT /********************************************************************
                      NAME: V_LRM_COMMITMENTS
                      Used for the Commitments Context

                      Revision History
                      -KJEANS Feb 13, 2019 -SQ18965 created
                      -KJEANS MAR 6, 2019 - SQ19002 ADD MANU_SEQ_NBR , calculate the Comitment Voume from the Partition Commitments
                      -KJEANS MAR 8, 2019 -SQ19002 addd calculation for Remaining Volume to Commit
                      -MB     MAR 21, 2019 -SQ19002 add COPA_COMMIT_LIC_TYPE
                      --DS    Oct 04,2022 - SQ 19821 - updated V_REMAIN_COMMIT_M3_VOL calculation
               ********************************************************************/
  C.LICN_SEQ_NBR,
           C.COMMIT_SEQ_NBR,
           C.COPA_PARTITION,
           C.COPA_COMMIT_APPO,
           P.SUM_COPA_COMMIT_M3_VOL                AS V_COPA_COMMIT_M3_VOL,
           ROUND (
                (BLAL_CALC.CRUISE_VOLUME
               + BLAL_CALC.REMAIN_VOLUME)
               - SL.SUM_LIC_COPA_COMMIT_M3_VOL)    AS V_REMAIN_COMMIT_M3_VOL,
           C.MODIFIEDBY,
           C.MODIFIEDON,
           C.MODIFIEDUSING,
           C.CREATEDBY,
           C.CREATEDON,
           C.CREATEDUSING,
           C.MANU_SEQ_NBR,
           C.COPA_COMMIT_LIC_TYPE
      FROM FOREST.COMMITMENTS    C,
           FOREST.V_LRM_LICENCE  L,
           (  SELECT SUM (COPA_COMMIT_M3_VOL)     SUM_COPA_COMMIT_M3_VOL,
                     COMMIT_SEQ_NBR               AS P_COMMIT_SEQ_NBR
                FROM COMMITMENT_PARTITION
            GROUP BY COMMIT_SEQ_NBR) P,
           (  SELECT SUM (NVL (COPA_COMMIT_M3_VOL, 0))
                         SUM_LIC_COPA_COMMIT_M3_VOL,
                     LICN_SEQ_NBR
                         AS LICN_SEQ_NBR
                FROM COMMITMENT_PARTITION CP, COMMITMENTS C
               WHERE CP.COMMIT_SEQ_NBR = C.COMMIT_SEQ_NBR
            GROUP BY LICN_SEQ_NBR) SL,
--           (  SELECT SUM (NVL (V_BLAL_RW_VOL, 0))     SUM_LIC_COPA_RW_VOL,
--                     CP.COMMIT_SEQ_NBR                AS COMMIT_SEQ_NBR
--                FROM FOREST.V_LRM_COMMITMENT_PARTITION CP, FOREST.COMMITMENTS C
--               WHERE CP.COMMIT_SEQ_NBR = C.COMMIT_SEQ_NBR
--            GROUP BY CP.COMMIT_SEQ_NBR) SRW,
         (  SELECT SUM (NVL (BLAL_CRUISE_M3_VOL, 0))     CRUISE_VOLUME,
                     SUM (NVL (BLAL_RW_VOL, 0))            REMAIN_VOLUME,
                     LICN_SEQ_NBR
                FROM FOREST.BLOCK_ALLOCATION
            GROUP BY LICN_SEQ_NBR) BLAL_CALC
     WHERE     C.LICN_SEQ_NBR = L.LICN_SEQ_NBR
           AND P.P_COMMIT_SEQ_NBR(+) = C.COMMIT_SEQ_NBR
           AND SL.LICN_SEQ_NBR(+) = L.LICN_SEQ_NBR
          -- AND SRW.COMMIT_SEQ_NBR(+) = C.COMMIT_SEQ_NBR
           AND BLAL_CALC.LICN_SEQ_NBR = L.LICN_SEQ_NBR
