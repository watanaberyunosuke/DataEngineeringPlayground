#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Error handling ---
trap 'echo "[ERROR] Script failed at line $LINENO with exit code $?"; exit 1' ERR
trap 'echo "[INFO] Script interrupted (SIGINT/SIGTERM)"; exit 1' INT TERM

# --- Prerequisite checks ---
check_prereqs() {
    for cmd in docker dbt; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "[ERROR] Required command '$cmd' not found in PATH."
            exit 1
        fi
    done
}

start_service() {
    echo "[INFO] Spinning up the lakehouse environment..."
    check_prereqs

    echo "[INFO] Building data lake (MinIO + Nessie)"
    cd "$SCRIPT_DIR" || exit 1
    docker compose -f docker-compose-lake.yml up -d

    echo "[INFO] Waiting for MinIO to be healthy..."
    until docker exec minio /bin/sh -c "curl -f http://localhost:9000/minio/health/live" &>/dev/null; do
        echo "[INFO] Waiting for MinIO..."
        sleep 5
    done
    echo "[INFO] MinIO is healthy."

    echo "[INFO] Waiting for Nessie to be healthy..."
    until docker exec nessie-catalog curl -f http://localhost:19120/api/v1/config &>/dev/null; do
        echo "[INFO] Waiting for Nessie..."
        sleep 5
    done
    echo "[INFO] Nessie is healthy."

    echo "[INFO] Building Trino"
    docker compose -f docker-compose-trino.yml up -d
    sleep 15
    init_trino

    echo "[INFO] Building Airflow"
    docker compose -f docker-compose-airflow.yml up -d
    echo "[INFO] Finished building Airflow"
    sleep 10
}

init_trino() {
    echo "[INFO] Initialising Trino"
    if ! docker ps --format '{{.Names}}' | grep -q '^trino-coordinator$'; then
        echo "[ERROR] Trino container 'trino-coordinator' not running."
        exit 1
    fi

    # Wait for Trino to be ready
    until docker exec trino-coordinator trino --execute "SHOW CATALOGS;" &>/dev/null; do
        echo "[INFO] Waiting for Trino coordinator..."
        sleep 5
    done

    # Initialize Iceberg schema
    docker exec trino-coordinator trino \
        --catalog iceberg \
        --execute "CREATE SCHEMA IF NOT EXISTS landing; CREATE SCHEMA IF NOT EXISTS staging; CREATE SCHEMA IF NOT EXISTS curated;"

    echo "[INFO] Schema landing, staging, curated created in Trino Iceberg Catalog"
    echo "[INFO] Finished Initialising Trino"
}

load_dbt_seed_data() {
    echo "[INFO] Loading dbt seed data"
    dbt seed --project-dir ./dags/dbt_trino --profiles-dir ./dags/dbt_trino
    echo "[INFO] CSV files loaded into dbt landing project"
}

stop_service() {
    echo "[INFO] Stopping all services..."
    docker compose -f docker-compose-airflow.yml down -v --remove-orphans || true
    docker compose -f docker-compose-trino.yml down -v --remove-orphans || true
    docker compose -f docker-compose-lake.yml down -v --remove-orphans || true
    echo "[INFO] All services stopped."
}

case "${1:-help}" in
    "start")
        start_service
        ;;
    "stop")
        stop_service
        ;;
    "init_trino")
        init_trino
        ;;
    "load_dbt_seed_data")
        load_dbt_seed_data
        ;;
    *)
        echo "Usage: $0 {start|stop|init_trino|load_dbt_seed_data}"
        echo "Examples:"
        echo "  $0 start    # Start all services"
        echo "  $0 stop     # Stop all services"
        ;;
esac
