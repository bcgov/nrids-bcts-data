CREATE OR REPLACE FUNCTION BCTS_STAGING.SF_CALC_LICENCE_STANDING_AREA(
    a_licn_seq_nbr NUMERIC,
    a_manu_seq_nbr NUMERIC
)
RETURNS NUMERIC AS $$

DECLARE
  ln_result NUMERIC := 0;
  ls_merch_ha_area NUMERIC(21,6) := 0;
  ls_harvested_ha_area NUMERIC(21,6) := 0;
  
BEGIN

  SELECT SUM(COALESCE(blal_merch_ha_area, 0))
  INTO ls_merch_ha_area
  FROM LRM_REPLICATION.block_allocation
  WHERE block_allocation.licn_seq_nbr = a_licn_seq_nbr;
  --    AND block_allocation.manu_seq_nbr = a_manu_seq_nbr;
  SELECT SUM(COALESCE(blal_harvested_ha_area, 0))
  INTO ls_harvested_ha_area
  FROM LRM_REPLICATION.block_allocation
  WHERE block_allocation.licn_seq_nbr = a_licn_seq_nbr;
  --    AND block_allocation.manu_seq_nbr = a_manu_seq_nbr;
  IF ls_merch_ha_area = BCTS_STAGING.SF_CALC_LICENCE_HARV_AREA(a_licn_seq_nbr, a_manu_seq_nbr) THEN
    ln_result := 0;
  ELSIF BCTS_STAGING.SF_CALC_LICENCE_HARV_AREA(a_licn_seq_nbr, a_manu_seq_nbr) > 0 THEN
    ln_result := ls_merch_ha_area - BCTS_STAGING.SF_CALC_LICENCE_HARV_AREA(a_licn_seq_nbr, a_manu_seq_nbr);
  ELSE
    ln_result := ls_merch_ha_area;
  END IF;
  RETURN ln_result;
END;
$$ LANGUAGE plpgsql;
