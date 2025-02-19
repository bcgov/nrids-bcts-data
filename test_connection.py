from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
import getpass

# Static connection parameters
HOST = "theory.bcgov"  # Update as needed
PORT = "5434"       # Default PostgreSQL port
DATABASE = "odstst"  # Update with your database name
SCHEMA = "lrm_replication"        # Update with your schema name
TABLE = "division"  # Update with your table name

# Prompt for user credentials
username = input("Enter PostgreSQL username: ")
password = getpass.getpass("Enter PostgreSQL password: ")

# Create a connection URL
connection_url = f"postgresql+psycopg2://{username}:{password}@{HOST}:{PORT}/{DATABASE}"

try:
    # Create an SQLAlchemy engine
    engine = create_engine(connection_url)
    
    # Connect to the database
    with engine.connect() as connection:
        print("Connection successful!")
        
        # Query to check if the table can be read
        query = text(f"SELECT * FROM {SCHEMA}.{TABLE} LIMIT 2;")
        
        # Execute the query
        result = connection.execute(query)
        print(result.fetchall())
        print(f"Table '{TABLE}' in schema '{SCHEMA}' is accessible.")
except SQLAlchemyError as e:
    print(f"An error occurred: {e}")
