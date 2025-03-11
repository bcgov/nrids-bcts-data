-- DROP TABLE IF EXISTS lrm_replication.v_cp;

CREATE TABLE IF NOT EXISTS lrm_replication.v_cp
(
    tso_code text COLLATE pg_catalog."default",
    tso_name text COLLATE pg_catalog."default",
    nav_name text COLLATE pg_catalog."default",
    tenure text COLLATE pg_catalog."default",
    licence_id text COLLATE pg_catalog."default",
    permit_id text COLLATE pg_catalog."default",
    perm_application_description text COLLATE pg_catalog."default",
    divi_div_nbr bigint,
    licn_seq_nbr bigint,
    perm_seq_nbr bigint
)