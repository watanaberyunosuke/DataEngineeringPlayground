import subprocess
from airflow.exceptions import AirflowException
from airflow.sdk import BaseOperator
from dbt.cli.main import dbtRunner, dbtRunnerResult


class DbtCoreOperator:
    def __init__(
        self,
        dbt_project_dir: str,
        dbt_profiles_dir: str,
        dbt_command: str,
        target: str = None,
        select: str = None,
        dbt_vars: dict = None,
        full_refresh: bool = False,
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)
        self.dbt_project_dir = dbt_project_dir
        self.dbt_profiles_dir = dbt_profiles_dir
        self.dbt_command = dbt_command
        self.target = target
        self.select = select
        self.dbt_vars = dbt_vars
        self.full_refresh = full_refresh
        self.runner = dbtRunner()
        self.dbt_vars = dbt_vars or {}
        self.full_refresh = full_refresh

    def execute(self):
        command_args = [
            self.dbt_command,
            "--project-dir",
            self.dbt_project_dir,
            "--profiles-dir",
            self.dbt_profiles_dir,
        ]
        if self.target:
            command_args.extend(["--target", self.target])

        if self.select:
            command_args.extend(["--select", self.select])

        if self.full_refresh:
            command_args.extend(["--full-refresh"])

        if self.dbt_vars:
            vars_string = " ".join([f"{k}:{v}" for k, v in self.dbt_vars.items()])
            command_args.extend(["--vars", vars_string])

        self.log.info(f"Running dbt command: {' '.join(command_args)}")
        res: dbtRunnerResult = self.runner.invoke(command_args)

        for r in res.result:
            self.log.info(
                f"dbt command finished on {r.node.name} with return code {res.status}"
            )
