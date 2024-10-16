-- Connect to ODS database
\connect ods

-- Create user
CREATE USER ods_proxy_user_lrm WITH PASSWORD 'ods_proxy_user_lrm';

-- Grant privileges to the user
GRANT CONNECT ON DATABASE ods TO ods_proxy_user_lrm;
GRANT CREATE ON DATABASE ods TO ods_proxy_user_lrm;
GRANT USAGE ON SCHEMA public TO ods_proxy_user_lrm; 

-- Switch to the new user
\c ods ods_proxy_user_lrm

-- Create schema
CREATE SCHEMA IF NOT EXISTS lrm_replication;


-- Metadata table for ODS

DROP TABLE IF EXISTS lrm_replication.cdc_master_table_list;

CREATE TABLE lrm_replication.cdc_master_table_list (
    application_name VARCHAR(255) NOT NULL,  -- Name of the application
    source_schema_name VARCHAR(255) NOT NULL,  -- Source schema name
    source_table_name VARCHAR(255) NOT NULL,  -- Source table name
    target_schema_name VARCHAR(255) NOT NULL,  -- Target schema name
    target_table_name VARCHAR(255) NOT NULL,  -- Target table name
    truncate_flag BOOLEAN DEFAULT FALSE,  -- Indicates if the target table should be truncated
    cdc_flag BOOLEAN DEFAULT FALSE,  -- Indicates if CDC (Change Data Capture) is enabled
    full_inc_flag BOOLEAN DEFAULT FALSE,  -- Full or Incremental data load flag
    cdc_column VARCHAR(255),  -- Column used for CDC tracking
    replication_order INT,  -- Order of replication
    customsql_ind BOOLEAN DEFAULT FALSE,  -- Indicates if custom SQL is used
    customsql_query TEXT,  -- Custom SQL query
    active_ind CHAR(1) NOT NULL DEFAULT 'Y',  -- Active indicator, 'Y' or 'N'
    PRIMARY KEY (application_name, source_schema_name, source_table_name, target_schema_name, target_table_name)
);

DROP TABLE IF EXISTS lrm_replication.audit_batch_status;

CREATE TABLE lrm_replication.audit_batch_status (
    table_name VARCHAR(255) NOT NULL,       -- Name of the table
    application_name VARCHAR(255) NOT NULL, -- Name of the application
    operation_type VARCHAR(50) NOT NULL,    -- Type of operation (e.g., 'replication')
    status VARCHAR(50) NOT NULL,            -- Status of the operation
    batch_run_date DATE NOT NULL DEFAULT CURRENT_DATE, -- Date of the operation
    PRIMARY KEY (table_name, application_name, batch_run_date)
);


-- Initialize lrm_replication.cdc_master_table_list
DO $$
DECLARE
    tables text[] := ARRAY['DIVISION','BLOCK_ALLOCATION','MANAGEMENT_UNIT','LICENCE','BLOCK_ADMIN_ZONE','DIVISION_CODE_LOOKUP','CODE_LOOKUP','TENURE_TYPE','CUT_PERMIT','MARK','CUT_BLOCK','ACTIVITY_CLASS','ACTIVITY_TYPE','ACTIVITY'];  
    table_name text;
BEGIN
    -- Loop through the list of table names
    FOREACH table_name IN ARRAY tables
    LOOP
        -- Insert into the table for each table in the list
        INSERT INTO lrm_replication.cdc_master_table_list (
            application_name,
            source_schema_name,
            source_table_name,
            target_schema_name,
            target_table_name,
            truncate_flag,
            cdc_flag,
            full_inc_flag,
            cdc_column,
            replication_order,
            customsql_ind,
            customsql_query)
        VALUES (
            'bcts_replication',
            'lrm_replication',
            table_name,               -- Source table name
            'lrm_replication',
            table_name,               -- Target table name
            'Y',
            'N',
            'N',
            '',
            1,
            'N',
            ''
        );
    END LOOP;
END $$;

-- Create target tables
\i '/init-scripts/annual_developed_volume_ddl.sql'

