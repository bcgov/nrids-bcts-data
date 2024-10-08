-- Connect to ODS database
\connect ods

-- Create schema
CREATE SCHEMA IF NOT EXISTS FOREST;

-- Create user
CREATE USER ods_proxy_user_lrm WITH PASSWORD 'ods_proxy_user_lrm';

-- Grant privileges
GRANT USAGE ON SCHEMA FOREST TO ods_proxy_user_lrm;
GRANT SELECT ON ALL TABLES IN SCHEMA FOREST TO ods_proxy_user_lrm;

-- Ensure future tables in the schema also have SELECT permission
ALTER DEFAULT PRIVILEGES IN SCHEMA FOREST
    GRANT SELECT ON TABLES TO ods_proxy_user_lrm;
