/* Formatted on 2025/01/08 12:01:36 PM (QP5 v5.417) */
CREATE OR REPLACE VIEW BCTS_STAGING.V_LRM_LICENCE_SHAPE
AS
    SELECT /*
                           V1.1     2018-05-30      JZHOU       SQ18387     Added V_TREEFIELD field
                           V2.0    MXIAN       2020-10-26      SQ19482     Add fields: created%, modified%, shape_area
                           V3.0    D.sabatino   2020-12-08      SQ19601    Pull Manu_seq_nbr from the allocation table.
                           */
           lcs.OBJECTID,
           la.MANU_SEQ_NBR,
           lcs.LICN_SEQ_NBR,
           lcs.SHAPE,
           lcs.SDE_STATE_ID,
           'Licence Shape - ' || l.LICN_LICENCE_ID,
           lcs.SHAPE_AREA,
           lcs.MODIFIEDBY,
           lcs.MODIFIEDON,
           lcs.MODIFIEDUSING,
           lcs.CREATEDBY,
           lcs.CREATEDON,
           lcs.CREATEDUSING
      FROM LRM_REPLICATION.LICENCE_ALLOCATION  la
           LEFT JOIN LRM_REPLICATION.LICENCE_SHAPE_EVW lcs
               ON la.licn_seq_nbr = lcs.licn_seq_nbr
           LEFT JOIN LRM_REPLICATION.LICENCE L ON LA.LICN_SEQ_NBR = L.LICN_SEQ_NBR;


