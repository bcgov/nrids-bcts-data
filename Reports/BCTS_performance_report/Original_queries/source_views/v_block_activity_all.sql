--------------------------------------------------------
--  File created - Tuesday-December-10-2024   
--------------------------------------------------------
-- Unable to render VIEW DDL for object FORESTVIEW.V_BLOCK_ACTIVITY_ALL with DBMS_METADATA attempting internal generator.
CREATE VIEW FORESTVIEW.V_BLOCK_ACTIVITY_ALL
AS SELECT
-- C Johnston - Dec 22 2017 - SQ 18066 - Added FIELD_TEAM_DESC
-- E Luo     -  Apr 12 2017 - SQ 18059 - Added feild uri, LICN_LICENCE_STATE
      d.divi_short_code tso_code,
       d.divi_division_name tso_name,
       m.manu_id nav_name,
       tn.tent_tenure_id tenure,
       l.licn_licence_id licence_id,
       DECODE (UPPER (SUBSTR (p.perm_permit_id, 1, 4)),
               'APR-', NULL,
               p.perm_permit_id)
          AS permit_id,
       mk.mark_mark_id mark_id,
       b.cutb_block_id block_id,
       b.cutb_block_number block_nbr,
       a.cutb_seq_nbr,
       a.acti_seq_nbr,
       l.licn_seq_nbr,
       ap.actt_seq_nbr,
       ac.accl_description activity_class,
       ap.actt_description activity_type,
       ap.actt_key_ind,
       a.acti_status_date activity_date,
       a.acti_status_ind,
       ac.accl_object_type,
       a.acti_responsibility,
       c.ctor_name,
       a.acti_cost,
       a.acti_target_date,
       a.acti_target_cost,
       a.acti_comments,
       d.divi_div_nbr,
       ft_vt.COLU_LOOKUP_DESC,
        b.cutb_system_id ubi,
       l.licn_licence_state
  FROM forest.activity_class ac,
       forest.activity_type ap,
       forest.activity a,
       forest.ctor_contractor c,
       forest.division d,
       forest.management_unit m,
       forest.licence l,
       forest.cut_permit p,
       forest.mark mk,
       forest.tenure_type tn,
       forest.cut_block b,                                    -- select * from
       forest.block_allocation ba,                            -- select * from
       FOREST.V_RES_VT_FDTM_TEAM ft_vt
   WHERE     b.cutb_seq_nbr = ba.cutb_seq_nbr
       AND b.divi_div_nbr = d.divi_div_nbr
       AND ba.manu_seq_nbr = m.manu_seq_nbr(+)
       AND ba.licn_seq_nbr = l.licn_seq_nbr(+)
       AND ba.perm_seq_nbr = p.perm_seq_nbr(+)
       AND ba.mark_seq_nbr = mk.mark_seq_nbr(+)
       AND l.tent_seq_nbr = tn.tent_seq_nbr(+)
       AND b.cutb_seq_nbr = a.cutb_seq_nbr
       AND ac.accl_seq_nbr = ap.accl_seq_nbr
       AND ac.divi_div_nbr = ap.divi_div_nbr
       AND a.actt_seq_nbr = ap.actt_seq_nbr
       AND a.ctor_seq_nbr = c.ctor_seq_nbr(+)
       AND l.licn_field_team_id = ft_vt.COLU_LOOKUP_ID(+)
       AND ac.accl_object_type = 'B'
       AND a.plan_seq_nbr IS NULL
