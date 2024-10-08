#!/bin/bash
# entrypoint_webserver.sh

# Initialize the Airflow database
airflow db init

# Function to create Airflow user
create_airflow_user() {
  echo "Waiting for the database to be ready..."
  while ! nc -z postgres 5432; do
    sleep 1
  done

  # Check if the user already exists
  if ! airflow users list | grep -q "admin"; then
    echo "Creating Airflow user..."
    airflow users create \
      --username admin \
      --firstname Admin \
      --lastname User \
      --role Admin \
      --email admin@example.com \
      --password admin
    echo "Airflow user created."
  else
    echo "Airflow user already exists."
  fi
}

# Create the user before starting the webserver
create_airflow_user

# Start the webserver
exec airflow webserver
