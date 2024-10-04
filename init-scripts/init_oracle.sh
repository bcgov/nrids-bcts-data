#!/bin/bash

# Wait for the Oracle database to start up (adjust time as needed)
sleep 60

# Create directory for Data Pump import/export
sqlplus sys/${ORACLE_PASSWORD}@localhost as sysdba <<EOF
CREATE DIRECTORY dp_dir AS '/u01/app/oracle/oradata/';
GRANT READ, WRITE ON DIRECTORY dp_dir TO system;
EXIT;
EOF

# Call the Python script to handle data export/import
# python3 /init-scripts/export_import.py

# Optional: Any other Oracle initialization, such as creating users or schemas
sqlplus sys/${ORACLE_PASSWORD}@localhost as sysdba <<EOF
CREATE USER myuser IDENTIFIED BY mypassword;
GRANT ALL PRIVILEGES TO myuser;
EXIT;
EOF

# Keep the container running
tail -f /dev/null
