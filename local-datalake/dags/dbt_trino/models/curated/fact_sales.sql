{{ config(materialized='table') }}
SELECT
    s.order_date,
    s.order_number,
    to_hex(md5(to_uft8(cast(s.product_key AS VARCHAR)))) AS order_number_hash,
    to_hex(md5(to_uft8(t.country))) AS country_key,
    (s.order_quantity * p.product_price) AS revenue,
    (s.order_quantity * p.product_cost) AS cost,
    (s.order_quantity * p.product_price) - (s.order_quantity * p.product_cost) AS profit
FROM {{ ref('stg_sales') }} s
LEFT JOIN {{ ref('stg_products') }} p ON s.product_key = p.product_key
LEFT JOIN {{ ref('stg_territories') }} t
    ON s.territory_key = t.sales_territory_key
