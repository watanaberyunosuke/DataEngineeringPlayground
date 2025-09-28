# Local Data Lake

A local development environment for experimenting with modern data lake architecture using Docker containers.

Insprired by [Vu Trinh's blog post](https://vutr.substack.com/p/build-a-lakehouse-on-a-laptop-with?r=2rj6sg&triedRedirect=true)

## Components

- **Apache Airflow** - Workflow orchestration and scheduling
- **Apache Trino** - Distributed SQL query engine
- **MinIO** - S3-compatible object storage 
- **dbt** - Data transformation

## Prerequisites

- Docker and Docker Compose
- Python 3.x
- pip

## Setup

1. Clone this repository
2. Install dependencies:
```sh
pip install -r [requirements-airflow.txt](http://_vscodecontentref_/1)
pip install -r [requirements-dbt.txt](http://_vscodecontentref_/2)
```

3. Run the spin up script:
```sh
./spin-up-lakehouse.sh start
```

This will start all services defined in the docker-compose files:

- `docker-compose-airflow.yml` - Airflow webserver, scheduler and database
- `docker-compose-lake.yml` - MinIO object storage
- `docker-compose-trino.yml` - Trino coordinator and workers

## Architecture

- MinIO provides S3-compatible object storage for the data lake
- Nessie provides version control for data and metadata
- Trino enables SQL queries across data in MinIO
- dbt handles data transformations using Trino as the execution engine
- Airflow orchestrates the entire pipeline

## Usage

1. Access services:
    - Airflow UI: <http://localhost:8080>
    - MinIO Console: <http://localhost:9001>
    - Trino UI: <http://localhost:8081>
    - Nessie UI: <http://localhost:19120>
2. DAG files are stored in the dags directory
3. dbt models are in dbt_trino
4. Trino configuration in trino-config

## Project Structure

```
├── config/           # Configuration files
├── dags/            # Airflow DAG definitions
├── plugins/         # Airflow plugins
├── logs/            # Log files
├── minio-data/      # MinIO data directory
└── trino-config/    # Trino configuration
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first.
