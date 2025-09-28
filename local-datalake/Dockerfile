FROM apache/airflow:3.1.0
COPY requirements-dbt.txt requirements-dbt.txt
RUN pip install apache-airflow==${AIRFLOW_VERSION} -r requirements-dbt.txt