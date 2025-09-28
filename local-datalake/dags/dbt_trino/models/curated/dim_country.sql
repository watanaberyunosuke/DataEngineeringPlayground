{{ config(materialized='table') }}

SELECT
    to_hex(md5(to_utf8(country))) AS country_key,
    country,
    continent
FROM {{ ref('stg_territories') }}
