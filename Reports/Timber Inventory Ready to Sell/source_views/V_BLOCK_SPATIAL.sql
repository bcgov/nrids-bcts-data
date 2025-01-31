/* Formatted on 2025/01/31 2:08:33 PM (QP5 v5.417) */
CREATE OR REPLACE FORCE VIEW FORESTVIEW.V_BLOCK_SPATIAL
(
    TSO_CODE,
    NAV_NAME,
    LICENCE_ID,
    PERMIT_ID,
    MARK_ID,
    BLOCK_ID,
    CUTB_SEQ_NBR,
    SPATIAL_FLAG
)
BEQUEATH DEFINER
AS
    SELECT D.DIVI_SHORT_CODE                               AS TSO_CODE,
           M.MANU_ID                                       AS NAV_NAME,
           L.LICN_LICENCE_ID                               AS LICENCE_ID,
           DECODE (UPPER (SUBSTR (P.PERM_PERMIT_ID, 1, 4)),
                   'APR-', NULL,
                   P.PERM_PERMIT_ID)                       AS PERMIT_ID,
           MK.MARK_MARK_ID                                 AS MARK_ID,
           B.CUTB_BLOCK_ID                                 AS BLOCK_ID,
           B.CUTB_SEQ_NBR,
           DECODE (BLK.cutb_seq_nbr, NULL, 'NO', 'YES')    AS SPATIAL_FLAG
      FROM FOREST.DIVISION             D,
           FOREST.MANAGEMENT_UNIT      M,
           FOREST.LICENCE              L,
           FOREST.CUT_PERMIT           P,
           FOREST.MARK                 MK,
           FOREST.CUT_BLOCK            B,
           FOREST.BLOCK_ALLOCATION     BA,
           FOREST.CUT_BLOCK_SHAPE_EVW  BLK
     WHERE     b.cutb_seq_nbr = ba.cutb_seq_nbr(+)
           AND b.divi_div_nbr = d.divi_div_nbr(+)
           AND ba.manu_seq_nbr = m.manu_seq_nbr(+)
           AND ba.licn_seq_nbr = l.licn_seq_nbr(+)
           AND ba.perm_seq_nbr = p.perm_seq_nbr(+)
           AND ba.mark_seq_nbr = mk.mark_seq_nbr(+)
           AND B.CUTB_SEQ_NBR = BLK.CUTB_SEQ_NBR(+);


GRANT SELECT ON FORESTVIEW.V_BLOCK_SPATIAL TO BCTS_ALL_OBJECTS_RO;

GRANT SELECT ON FORESTVIEW.V_BLOCK_SPATIAL TO BCTS_RO;

GRANT SELECT ON FORESTVIEW.V_BLOCK_SPATIAL TO FOREST_VIEW;

GRANT SELECT ON FORESTVIEW.V_BLOCK_SPATIAL TO LRMBCTS_REPORTING_TOOL;

GRANT SELECT ON FORESTVIEW.V_BLOCK_SPATIAL TO MAP_VIEW;

GRANT SELECT ON FORESTVIEW.V_BLOCK_SPATIAL TO TFM_VIEW_ROLE;
