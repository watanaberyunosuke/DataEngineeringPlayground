{{ config(database='dbt') }}

with raw_data
as (
    select
    *,
    regexp_replace(financial_year, '-.*') as financial_year_start,
from {{ source('snowflake-landing-health-expense', 'aus_health_expense')}}
)

select * from raw_data
