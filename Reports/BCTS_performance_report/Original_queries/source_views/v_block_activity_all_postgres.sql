
CREATE OR REPLACE VIEW BCTS_STAGING.V_BLOCK_ACTIVITY_ALL
AS SELECT
-- C Johnston - Dec 22 2017 - SQ 18066 - Added FIELD_TEAM_DESC
-- E Luo     -  Apr 12 2017 - SQ 18059 - Added feild uri, LICN_LICENCE_STATE
      d.divi_short_code tso_code,
       d.divi_division_name tso_name,
       m.manu_id nav_name,
       tn.tent_tenure_id tenure,
       l.licn_licence_id licence_id,
		CASE 
			WHEN UPPER(SUBSTRING(p.perm_permit_id FROM 1 FOR 4)) = 'APR-' THEN NULL 
			ELSE p.perm_permit_id 
		END AS permit_id,
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
  FROM lrm_replication.activity_class ac
  INNER JOIN lrm_replication.activity_type ap
	   ON ac.accl_seq_nbr = ap.accl_seq_nbr
       AND ac.divi_div_nbr = ap.divi_div_nbr
	    AND ac.accl_object_type = 'B'
       INNER JOIN lrm_replication.activity a
	     ON a.actt_seq_nbr = ap.actt_seq_nbr
		     AND a.plan_seq_nbr IS NULL
       LEFT JOIN lrm_replication.ctor_contractor c
	   ON a.ctor_seq_nbr = c.ctor_seq_nbr
	    INNER JOIN lrm_replication.cut_block b 
		 ON b.cutb_seq_nbr = a.cutb_seq_nbr
       INNER JOIN lrm_replication.division d
	   ON b.divi_div_nbr = d.divi_div_nbr
	   INNER JOIN lrm_replication.block_allocation ba  
	   ON b.cutb_seq_nbr = ba.cutb_seq_nbr
       LEFT JOIN lrm_replication.management_unit m
	    ON ba.manu_seq_nbr = m.manu_seq_nbr
       LEFT JOIN lrm_replication.licence l
	       ON ba.licn_seq_nbr = l.licn_seq_nbr
       LEFT JOIN lrm_replication.cut_permit p
	     ON ba.perm_seq_nbr = p.perm_seq_nbr
       LEFT JOIN lrm_replication.mark mk
	     ON ba.mark_seq_nbr = mk.mark_seq_nbr
       LEFT JOIN lrm_replication.tenure_type tn
	    ON l.tent_seq_nbr = tn.tent_seq_nbr                  
       LEFT JOIN lrm_replication.V_RES_VT_FDTM_TEAM ft_vt
	    ON l.licn_field_team_id = ft_vt.COLU_LOOKUP_ID
