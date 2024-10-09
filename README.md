# Local Development Environment for BCTS Reporting Using NRM Data Analytics Platform (DAP)

## Overview

This repository provides step-by-step instructions for developing ETL tasks and reports for BCTS reporting using the NRM Data Analytics Platform. ETL tasks are orchestrated using Apache Airflow, leveraging a local Kubernetes cluster running on Docker Desktop. The setup includes an Oracle database as the source, a PostgreSQL database as the Operational Data Store (ODS), and Airflow for task orchestration, replicating the production environment.

## Architecture

![Architecture Diagram](./images/BCTS%20Local%20Development%20Environment.jpeg) 

The architecture consists of the following components:

- **Oracle Database (Source)**: The source database from which data will be extracted.
- **PostgreSQL Database (ODS)**: The target database where data will be loaded.
- **Apache Airflow**: The orchestration tool for managing ETL workflows.
- **Kubernetes Cluster**: A local Kubernetes cluster running on Docker Desktop to run tasks using the Kubernetes Pod Operator.

## Getting Started

### Prerequisites

- Docker Desktop installed with Kubernetes enabled.

### Setup

**Clone the Repository**:
```bash
git clone https://github.com/smunthik/nrids-bcts-data
cd nrids-bcts-data

# Start Docker Desktop
# Ensure that the K8s cluster in Docker desktop is up and running

# Start the Services: Use the following command to spin up the Oracle database, PostgreSQL database, and Airflow:
docker-compose --profile airflow up

# Wait for the services to initialize

# Services:
    Airflow: localhost:8080 usename:admin, password: admin
    Postgres: localhost:5432 username: ods_proxy_user_lrm, password: ods_proxy_user_lrm, database: ods
    Oracle: localhost:1521 username: FOREST password: admin_password database: LRM

# Run the `test_dag`
```

During the initialization of the databases, a Python script will pull the required tables from LRMDBQ06 into the local Oracle database.
Currently, the connection from docker to LRM Test database is not working because of challenges in whitelisting the application on the database side due to dynamic container names. Hence, as a temporary workaround, the Python script is run on the host if db initialization is required. 

### Steps to add a new ETL task
1. **Create DAGs**:

    Define the ETL tasks in DAGs.
    Use the Kubernetes Pod Operator to run tasks on the local Kubernetes cluster.

2. **Generate DDL**:
    Initialize the local Oracle database with the required source tables by running the python script, init-scripts\init_oracle_import.py
    Generate DDL scripts from local FOREST schema. Convert to PostgreSQL syntax.
    Use DDL scripts generated to create the required target tables in the local ODS.

3. **Trigger DAGs**:

    Ensure K8s cluster is running on Docker desktop
    Trigger the DAGs to replicate the data from Oracle to ODS.
    Add DAGS or downstream tasks to implement transformations if any.

4. **Connect to Power BI**:

    The local ODS can be connected to Power BI Desktop for developing and testing reports before pushing changes to higher environments.

### Test and Deployment Process

***Permission from the data custodian and PIA***:

Ensure permission from the data custodian to pull the required data into ODS. Record the permission. 
Ensure that the PIA documents are updated

***Masking of the sensitive attributes***:
Ensure that the sensitive attributes which are not required for reporting are masked before pulling into ODS

***Update the BCTS DAP Access Tracker***:

Ensure that all changes are reflected in the BCTS DAP access tracker.

***Create SD ticket to grant access to the required tables to DAP proxy user***:

Ensure that DAP proxy user has the permissions to read access the required tables from the source system.

***Update the DAP Repository***:

Add the Docker image and DDL scripts to the ![nr-dap-ods](https://github.com/bcgov/nr-dap-ods) repository and create a pull request.

***Update the DAG Repository***:

Add the DAG to the ![nr-airflow](https://github.com/bcgov/nr-airflow) repository and create a pull request.

***Test in DEV Environment***:

Conduct thorough tests in the DEV environment.

### Production Deployment:

Once validated, proceed to deploy to production.

### Contributing
Contributions are welcome! Please follow the standard Git workflow:

    Fork the repository.
    Create a feature branch.
    Make your changes.
    Submit a pull request.

### License
This project is licensed under the MIT License.

### Acknowledgments
Apache Airflow for ETL orchestration.
Docker for containerization.
Kubernetes for orchestration of containerized applications.

### Contact
For any inquiries, please reach out to sreejith.munthikodu@gov.bc.ca.

