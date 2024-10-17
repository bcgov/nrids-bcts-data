#!/bin/bash

# Initialize the Airflow database
airflow db init

# Start the scheduler
exec airflow scheduler
