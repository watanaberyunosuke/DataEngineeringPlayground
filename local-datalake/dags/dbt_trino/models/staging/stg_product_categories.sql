{{ config(
    materialized = 'table'
) }}

SELECT
    *
FROM
    {{ ref('roduct_categories') }}
