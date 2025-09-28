from datetime import datetime, timedelta
from airflow.decorators import dag, task
from library.lib_operator import DbtCoreOperator
from airflow import settings


DBT_PROJECT_PATH = f"{settings.DAGS_FOLDER}/dbt_trino"

default_args = {
    "owner": "batman",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


@dag(
    dag_id="dbt_pipeline",
    default_args=default_args,
    description="A DAG to run dbt Core transformations with reusable @tasks.",
    schedule=timedelta(days=1),
    start_date=datetime(2025, 8, 8),
    catchup=False,
    tags=["dbt", "data_transformation"],
)
def dbt_pipeline():
    @task
    def dbt_seed():
        """Wrapper for dbt seed"""
        return DbtCoreOperator(
            task_id="dbt_seed",
            dbt_project_dir=DBT_PROJECT_PATH,
            dbt_profiles_dir=DBT_PROJECT_PATH,
            dbt_command="seed",
            full_refresh=True,
        ).execute({})

    @task
    def dbt_run():
        """Wrapper for dbt run"""
        return DbtCoreOperator(
            task_id="dbt_run",
            dbt_project_dir=DBT_PROJECT_PATH,
            dbt_profiles_dir=DBT_PROJECT_PATH,
            dbt_command="run",
        ).execute({})

    dbt_seed() >> dbt_run()


dag = dbt_pipeline()
