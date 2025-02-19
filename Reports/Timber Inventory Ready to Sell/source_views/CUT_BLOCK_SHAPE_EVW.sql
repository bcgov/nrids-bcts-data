--------------------------------------------------------
--  File created - Wednesday-February-05-2025   
--------------------------------------------------------
-- Unable to render VIEW DDL for object FOREST.CUT_BLOCK_SHAPE_EVW with DBMS_METADATA attempting internal generator.
CREATE VIEW FOREST.CUT_BLOCK_SHAPE_EVW
AS SELECT 
        b.OBJECTID,
        b.TRANSACTION_ID,
        b.CUTB_SEQ_NBR,
        b.BUFFERDIST,
        b.OBJECTID_1,
        b.TRANSACTIO,
        b.OBJECTID_2,
        b.HECTARES,
        b.FEATURE_LEN,
        b.FEATURE_AREA,
        b.SHAPE_LEN,
        b.SHAPE_AREA,
        b.SHAPE,
        b.LICN_SEQ_NBR,
        b.MANU_SEQ_NBR,
        b.MARK_SEQ_NBR,
        b.PERM_SEQ_NBR,
        b.MODIFIEDBY,
        b.MODIFIEDON,
        b.MODIFIEDUSING,
        b.CREATEDBY,
        b.CREATEDON,
        b.CREATEDUSING,
        0 SDE_STATE_ID 
FROM 
    FOREST.CUT_BLOCK_SHAPE b,
        (SELECT SDE_DELETES_ROW_ID,SDE_STATE_ID 
        FROM FOREST.D29082 
        WHERE SDE_STATE_ID = 0 AND 
            SDE.version_util.in_current_lineage (DELETED_AT) > 0) 
    d 
WHERE 
    b.OBJECTID = d.SDE_DELETES_ROW_ID(+) AND 
    d.SDE_STATE_ID IS NULL  AND 
    SDE.version_util.get_lineage_list > 0 
UNION ALL 
    SELECT 
        a.OBJECTID,
        a.TRANSACTION_ID,
        a.CUTB_SEQ_NBR,
        a.BUFFERDIST,
        a.OBJECTID_1,
        a.TRANSACTIO,
        a.OBJECTID_2,
        a.HECTARES,
        a.FEATURE_LEN,
        a.FEATURE_AREA,
        a.SHAPE_LEN,
        a.SHAPE_AREA,
        a.SHAPE,
        a.LICN_SEQ_NBR,
        a.MANU_SEQ_NBR,
        a.MARK_SEQ_NBR,
        a.PERM_SEQ_NBR,
        a.MODIFIEDBY,
        a.MODIFIEDON,
        a.MODIFIEDUSING,
        a.CREATEDBY,
        a.CREATEDON,
        a.CREATEDUSING,
        a.SDE_STATE_ID 
    FROM 
        FOREST.A29082 a,
            (SELECT SDE_DELETES_ROW_ID,SDE_STATE_ID 
            FROM FOREST.D29082 
            WHERE SDE.version_util.in_current_lineage (DELETED_AT) > 0) 
        d 
    WHERE a.OBJECTID = d.SDE_DELETES_ROW_ID(+) AND 
    a.SDE_STATE_ID = d.SDE_STATE_ID(+) AND 
    SDE.version_util.in_current_lineage (a.SDE_STATE_ID) > 0 AND 
    d.SDE_STATE_ID IS NULL
