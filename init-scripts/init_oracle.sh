#!/bin/bash

# Start the database
sqlplus / as sysdba <<EOF
STARTUP;
EXIT;
EOF

lsnrctl start

# # Wait for the Oracle database to start up (adjust time as needed)
# sleep 60

# Create directory for Data Pump import/export
sqlplus / as sysdba <<EOF
CREATE OR REPLACE DIRECTORY dp_dir AS '/u01/app/oracle/oradata/';
GRANT READ, WRITE ON DIRECTORY dp_dir TO system;
EXIT;
EOF


# Optional: Any other Oracle initialization, such as creating users or schemas
sqlplus / as sysdba <<EOF
-- Switch to the container database 
ALTER SESSION SET CONTAINER = CDB$ROOT;
-- Create the pluggable database LRM
CREATE PLUGGABLE DATABASE LRM 
ADMIN USER lrm_admin IDENTIFIED BY admin_password 
FILE_NAME_CONVERT = ('/opt/oracle/oradata/XE/pdbseed/', '/opt/oracle/oradata/LRM/');
-- Open the newly created PDB LRM
ALTER PLUGGABLE DATABASE LRM OPEN;
-- Switch to the new PDB LRM
ALTER SESSION SET CONTAINER = LRM;
-- Create the LRM FOREST schema
CREATE USER FOREST IDENTIFIED BY admin_password;
GRANT CREATE SESSION TO FOREST;
GRANT CREATE TABLE TO FOREST;
GRANT CREATE VIEW TO FOREST;
GRANT CREATE PROCEDURE TO FOREST;

CREATE TABLESPACE lrm_tablespace 
DATAFILE '/opt/oracle/oradata/LRM/lrm_tablespace.dbf' 
SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;

ALTER USER FOREST QUOTA UNLIMITED ON lrm_tablespace;

ALTER USER FOREST DEFAULT TABLESPACE lrm_tablespace;


EOF

# Call the Python script to handle data export/import
# echo Initializing FOREST schema. Fetching data from LRM Test source...
# python3 /init-scripts/init_oracle_import.py
# echo FOREST schema init completed!

# Keep the container running
tail -f /dev/null
