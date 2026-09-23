--int_order_items_06082026

create or replace table bi.mark_dev.int_order_items as

WITH order_items AS (SELECT * FROM bi.dbt_production_intermediate.int_order_items_deduplication)
   , tmp_customisations AS (SELECT * FROM bi.dbt_production_intermediate.int_customisations_deduplication)
   , dim_products AS (SELECT * FROM bi.dbt_production_models.dim_products)
   , finance_addons AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_addons)
   , orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication)
   , excluded_orders AS (SELECT * FROM bi.etl.excluded_orders)
   , ww_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_ww_orders)
   , sg_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_sg_orders_base)
   , fp_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_fp_orders)
   , hn_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_hn_orders_solidus)
   , plucky_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_plucky_orders_solidus)

SELECT DISTINCT a.id AS id
     , a.order_id AS order_id
     , c.key AS product_fk
     , a.price AS price
     , CASE
        WHEN d.order_item_id IS NOT NULL THEN TRUE
        ELSE FALSE
       END AS gift_wrap
     , b.child_name AS child_name
     , COALESCE(b.gender, c.gender) AS gender
     , f.sku AS giftbox_sku
  FROM order_items a
  LEFT JOIN tmp_customisations b
    ON a.id = b.order_item_id
  LEFT JOIN dim_products c
    ON a.variant_id = c.eagle_id
  LEFT JOIN finance_addons d 
    ON d.order_item_id = a.id 
   AND d.source = 'gift_wrap'
   LEFT JOIN finance_addons f
    ON f.order_item_id = a.id 
   AND f.sku LIKE '%giftbox%'
  LEFT JOIN orders e
    ON a.order_id = e.id
  
 -- Cleaned up the excluded order ids and also added a removal of null values which breaks the ETL - Ben 2019-09-28
  WHERE e.number NOT IN (
  --bugged orders
          SELECT order_number FROM excluded_orders where order_number is not null
          UNION
          --ww
          SELECT number as order_number FROM ww_orders where number is not null
          UNION
          --SG
          SELECT number as order_number FROM sg_orders where number is not null
          UNION
          --FP
          SELECT number as order_number FROM fp_orders where number is not null
          UNION
        --HN
        SELECT number as order_number FROM hn_orders WHERE number IS NOT NULL
        UNION
        --Plucky
        SELECT number as order_number FROM plucky_orders WHERE number IS NOT NULL
        )