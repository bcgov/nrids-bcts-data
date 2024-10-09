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
- Docker Compose.

### Setup

**Clone the Repository**:
```bash
git clone https://github.com/smunthik/nrids-bcts-data
cd nrids-bcts-data

# Start the Services: Use the following command to spin up the Oracle database, PostgreSQL database, and Airflow:
docker-compose up --profile airflow
```

During the initialization of the databases, a Python script will pull the required tables from LRMDBQ06 into the local Oracle database.

### Development Workflow
1. **Create DAGs**:

    Define the ETL tasks in DAGs.
    Use the Kubernetes Pod Operator to run tasks on the local Kubernetes cluster.

2. **Generate DDL**:

    Use DDL scripts generated from the local source database, converting them to PostgreSQL syntax to create the required target tables in the ODS.

3. **Trigger DAGs**:

    Trigger the DAGs to replicate the data from Oracle to ODS.

4. **Connect to Power BI**:

    The local ODS can be connected to Power BI Desktop for developing and testing reports before pushing changes to higher environments.

### Test and Deployment Process

**Deployment to Repositories**:

***Update the DAP Repository***:

If everything works as expected, add the Docker image and DDL scripts to the nr-dap-ods repository and create a pull request.

***Update the DAG Repository***:

Add the DAG to the nr-airflow repository and create a pull request.

***Test in DEV Environment***:

Conduct thorough tests in the DEV environment.

***Update the BCTS DAP Access Tracker***:

Ensure that all changes are reflected in the BCTS DAP access tracker.

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

