{{ config(materialized='table') }}

SELECT
    to_hex(md5(to_utf8(cast(p.product_key AS VARCHAR)))) AS product_key,
    p.product_name,
    p.product_sku,
    p.product_color,
    ps.subcategory_key,
    pc.category_name
FROM {{ ref('stg_products') }} AS p
LEFT JOIN {{ ref('stg_product_subcategory') }} AS ps
    ON p.product_subcategory_key = ps.product_subcategory_key
LEFT JOIN {{ ref('stg_product_category') }} AS pc
    ON ps.product_category_key = pc.product_category_key
