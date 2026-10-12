

with finance_addons_summary AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_addon_summary)
   , finance_units AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_units where order_item_id = 26539418)
   , finance_payment_fees AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_payment_fees)
   , finance_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_orders)
   , finance_shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_shipments where order_number = 'R255348233')
   , finance_unit_adjustments AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_unit_adjustments)
   , finance_unit_tax_additional AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_unit_tax_additional)
   , finance_unit_tax_included AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_unit_tax_included)
   , unit_cogs AS (SELECT * FROM bi.dbt_production_intermediate.int_unit_cogs)
   , unit_shipping_cost AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_unit_shipping_cost)
   , bracketed_shipping_cogs AS (SELECT * FROM bi.dbt_production_models.fct_finance_unit_shipping_cost_test)
   , fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)

  , component_summary AS (
  SELECT 
      order_number,
      order_item_id,
      --value:"id"::STRING AS component_name,
      value:"price_at_checkout"::FLOAT AS local_price,
      NULLIF(SPLIT_PART(value:"id"::STRING, ':', 1), '') AS component_name_clean
      --NULLIF(SPLIT_PART(value:"id"::STRING, ':', 2), '') AS component_type,
      --NULLIF(SPLIT_PART(value:"id"::STRING, ':', 3), '') AS component_sub_type
  FROM finance_units,
       LATERAL FLATTEN(input => PARSE_JSON(components)) AS f
)

, units as (
    SELECT order_number
         , order_item_id
         , 'unit' AS source
         , 'price' AS type
         , local_currency
         , local_price AS local_amount
        ,NULL as weight_in_grams
        ,NULL as weight_ratio
        ,NULL as uses_new_braketed_rates
    FROM finance_units

)

, shipment_income as (
    SELECT a.order_number
         , b.order_item_id
         , 'shipment' AS source
         , 'price' AS type
         , a.local_currency
          -- The partition here handles the case where we could have multiple shipments.
         , a.local_price * RATIO_TO_REPORT(b.ratio_to_order) OVER (PARTITION BY a.shipment_id)
           AS local_amount
        ,NULL as weight_in_grams
        ,NULL as weight_ratio
        ,NULL as uses_new_braketed_rates
      FROM finance_shipments a
      JOIN finance_units b
        ON a.order_number = b.order_number
 )

-- , shipment_cost as (
--     SELECT order_number
--          , order_item_id
--          , 'shipment' AS source
--          , 'cogs' AS type
--          , local_currency
--          , -local_amount
--         ,NULL as weight_in_grams
--         ,NULL as weight_ratio
--         ,NULL as uses_new_braketed_rates
--       FROM unit_shipping_cost
-- )

-- , bracketed_shipment_cost as (
--     SELECT order_number
--          , order_item_id
--          , 'bracketed_shipment' AS source
--          , 'cogs' AS type
--          , local_currency
--          , -local_amount
--         ,weight_in_grams
--        ,weight_ratio
--        ,uses_new_braketed_rates
--       FROM bracketed_shipping_cogs
-- )

-- , cogs as (
--     SELECT order_number
--          , order_item_id
--          , source
--          , 'cogs' AS type
--          , local_currency
--          , -local_amount
--         ,NULL as weight_in_grams
--         ,NULL as weight_ratio
--         ,NULL as uses_new_braketed_rates
--       FROM unit_cogs
-- )

-- -- Tax
-- -- TODO look at the 55 dual tax rated items
-- -- unit_tax_additional and unit_tax_included handles states where we show tax as an
-- -- separate value at the end of the checkout.
-- -- Essentially these two tables normalise the two ways we show tax on the site.

-- -- The tax here is stored in a separate Eagle column.
-- , tax1 as (
--     SELECT order_number
--          , order_item_id
--          , taxable_type AS source
--          , 'tax' AS type
--          , local_currency
--          , SUM(-local_amount) AS local_amount
--         ,NULL as weight_in_grams
--         ,NULL as weight_ratio
--         ,NULL as uses_new_braketed_rates
--       FROM finance_unit_tax_additional
--      GROUP BY 1,2,3,4,5
-- )

-- -- The tax here is pulled from the COGs sheet.
-- , tax2 as (
--     SELECT order_number
--          , order_item_id
--          , taxable_type AS source
--          , 'tax' AS type
--          , local_currency
--          , SUM(-local_amount) AS local_amount
--         ,NULL as weight_in_grams
--         ,NULL as weight_ratio
--         ,NULL as uses_new_braketed_rates
--       FROM finance_unit_tax_included
--      GROUP BY 1,2,3,4,5
-- )

-- -- Adjustments

-- , adjustments as (
--     SELECT order_number
--          , order_item_id
--          , adjustable_type AS source
--          , adjustment_type AS type
--          , local_currency
--          , local_amount
--         ,NULL as weight_in_grams
--         ,NULL as weight_ratio
--         ,NULL as uses_new_braketed_rates
--       FROM finance_unit_adjustments
--      WHERE adjustment_type != 'tax'
-- )

-- -- Payment Fees

-- , payment_fees as (
--     SELECT b.order_number
--          , b.order_item_id
--          , 'payment' AS source
--          , 'fee' AS type
--          , a.currency as local_currency
--          , -a.amount * RATIO_TO_REPORT(b.ratio_to_order) OVER (PARTITION BY a.payment_number)
--         ,NULL as weight_in_grams
--         ,NULL as weight_ratio
--         ,NULL as uses_new_braketed_rates
--       FROM finance_payment_fees a
--       JOIN finance_units b ON a.order_number = b.order_number
-- )


-- HN Royalty Fees

--, royalty_fees as (
    SELECT
        a.order_number
        , a.order_item_id
        , 'royalty' AS source
        , 'fee' AS type
        , a.local_currency AS local_currency
        --, a.local_adjusted_price AS unit_price
        , ((-a.local_adjusted_price + -b.local_amount) * 0.18)
        , NULL as weight_in_grams
        , NULL as weight_ratio
        , NULL as uses_new_braketed_rates
        , -a.local_adjusted_price
        , -b.local_amount
        , (-a.local_adjusted_price + -b.local_amount)
    FROM  finance_units a
        LEFT JOIN shipment_income b
            ON a.order_item_id = b.order_item_id
    WHERE lower(a.sub_category) = 'historic newspapers'

-- )

-- , temp_unit_profit_and_loss as(
--     SELECT * FROM units
--      UNION ALL
--     SELECT * FROM shipment_income
--      UNION ALL
--     SELECT * FROM shipment_cost
--      UNION ALL
--     SELECT * FROM cogs
--      UNION ALL
--     SELECT * FROM tax1
--      UNION ALL
--     SELECT * FROM tax2
--      UNION ALL
--     SELECT * FROM adjustments
--      UNION ALL
--     SELECT * FROM payment_fees
--      UNION ALL
--     SELECT * FROM bracketed_shipment_cost
--      UNION ALL
--     SELECT * FROM royalty_fees
    
-- )

-- , temp_converted_unit_profit_and_loss as (
--     SELECT a.order_number
--          , a.order_item_id
--          , b.ordered_at
--          , a.source
--          , a.type
--          , CASE WHEN a.source IN ('marketing') OR a.type IN ('voucher') THEN 'marketing'
--                 WHEN a.type IN ('price', 'discount', 'adjustment', 'tax', 'store_credit') THEN 'revenue'
--                 ELSE 'other'
--             END AS pnl_group
--          , c.rate AS fx_rate
--          , a.local_currency
--          , GREATEST(a.local_amount, 0) AS local_income
--          , GREATEST(-a.local_amount, 0) AS local_cost
--          , GREATEST(a.local_amount, 0) / c.rate AS income
--          , GREATEST(-a.local_amount, 0) / c.rate AS cost
--         , weight_in_grams
--         , weight_ratio
--         , uses_new_braketed_rates
--       FROM temp_unit_profit_and_loss a
--       JOIN finance_orders b
--         ON a.order_number = b.order_number
--       JOIN fx c
--         ON b.ordered_at::DATE = c.date
--       --and finance.fx.currency='GBP' ??
--        AND a.local_currency = c.currency

-- )

-- -- , temp_unit_ratios1 as (
-- --     -- This is a hack, the system was built around the idea of having a unit with
-- --     -- an optional giftwrap but now we have N+1 addons, giftwraps and units.
-- --     -- As a patch I group addons including wraps by item ID and label them as gwrap.
-- --     SELECT b.order_number
-- --          , b.order_item_id
-- --          , 'gift_wrap' as unit_type
-- --          --set this to 1 when it's 0 to avoid the ratio being 0 and division by 0 error
-- --          --this was logic implemented in finance.units code which we have copied here.
-- --          , CASE WHEN MAX(b.local_price) > 0 then SUM(a.local_price) / max(b.local_price)
-- --                 ELSE 1
-- --             END AS ratio_to_unit
-- --         ,NULL as weight_in_grams
-- --         ,NULL as weight_ratio
-- --         ,NULL as uses_new_braketed_rates
-- --       FROM finance_addons_summary a
-- --       JOIN finance_units b
-- --         ON a.order_number = b.order_number
-- --        AND a.order_item_id = b.order_item_id
-- --      --  where b.order_item_id = 16711795
-- --      GROUP BY 1,2
-- -- )

-- , temp_component_ratios AS (
--   SELECT
--     u.order_number,
--     u.order_item_id,
--     component_name_clean AS unit_type,
--     CASE WHEN MAX(u.local_price) > 0
--          THEN SUM(cd.local_price) / MAX(u.local_price)
--          ELSE 1 END AS ratio_to_unit
--     ,NULL as weight_in_grams
--     ,NULL as weight_ratio
--     ,NULL as uses_new_braketed_rates
--   FROM component_summary cd
--   JOIN finance_units u
--     ON cd.order_number = u.order_number
--    AND cd.order_item_id = u.order_item_id

--   GROUP BY 1, 2, 3
-- --  ;
-- )

-- -- , temp_unit_ratios2 as (
-- --     SELECT a.order_number
-- --          , a.order_item_id
-- --          , 'product' AS unit_type
-- --         , 1 - COALESCE(b.ratio_to_unit, 0) AS ratio_to_unit
-- --         ,NULL as weight_in_grams
-- --         ,NULL as weight_ratio
-- --         ,NULL as uses_new_braketed_rates
-- --       FROM finance_units a
-- --       LEFT JOIN temp_unit_ratios1 b
-- --         ON a.order_number = b.order_number
-- --        AND a.order_item_id = b.order_item_id
-- --   --      where a.order_item_id = 22741720;
-- -- )

-- , temp_unit_ratios2 AS (
--     SELECT 
--         a.order_number,
--         a.order_item_id,
--         'product' AS unit_type,
--         GREATEST(
--             1 - COALESCE(cr.total_ratio, 0),
--             0
--         ) AS ratio_to_unit,
--         NULL AS weight_in_grams,
--         NULL AS weight_ratio,
--         NULL AS uses_new_braketed_rates
--     FROM finance_units a
--     LEFT JOIN (
--         SELECT 
--             order_number, 
--             order_item_id, 
--             SUM(ratio_to_unit) AS total_ratio
--         FROM temp_component_ratios
--         GROUP BY 1, 2
--     ) cr ON a.order_number = cr.order_number AND a.order_item_id = cr.order_item_id

-- )



-- , temp_unit_ratios as (
--   --  SELECT * FROM temp_unit_ratios1  UNION ALL
--     SELECT *
--       FROM temp_unit_ratios2
--     UNION ALL
--     SELECT * from temp_component_ratios
    
-- )

-- -- finance.unit_profit_and_loss
-- SELECT temp_converted_unit_profit_and_loss.order_number
--      , temp_converted_unit_profit_and_loss.order_item_id
--      , temp_converted_unit_profit_and_loss.ordered_at
--      , temp_unit_ratios.unit_type
--      , temp_converted_unit_profit_and_loss.source
--      , temp_converted_unit_profit_and_loss.type
--      , temp_converted_unit_profit_and_loss.pnl_group
--      , temp_converted_unit_profit_and_loss.fx_rate
--      , temp_converted_unit_profit_and_loss.local_currency
--      , temp_converted_unit_profit_and_loss.local_income
--        * COALESCE(
--                   temp_unit_ratios.ratio_to_unit, 0)
--        AS local_income
--      , temp_converted_unit_profit_and_loss.local_cost
--        * COALESCE(
--                   temp_unit_ratios.ratio_to_unit, 0)
--        AS local_cost
--      , temp_converted_unit_profit_and_loss.income
--        * COALESCE(
--                   temp_unit_ratios.ratio_to_unit, 0)
--        AS income
--      , temp_converted_unit_profit_and_loss.cost
--        * COALESCE(
--                   temp_unit_ratios.ratio_to_unit, 0)
--        AS cost
--        , temp_converted_unit_profit_and_loss.weight_in_grams
--        , temp_converted_unit_profit_and_loss.weight_ratio
--        , temp_converted_unit_profit_and_loss.uses_new_braketed_rates
--   FROM temp_converted_unit_profit_and_loss
   
  
-- JOIN temp_unit_ratios AS temp_unit_ratios
--   ON temp_converted_unit_profit_and_loss.order_number = temp_unit_ratios.order_number
--  AND temp_converted_unit_profit_and_loss.order_item_id = temp_unit_ratios.order_item_id

--   AND (temp_converted_unit_profit_and_loss.source != 'royalty' OR temp_unit_ratios.unit_type = 'product')
           
--  --and unit_type <> 'old_gift_wrap'

--   WHERE NOT (income = 0
--             AND cost = 0)
--  AND CONCAT(unit_type,' ', source) != 'gift_wrap royalty'