import pandas as pd
from sqlalchemy import create_engine, text

# Database connection details
DATABASE_URI = f'postgresql+psycopg2://{ODS_USERNAME}:{ODS_PASSWORD}@{ODS_HOST}:{ODS_PORT}/{ODS_DATABASE}'

# Connect to the database
engine = create_engine(DATABASE_URI)

# Query the master_access table and load data into a DataFrame
query = f"SELECT * FROM lrm_replication.master_access"
df = pd.read_sql(query, engine)

# Function to generate grant statements based on role permissions
def generate_grant_statements(row):
    statements = []
    schema = row['SCHEMA']
    table_name = row['TABLE_NAME']
    
    # List of roles and their permissions in the DataFrame
    role_permissions = {
        'BCTS_ETL_ROLE': row['BCTS_ETL_ROLE'],
        'BCTS_DEV_ROLE': row['BCTS_DEV_ROLE'],
        'BCTS_STAGE_ANALYST_ROLE': row['BCTS_STAGE_ANALYST_ROLE'],
        'BCTS_STAGE_ANALYST_PI_ROLE': row['BCTS_STAGE_ANALYST_PI_ROLE'],
        'BCTS_ANALYST_ROLE': row['BCTS_ANALYST_ROLE'],
        'BCTS_ANALYST_PI_ROLE': row['BCTS_ANALYST_PI_ROLE']
    }
    
    # Generate grant statements based on role permissions
    for role, permission in role_permissions.items():
        if permission == "Read":
            statements.append(f"GRANT SELECT ON {schema}.{table_name} TO {role};")
        elif permission == "Read/Write":
            statements.append(f"GRANT SELECT, INSERT, UPDATE, DELETE ON {schema}.{table_name} TO {role};")
        # Ignore 'Deny' permissions

    return statements

# Generate all grant statements for each row in the DataFrame
all_statements = []
for _, row in df.iterrows():
    all_statements.extend(generate_grant_statements(row))

# Execute the grant statements in PostgreSQL
with engine.begin() as connection:
    for statement in all_statements:
        print(statement)
        connection.execute(text(statement))

print("Grant statements executed successfully.")
