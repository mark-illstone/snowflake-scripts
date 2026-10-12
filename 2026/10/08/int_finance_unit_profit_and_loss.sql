CREATE OR REPLACE TABLE bi.mark_dev.int_finance_unit_profit_and_loss AS

WITH unit_profit_and_loss AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_unit_profit_and_loss_base)

, base_metrics AS (
    SELECT order_number
         , order_item_id
         , unit_type
         , COALESCE(SUM(CASE WHEN type = 'price' THEN income - cost END), 0)                                                                        AS gross_revenue
         , COALESCE(SUM(CASE WHEN unit_type = 'product' and source <> 'shipment' and type = 'price' THEN income - cost END), 0)                     AS gross_revenue_product
         , COALESCE(SUM(CASE WHEN unit_type = 'giftwrap' and source <> 'shipment'  and type = 'price' THEN income - cost END), 0)                   AS gross_revenue_giftwrap
         , COALESCE(SUM(CASE WHEN unit_type = 'dedication_photo_upload' and source <> 'shipment' and type = 'price' THEN income - cost END), 0)     AS gross_revenue_photo
         , COALESCE(SUM(CASE WHEN unit_type = 'cover_style' and source <> 'shipment'  and type = 'price' THEN income - cost END), 0)                AS gross_revenue_cover
         , COALESCE(SUM(CASE WHEN unit_type = 'edition' and source <> 'shipment'  and type = 'price' THEN income - cost END), 0)                    AS gross_revenue_edition

         , COALESCE(-SUM(CASE WHEN type IN ('discount', 'voucher', 'store_credit') THEN income - cost END), 0)                                      AS discount
         , COALESCE(-SUM(CASE WHEN type = 'reorder' THEN income - cost END), 0)                                                                     AS reorders
         , COALESCE(-SUM(CASE WHEN type = 'tax' THEN income - cost END), 0)                                                                         AS tax
         , COALESCE(SUM(CASE WHEN type = 'adjustment' THEN income - cost END), 0)                                                                   AS adjustment
         -- refunds look like it will always be null
         , COALESCE(-SUM(CASE WHEN type = 'refund' THEN income - cost END), 0)                                                                      AS refunds
         , COALESCE(-SUM(CASE WHEN type = 'cogs' THEN income - cost END), 0)                                                                        AS cogs
         , COALESCE(-SUM(CASE WHEN type = 'fee' AND source = 'payment' THEN income - cost END), 0)                                                  AS payment_fees
         , COALESCE(-SUM(CASE WHEN type = 'fee' AND source = 'royalty' THEN income - cost END), 0)                                                  AS royalty_fees
         , COALESCE(-SUM(CASE WHEN source = 'marketing' THEN income - cost END), 0)                                                                 AS marketing_cost
         , COALESCE(-SUM(CASE WHEN source = 'shipment' AND type = 'cogs' THEN income - cost END), 0)                                                AS shipments_cost
         , COALESCE(-SUM(CASE WHEN source IN ('order', 'unit', 'gift_wrap') AND type = 'cogs' THEN income - cost END), 0)                           AS production_cost
         -- 11/05/2020 AS: moved from Looker to here as makes more sense
         , COALESCE(SUM(CASE WHEN source = 'shipment' THEN income END), 0)                                                                          AS net_revenue_shipping
         , COALESCE(SUM(CASE WHEN source = 'shipment' THEN local_income END), 0)                                                                    AS local_net_revenue_shipping
         , COALESCE(-SUM(CASE WHEN (type = 'cogs') AND (source = 'unit'  OR source = 'gift_wrap' OR source = 'addon') THEN income - cost END), 0)   AS unit_cogs
         , COALESCE(-SUM(CASE WHEN source = 'order' AND type = 'cogs' THEN income - cost END), 0)                                                   AS order_cogs
         , COALESCE(-SUM(CASE WHEN type = 'store_credit' AND ordered_at::date >= '2018-03-01' THEN income - cost END), 0)                           AS store_credit
         , COALESCE(SUM(local_income), 0)                                                                                                           AS local_income
         , COALESCE(SUM(local_cost), 0)                                                                                                             AS local_cost
         , COALESCE(SUM(income), 0)                                                                                                                 AS income
         , COALESCE(SUM(cost), 0)                                                                                                                   AS cost
         , COALESCE(-SUM(CASE WHEN uses_new_braketed_rates = 1 and source = 'bracketed_shipment' AND type = 'cogs' THEN income - cost END), 0)      AS bracketed_shipments_cost
         , COALESCE(-SUM(CASE WHEN uses_new_braketed_rates = 1 and source = 'bracketed_shipment' AND type = 'cogs' THEN local_income - cost END), 0)AS local_bracketed_shipments_cost
         , MAX(weight_in_grams)                                                                                                                     AS weight_in_grams
         , MAX(weight_ratio)                                                                                                                        AS weight_ratio
         , MAX(uses_new_braketed_rates)                                                                                                             AS uses_new_braketed_rates
         , ordered_at

         , COALESCE(SUM(CASE WHEN unit_type = 'product'                 and source in ('unit', 'gift_wrap', 'addon') and type = 'cogs' THEN cost END), 0) AS unit_cogs_product
         , COALESCE(SUM(CASE WHEN unit_type = 'giftwrap'                and source in ('unit', 'gift_wrap', 'addon') and type = 'cogs' THEN cost END), 0) AS unit_cogs_giftwrap
         , COALESCE(SUM(CASE WHEN unit_type = 'dedication_photo_upload' and source in ('unit', 'gift_wrap', 'addon') and type = 'cogs' THEN cost END), 0) AS unit_cogs_photo
         , COALESCE(SUM(CASE WHEN unit_type = 'cover_style'             and source in ('unit', 'gift_wrap', 'addon') and type = 'cogs' THEN cost END), 0) AS unit_cogs_cover
         , COALESCE(SUM(CASE WHEN unit_type = 'edition'                 and source in ('unit', 'gift_wrap', 'addon') and type = 'cogs' THEN cost END), 0) AS unit_cogs_edition

         , COALESCE(SUM(CASE WHEN unit_type = 'product' AND source = 'unit'         AND type = 'price'                                       THEN income - cost END), 0)     AS product_price
         , COALESCE(SUM(CASE WHEN unit_type = 'product' AND source = 'shipment'     AND type = 'price'                                       THEN income - cost END), 0)     AS product_shipping
         , COALESCE(SUM(CASE WHEN unit_type = 'product' AND source = 'unit'         AND type IN ('discount', 'voucher', 'store_credit')      THEN income - cost END), 0)     AS product_discount
         , COALESCE(SUM(CASE WHEN unit_type = 'product' AND source = 'unit'         AND type = 'reorder'                                     THEN income - cost END), 0)     AS product_reorder
      FROM unit_profit_and_loss
     GROUP BY ALL
)

, stacked_metrics AS (
    -- adjustments in this context are shipping or giftwrap other adjustments such as refunds have been filtered out.
    SELECT *
         , gross_revenue - discount - reorders AS revenue_post_discount
         , gross_revenue - discount - reorders + adjustment AS revenue_post_adjustments
         , gross_revenue - discount - reorders + adjustment - tax AS net_revenue

         , gross_revenue_product - discount - reorders + adjustment - tax AS net_revenue_product
         , gross_revenue_giftwrap - discount - reorders + adjustment - tax AS net_revenue_giftwrap
         , gross_revenue_photo - discount - reorders + adjustment - tax AS net_revenue_photo
         , gross_revenue_cover - discount - reorders + adjustment - tax AS net_revenue_cover
         , gross_revenue_edition - discount - reorders + adjustment - tax AS net_revenue_edition

         , product_price + product_shipping + product_discount + product_reorder AS calculated_royalty_value

      FROM base_metrics
 )

SELECT order_number
     , order_item_id
     , unit_type
     , gross_revenue
     , discount
     , reorders
     , tax
     , adjustment
     , revenue_post_adjustments
     , revenue_post_discount
     , net_revenue
     , net_revenue_product
     , net_revenue_giftwrap
     , net_revenue_photo
     , net_revenue_cover
     , net_revenue_edition
     , gross_revenue_product
     , gross_revenue_giftwrap
     , gross_revenue_photo
     , gross_revenue_cover
     , gross_revenue_edition
     , refunds -- broken
     , cogs
     , payment_fees
     , royalty_fees
     , cogs + payment_fees AS other_cost
     , marketing_cost
     , shipments_cost
     , production_cost
     , net_revenue_shipping
     , local_net_revenue_shipping
     , unit_cogs
     , order_cogs
     , store_credit
     , local_cost
     , local_income
     , income
     , cost
     , CASE WHEN ordered_at::date > '2021-07-01' and ordered_at::date < '2023-03-01' THEN (0.001 * net_revenue) ELSE (0.002 * net_revenue) END as cogs_storage_costs
     , CASE WHEN ordered_at::date > '2021-07-01' THEN (0.0025 * net_revenue) ELSE (0.005 * net_revenue) END as cogs_inbound_logistics_costs

     , bracketed_shipments_cost
     , local_bracketed_shipments_cost
     , weight_in_grams
     , weight_ratio
     , uses_new_braketed_rates

     -- COGS = payment_fees - shipments_cost - production_cost
     , net_revenue - payment_fees - shipments_cost - production_cost AS gross_profit_old
     , (net_revenue - payment_fees - shipments_cost - production_cost) - marketing_cost AS contribution
     , net_revenue - (payment_fees + bracketed_shipments_cost + unit_cogs + order_cogs + cogs_inbound_logistics_costs + cogs_storage_costs + royalty_fees)  AS gross_profit_new  
 
     , unit_cogs_product
     , unit_cogs_giftwrap
     , unit_cogs_photo
     , unit_cogs_cover
     , unit_cogs_edition
    
     , calculated_royalty_value
    
    FROM stacked_metrics

    GROUP BY ALL