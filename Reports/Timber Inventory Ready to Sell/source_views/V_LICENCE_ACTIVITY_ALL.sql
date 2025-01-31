/* Formatted on 2025/01/31 2:09:39 PM (QP5 v5.417) */
CREATE OR REPLACE FORCE VIEW FORESTVIEW.V_LICENCE_ACTIVITY_ALL
(
    DIVI_DIV_NBR,
    TSO_CODE,
    FIELD_TEAM_DESC,
    NAV_NAME,
    TENURE,
    LICENCE_ID,
    LICN_LICENCE_STATE,
    ACTIVITY_CLASS,
    ACTIVITY_TYPE,
    ACTT_KEY_IND,
    ACCL_OBJECT_TYPE,
    ACTI_RESPONSIBILITY,
    ACTI_STATUS_IND,
    ACTI_TARGET_DATE,
    ACTI_TARGET_COST,
    ACTIVITY_DATE,
    ACTI_STATUS_DATE,
    ACTI_COST,
    ACTI_COMMENTS,
    LICENSEE,
    ACTI_SEQ_NBR,
    LICN_SEQ_NBR,
    MODIFIEDBY,
    MODIFIEDON,
    CREATEDBY,
    CREATEDON
)
BEQUEATH DEFINER
AS
    SELECT d.divi_div_nbr,
           d.divi_short_code         AS tso_code,
           COLU.COLU_LOOKUP_DESC     AS FIELD_TEAM_DESC,
           mu.manu_id                AS nav_name,
           t.tent_tenure_id          AS tenure,
           l.licn_licence_id         AS licence_id,
           l.licn_licence_state,
           ac.accl_description       AS activity_class,
           ap.actt_description       AS activity_type,
           ap.actt_key_ind,
           ac.accl_object_type,
           a.acti_responsibility,
           acti_status_ind,
           a.acti_target_date,
           a.acti_target_cost,
           a.acti_status_date        AS activity_date,
           acti_status_date,
           a.acti_cost,
           a.acti_comments,
           ctor.ctor_name            AS Licensee,
           a.acti_seq_nbr,
           a.licn_seq_nbr,
           a.modifiedby,
           a.modifiedon,
           a.createdby,
           a.createdon
      FROM forest.activity_class      ac,
           forest.activity_type       ap,
           forest.activity            a,
           forest.licence             l,
           forest.ctor_contractor     ctor,
           forest.licence_allocation  la,
           forest.management_unit     mu,
           forest.division            d,
           forest.tenure_type         t,
           FOREST.CODE_LOOKUP         COLU
     WHERE     ac.accl_object_type = 'L'
           AND ac.accl_seq_nbr = ap.accl_seq_nbr
           AND ac.divi_div_nbr = ap.divi_div_nbr
           AND a.actt_seq_nbr = ap.actt_seq_nbr
           AND a.licn_seq_nbr = l.licn_seq_nbr
           AND l.ctor_seq_nbr = ctor.ctor_seq_nbr(+)
           AND l.licn_seq_nbr = la.licn_seq_nbr
           AND la.manu_seq_nbr = mu.manu_seq_nbr(+)
           AND l.divi_div_nbr = d.divi_div_nbr
           AND l.tent_seq_nbr = t.tent_seq_nbr(+)
           AND L.LICN_FIELD_TEAM_ID = COLU.COLU_LOOKUP_ID(+)
           AND COLU.COLU_LOOKUP_TYPE(+) = 'FDTM';


GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO BCTS_ALL_OBJECTS_RO;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO BCTS_RO;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO FOREST_PROG;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO FOREST_VIEW;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO FOREST_XX;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO GENUS_BCGW_DATA_REPLICATION;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO LRMBCTS_REPORTING_TOOL;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO MAP_VIEW;

GRANT SELECT ON FORESTVIEW.V_LICENCE_ACTIVITY_ALL TO TFM_VIEW_ROLE;
