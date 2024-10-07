import cx_Oracle
import os
import sys

# List of tables to initialize in the local Oracle LRm db
tables = ['DIVISION']  # Fetch first 100 rows
owner = 'FOREST'

# Access the environment variables
remote_user = os.getenv('lrmq06_username')
remote_password = os.getenv('lrmq06_password')
remote_host = 'nrcdb02.bcgov'
remote_service_name='dbq06.nrs.bcgov'

local_user = 'FOREST'
local_password = 'admin_password'
local_host = 'localhost'
local_service_name='LRM'

remote_dsn = cx_Oracle.makedsn(remote_host, 1521, service_name=remote_service_name)
remote_conn = cx_Oracle.connect(remote_user, remote_password, dsn=remote_dsn)

local_dsn = cx_Oracle.makedsn(local_host, 1521, service_name=local_service_name)
local_conn = cx_Oracle.connect(local_user, local_password, dsn=local_dsn)

def create_local_table(table_name, owner, columns):
    """Create a table in the local Oracle DB based on fetched column definitions."""
    with local_conn.cursor() as cursor:
        # Construct column definitions from the source types
        column_defs = ', '.join([f"{col['name']} {col['type'].split('DB_TYPE_')[1]}"  if not col['type'].startswith('VARCHAR2') else f"{col['name']} {col['type']}" for col in columns])
        create_table_sql = f"CREATE TABLE {owner}.{table_name} ({column_defs})"
        try:
            cursor.execute(create_table_sql)
            local_conn.commit()
            print(f"Table {owner}.{table_name} created successfully.")
        except cx_Oracle.DatabaseError as e:
            print(f"Error creating table {table_name}: {e}")
            remote_conn.close()
            local_conn.close()
            sys.exit(1)
            
def ingest_data(table_name, owner, columns, data):
    """Insert data into the local Oracle DB."""
    with local_conn.cursor() as cursor:
        # Prepare SQL INSERT statement
        insert_sql = f"INSERT INTO {owner}.{table_name} ({', '.join(col['name'] for col in columns)}) VALUES ({', '.join(':' + str(i + 1) for i in range(len(columns)))})"
        cursor.executemany(insert_sql, data)
        local_conn.commit()
        print(f"Data ingested into {table_name} successfully.")

def fetch_remote_data(table_name, owner_name):
    """Fetch data and column definitions from the remote Oracle DB."""
    with remote_conn.cursor() as cursor:
        cursor.execute(f"SELECT * FROM {owner_name}.{table_name} WHERE ROWNUM = 1")  # Fetch only column metadata
        columns = [{'name': desc[0], 'type': f"VARCHAR2({desc[2]})" if desc[1].name == 'DB_TYPE_VARCHAR' else desc[1].name} for desc in cursor.description]  # Get data type names
        
        # Now fetch actual data
        cursor.execute(f"SELECT * FROM {owner_name}.{table_name} WHERE ROWNUM <= 100")
        data = cursor.fetchall()
        return columns, data

def main():

    for table in tables:
        print(f"Processing {table}...")
        columns, data = fetch_remote_data(table, owner)

        # Create local table if not exists
        create_local_table(table, owner, columns)

        # Ingest data
        ingest_data(table, owner, columns, data)

    print("Data transfer complete.")

if __name__ == '__main__':
    main()

    # Close connections
    remote_conn.close()
    local_conn.close()
