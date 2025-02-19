/* Formatted on 2025/01/08 12:01:36 PM (QP5 v5.417) */
CREATE OR REPLACE FORCE VIEW FOREST.V_LRM_LICENCE_SHAPE
(
    OBJECTID,
    MANU_SEQ_NBR,
    LICN_SEQ_NBR,
    SHAPE,
    SDE_STATE_ID,
    V_TREEFIELD,
    SHAPE_AREA,
    MODIFIEDBY,
    MODIFIEDON,
    MODIFIEDUSING,
    CREATEDBY,
    CREATEDON,
    CREATEDUSING
)
BEQUEATH DEFINER
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
           lcs."SHAPE_AREA",
           lcs.MODIFIEDBY,
           lcs.MODIFIEDON,
           lcs.MODIFIEDUSING,
           lcs.CREATEDBY,
           lcs.CREATEDON,
           lcs.CREATEDUSING
      FROM LICENCE_ALLOCATION  la
           LEFT JOIN LICENCE_SHAPE_EVW lcs
               ON la.licn_seq_nbr = lcs.licn_seq_nbr
           LEFT JOIN LICENCE L ON LA.LICN_SEQ_NBR = L.LICN_SEQ_NBR;


CREATE OR REPLACE TRIGGER FOREST.TD_V_LRM_LICENCE_SHAPE
INSTEAD OF DELETE ON FOREST.V_LRM_LICENCE_SHAPE
FOR EACH ROW
BEGIN
     DELETE FROM LICENCE_SHAPE_EVW
     WHERE OBJECTID = :OLD.OBJECTID;
END;
/


CREATE OR REPLACE TRIGGER FOREST.TI_V_LRM_LICENCE_SHAPE
INSTEAD OF INSERT ON FOREST.V_LRM_LICENCE_SHAPE
FOR EACH ROW
BEGIN
      INSERT INTO LICENCE_SHAPE_EVW (
    OBJECTID,
    LICN_SEQ_NBR,
    MANU_SEQ_NBR,
    SHAPE,
    SDE_STATE_ID,
   SHAPE_AREA,
   MODIFIEDBY,
   MODIFIEDON,
   MODIFIEDUSING,
   CREATEDBY,
   CREATEDON,
   CREATEDUSING
             ) VALUES
             (
             :NEW.OBJECTID,
             :NEW.LICN_SEQ_NBR,
             :NEW.MANU_SEQ_NBR,
             :NEW.SHAPE,
             :NEW.SDE_STATE_ID,
               :NEW.SHAPE_AREA,
               :NEW.MODIFIEDBY,
               :NEW.MODIFIEDON,
               :NEW.MODIFIEDUSING,
               :NEW.CREATEDBY,
               :NEW.CREATEDON,
               :NEW.CREATEDUSING  );
END;
/


CREATE OR REPLACE TRIGGER FOREST.TU_V_LRM_LICENCE_SHAPE
INSTEAD OF UPDATE ON FOREST.V_LRM_LICENCE_SHAPE
FOR EACH ROW
BEGIN
     UPDATE LICENCE_SHAPE_EVW
     SET
             LICN_SEQ_NBR = :NEW.LICN_SEQ_NBR,
             MANU_SEQ_NBR = :NEW.MANU_SEQ_NBR,
             SHAPE = :NEW.SHAPE,
             SDE_STATE_ID = :NEW.SDE_STATE_ID,
           SHAPE_AREA = :NEW.SHAPE_AREA,
           MODIFIEDBY = :NEW.MODIFIEDBY,
           MODIFIEDON =:NEW.MODIFIEDON,
           MODIFIEDUSING =:NEW.MODIFIEDUSING,
           CREATEDBY = :NEW.CREATEDBY,
           CREATEDON = :NEW.CREATEDON,
           CREATEDUSING = :NEW.CREATEDUSING
     WHERE OBJECTID = :OLD.OBJECTID;
END;
/


GRANT SELECT ON FOREST.V_LRM_LICENCE_SHAPE TO BCTS_RO;

GRANT DELETE, INSERT, UPDATE ON FOREST.V_LRM_LICENCE_SHAPE TO TFM_MODIFY_ROLE;

GRANT SELECT ON FOREST.V_LRM_LICENCE_SHAPE TO TFM_VIEW_ROLE;
