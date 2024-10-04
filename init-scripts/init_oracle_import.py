import cx_Oracle
import subprocess
import os

# Environment variables
remote_dsn = cx_Oracle.makedsn('remote_host', 1521, service_name='remote_service')
remote_conn = cx_Oracle.connect('remote_user', 'remote_password', dsn=remote_dsn)

local_dsn = cx_Oracle.makedsn('localhost', 1521, service_name='ORCLCDB.localdomain')
local_conn = cx_Oracle.connect('system', os.getenv('ORACLE_PASSWORD'), dsn=local_dsn)

export_dir = '/u01/app/oracle/oradata/'  # Path inside Docker container for Data Pump files

def export_data():
    """ Use Data Pump to export data from the remote Oracle DB """
    subprocess.run([
        'expdp', 'remote_user/remote_password@remote_host',
        'SCHEMAS=remote_schema_name',
        'TABLES=table1,table2,...,table10',
        'QUERY=\'table1: "WHERE ROWNUM <= 1000", table2: "WHERE ROWNUM <= 1000"\'',
        f'DIRECTORY=dp_dir', 
        'DUMPFILE=export.dmp', 
        'LOGFILE=export.log'
    ])

def import_data():
    """ Use Data Pump to import data into the local Oracle DB """
    subprocess.run([
        'impdp', f'system/{os.getenv("ORACLE_PASSWORD")}@localhost',
        'SCHEMAS=local_schema_name',
        'TABLES=table1,table2,...,table10',
        f'DIRECTORY=dp_dir', 
        'DUMPFILE=export.dmp', 
        'LOGFILE=import.log'
    ])

def main():
    export_data()
    import_data()

if __name__ == '__main__':
    main()
