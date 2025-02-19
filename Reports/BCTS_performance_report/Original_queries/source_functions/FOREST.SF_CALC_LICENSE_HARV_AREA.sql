CREATE OR REPLACE FUNCTION BCTS_STAGING.SF_CALC_LICENCE_HARV_AREA (
	a_licn_seq_nbr		NUMERIC,
    a_manu_seq_nbr		NUMERIC
)
RETURNS NUMERIC AS $$

DECLARE
    ln_result NUMERIC := 0;
    ls_merch_ha_area NUMERIC(21,6) := 0;
    ls_harvested_ha_area NUMERIC(21,6) := 0;
    ls_cruise_m3_vol NUMERIC(21,6) := 0;
    ls_harvested_m3_vol NUMERIC(21,6) := 0;

BEGIN

    SELECT
    SUM(COALESCE(blal_merch_ha_area, 0)) AS merch_ha_area,
    SUM(COALESCE(blal_harvested_ha_area, 0)) AS harvested_ha_area,
    SUM(COALESCE(blal_cruise_m3_vol, 0)) AS cruise_m3_vol,
    SUM(COALESCE(blal_harvested_m3_vol, 0)) AS harvested_m3_vol
    INTO ls_merch_ha_area, ls_harvested_ha_area, ls_cruise_m3_vol, ls_harvested_m3_vol
    FROM LRM_REPLICATION.block_allocation
    WHERE licn_seq_nbr = a_licn_seq_nbr;


    IF ls_harvested_ha_area > 0 THEN 
        ln_result := ls_harvested_ha_area;
    ELSIF ls_merch_ha_area > 0 AND ls_cruise_m3_vol > 0 THEN 
        ln_result := ls_harvested_m3_vol / (ls_cruise_m3_vol / ls_merch_ha_area);
    ELSE ln_result := 0;
    END IF;

	RETURN ln_result;

END;
$$ LANGUAGE plpgsql; 