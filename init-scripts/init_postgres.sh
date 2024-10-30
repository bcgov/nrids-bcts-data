#!/bin/bash

set -e

# Wait for PostgreSQL to start
until pg_isready -U "$POSTGRES_USER"; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

# Create database if not exists
psql -U "$POSTGRES_USER" -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'ods'" | grep -q 1 || \
psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE ods;"

# Execute the SQL script to create schema and users
psql -U "$POSTGRES_USER" -d "ods" -f /init-scripts/init_postgres_schema.sql

echo "Database setup complete."

tail -f /dev/null

