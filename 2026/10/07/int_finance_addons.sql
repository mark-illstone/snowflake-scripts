CREATE OR REPLACE TABLE bi.mark_dev.int_finance_addons AS

WITH addons AS (SELECT * FROM bi.dbt_production_intermediate.int_addons)
   , orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication)
   , variants AS (SELECT * FROM bi.dbt_production_intermediate.int_variants)
   , prices AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_prices)
   , excluded_orders AS (SELECT * FROM bi.etl.excluded_orders)
   , ww_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_ww_orders)
   , sg_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_sg_orders_base)
   , fp_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_fp_orders)
   , hn_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_hn_orders_solidus)
   , plucky_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_plucky_orders_solidus)
   , finance_catalog AS (SELECT * FROM bi.kleene_webforms.finance_catalog)
   , skus_mapping AS (SELECT * FROM bi.google_sheets.skus_mapping)
   , generic_sku_mapping AS (SELECT * FROM bi.google_sheets.ops_addon_unit_forecast)

, excluded_order_numbers AS (
    --bugged orders
    SELECT order_number FROM excluded_orders WHERE order_number IS NOT NULL
    
    UNION ALL
    --WW
    SELECT number AS order_number FROM ww_orders WHERE number IS NOT NULL
    
    UNION ALL
    --SG
    SELECT number AS order_number FROM sg_orders WHERE number IS NOT NULL
    
    UNION ALL
    --FP
    SELECT number AS order_number FROM fp_orders WHERE number IS NOT NULL

    UNION ALL
	--HN
	SELECT number as order_number FROM hn_orders WHERE number IS NOT NULL

    UNION ALL
    --Plucky
    SELECT number as order_number FROM plucky_orders WHERE number IS NOT NULL
)

SELECT orders.number AS order_number
     , addons.id AS order_item_id
     , addons.variant_id
     , COALESCE(skus_mapping.product_type, 'unknown_addon') AS source
     , variants.sku
     , COALESCE(prices.amount, finance_catalog.catalog_price) AS local_price
     , orders.currency AS local_currency
     , COALESCE(gsm.generic_sku, 'Other') AS generic_sku
     , gsm.stock_box_sku
  FROM addons
  LEFT JOIN orders
    ON addons.order_id = orders.id
  LEFT JOIN variants
    ON variants.sku = addons.sku
  LEFT JOIN prices
    ON prices.variant_id = variants.id
   AND orders.currency = prices.currency
   AND addons.created_at BETWEEN COALESCE(prices.created_at, '2016-01-01') 
                         AND COALESCE(prices.deleted_at, CURRENT_TIMESTAMP)::DATE
  --AND deduped.item_position = 1
  LEFT JOIN finance_catalog 
    ON orders.currency = finance_catalog.catalog_currency
  LEFT JOIN skus_mapping
    ON variants.sku = skus_mapping.sku

  LEFT JOIN generic_sku_mapping gsm
    ON variants.sku = gsm.solidus_sku
        AND orders.completed_at::date BETWEEN gsm.effective_date_from AND gsm.effective_date_to
    
 WHERE orders.number IS NOT NULL 
   AND orders.number NOT IN (SELECT * FROM excluded_order_numbers)