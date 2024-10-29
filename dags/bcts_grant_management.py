import pandas as pd
from sqlalchemy import create_engine

MASTER_FILE_PATH = "./BCTS_ACCESS_CATALOG_DEV.xlsx"

ODS_USERNAME = "ods_proxy_user_lrm"
ODS_PASSWORD= "ods_proxy_user_lrm"
ODS_HOST= "localhost"
ODS_PORT= "5432"
ODS_DATABASE= "ods"

# Database connection details
DATABASE_URI = f'postgresql+psycopg2://{ODS_USERNAME}:{ODS_PASSWORD}@{ODS_HOST}:{ODS_PORT}/{ODS_DATABASE}'

# Create SQLAlchemy engine
engine = create_engine(DATABASE_URI)

# Read the master grant file into a pandas DataFrame
df = pd.read_excel(MASTER_FILE_PATH)

# Write DataFrame to the target table in PostgreSQL, replacing the table if it exists
df.to_sql(
    'master_access',  # Target table name
    engine,
    schema='lrm_replication',  # Replace with the correct schema if needed
    if_exists='replace',  # Replace the table if it already exists
    index=False  # Do not write DataFrame index as a column
)

print("Data has been successfully written to the master_access table in PostgreSQL.")
