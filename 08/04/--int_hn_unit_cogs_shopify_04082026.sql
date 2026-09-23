--int_hn_unit_cogs_shopify_04082026

create or replace table bi.mark_dev.int_unit_cogs as

WITH gsheet_cogs_by_format AS (SELECT * FROM bi.google_sheets.hn_cogs_by_format)
   , product_data AS (SELECT * FROM bi.historical_newspapers_shopify.int_product_data)
   , finance_units AS (SELECT * FROM bi.historical_newspapers_shopify.int_finance_units)
   , fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)
   , gsheet_cogs_by_format_fall_back AS (SELECT * FROM bi.google_sheets.hn_cogs_by_format_fallback)


, temp_addon_cogs as (
    SELECT 
           a.line_item_id
         , c.currency
         , replace(c.psp_unit_cost, ',','')::FLOAT as psp_unit_cost
         , replace(c.hn_unit_cost, ',','')::FLOAT as hn_unit_cost
         , replace(c.psp_fulfilment_cost, ',','')::FLOAT as psp_fulfilment_cost 
         , replace(c.psp_twistwrap_cost, ',','')::FLOAT as psp_twistwrap_cost
         , replace(c.hn_twistwrap_cost, ',','')::FLOAT as hn_twistwrap_cost
         , replace(c.psp_box_cost, ',','')::FLOAT as psp_box_cost
         , replace(c.hn_box_cost, ',','')::FLOAT as hn_box_cost
         , replace(c.hn_insert_cost, ',','')::FLOAT as hn_insert_cost
      FROM product_data a
      
      INNER JOIN gsheet_cogs_by_format c
       ON c.psp = a.stock_location
       AND lower(c.cogs_format) = lower(a.addon_cogs_format)
       AND a.created_at::date between to_Date(c.effective_from,'DD/MM/YYYY') and to_Date(c.effective_to,'DD/MM/YYYY') 
 )

, temp_addon_cogs_fallback as (
    SELECT 
           a.line_item_id
         , c.currency
         , replace(c.psp_unit_cost, ',','')::FLOAT as psp_unit_cost
         , replace(c.hn_unit_cost, ',','')::FLOAT as hn_unit_cost
         , replace(c.psp_fulfilment_cost, ',','')::FLOAT as psp_fulfilment_cost 
         , replace(c.psp_twistwrap_cost, ',','')::FLOAT as psp_twistwrap_cost
         , replace(c.hn_twistwrap_cost, ',','')::FLOAT as hn_twistwrap_cost
         , replace(c.psp_box_cost, ',','')::FLOAT as psp_box_cost
         , replace(c.hn_box_cost, ',','')::FLOAT as hn_box_cost
         , replace(c.hn_insert_cost, ',','')::FLOAT as hn_insert_cost
      FROM product_data a
      
       INNER JOIN gsheet_cogs_by_format_fall_back c
       ON c.psp = a.stock_location
       AND lower(c.cogs_format) = lower(a.addon_cogs_format)
       AND a.created_at::date between to_Date(c.effective_from,'DD/MM/YYYY') and to_Date(c.effective_to,'DD/MM/YYYY')  
 )

, temp_addon_cogs_full as (
    SELECT 
         'unit' as source
         , a.stock_location
         , a.line_item_id
         , coalesce(b.currency, c.currency) as local_currency
         , a.sku as unit_sku
         , a.addon_sku
         , a.order_id
         , a.created_at
         , NULL as local_amount
         , coalesce(b.psp_unit_cost, c.psp_unit_cost)               as psp_unit_cost
         , coalesce(b.hn_unit_cost, c.hn_unit_cost)                 as hn_unit_cost
         , coalesce(b.psp_fulfilment_cost, c.psp_fulfilment_cost)   as psp_fulfilment_cost
         , coalesce(b.psp_twistwrap_cost, c.psp_twistwrap_cost)     as psp_twistwrap_cost
         , coalesce(b.hn_twistwrap_cost, c.hn_twistwrap_cost)       as hn_twistwrap_cost
         , coalesce(b.psp_box_cost, c.psp_box_cost)                 as psp_box_cost
         , coalesce(b.hn_box_cost, c.hn_box_cost)                   as hn_box_cost
         , coalesce(b.hn_insert_cost, c.hn_insert_cost)             as hn_insert_cost
         , a.cogs_format
         , a.addon_cogs_format
      FROM product_data a
      
        LEFT JOIN temp_addon_cogs b
        ON a.line_item_id = b.line_item_id

        LEFT JOIN temp_addon_cogs_fallback c
        ON a.line_item_id = c.line_item_id

    WHERE a.addon_sku is not null
       
 )
 
, temp_unit_cogs as (
    SELECT
         'unit' as source
         , a.stock_location
         , a.line_item_id
         , coalesce(c.currency, f.currency) as local_currency
         , a.sku as unit_sku
         , a.addon_sku
         , a.order_id
         , a.created_at
         , max(coalesce(replace(coalesce(c.psp_unit_cost, f.psp_unit_cost), ',','')::FLOAT,  0)) + max(coalesce(replace(coalesce(c.hn_unit_cost, f.hn_unit_cost), ',','')::FLOAT, 0)) AS local_amount
         , coalesce(replace(c.psp_unit_cost, ',','')::FLOAT          , replace(f.psp_unit_cost, ',','')::FLOAT)          as psp_unit_cost
         , coalesce(replace(c.hn_unit_cost, ',','')::FLOAT           , replace(f.hn_unit_cost, ',','')::FLOAT)           as hn_unit_cost
         , coalesce(replace(c.psp_fulfilment_cost, ',','')::FLOAT    , replace(f.psp_fulfilment_cost, ',','')::FLOAT)    as psp_fulfilment_cost 
         , coalesce(replace(c.psp_twistwrap_cost, ',','')::FLOAT     , replace(f.psp_twistwrap_cost, ',','')::FLOAT)     as psp_twistwrap_cost
         , coalesce(replace(c.hn_twistwrap_cost, ',','')::FLOAT      , replace(f.hn_twistwrap_cost, ',','')::FLOAT)      as hn_twistwrap_cost
         , coalesce(replace(c.psp_box_cost, ',','')::FLOAT           , replace(f.psp_box_cost, ',','')::FLOAT)           as psp_box_cost
         , coalesce(replace(c.hn_box_cost, ',','')::FLOAT            , replace(f.hn_box_cost, ',','')::FLOAT)            as hn_box_cost
         , coalesce(replace(c.hn_insert_cost, ',','')::FLOAT         , replace(f.hn_insert_cost, ',','')::FLOAT)         as hn_insert_cost
         , a.cogs_format
         , a.addon_cogs_format
      FROM product_data a
      
      LEFT JOIN gsheet_cogs_by_format c
        ON c.psp = a.stock_location
       AND lower(c.cogs_format) = coalesce(lower(a.cogs_format), lower(a.sku))
       AND c.page_count_bucket = a.page_bucket
       AND a.created_at::date between to_Date(c.effective_from,'DD/MM/YYYY') and to_Date(c.effective_to,'DD/MM/YYYY')  

        LEFT JOIN gsheet_cogs_by_format_fall_back f
        ON f.psp = a.stock_location
       AND lower(f.cogs_format) = coalesce(lower(a.cogs_format), lower(a.sku))
       AND a.created_at::date between to_Date(f.effective_from,'DD/MM/YYYY') and to_Date(f.effective_to,'DD/MM/YYYY') 

       
     GROUP BY ALL
)

 , temp_cogs as (
 SELECT 
       stock_location
     , line_item_id
     , order_id
     , created_at
     , local_currency
     , cogs_format
     , addon_cogs_format
     , local_amount as local_unit_cost
     , psp_fulfilment_cost + psp_twistwrap_cost + hn_twistwrap_cost + hn_insert_cost as local_order_cost
     , psp_unit_cost
     , hn_unit_cost
     , psp_fulfilment_cost
     , psp_twistwrap_cost
     , hn_twistwrap_cost
     , psp_box_cost
     , hn_box_cost
     , hn_insert_cost
 FROM
     temp_addon_cogs_full
     
 UNION

SELECT   
      stock_location
    , line_item_id
    , order_id
    , created_at
    , local_currency
    , cogs_format
    , addon_cogs_format
    , local_amount as local_unit_cost
    , psp_fulfilment_cost + psp_twistwrap_cost + hn_twistwrap_cost + hn_insert_cost as local_order_cost
    , psp_unit_cost
    , hn_unit_cost
    , psp_fulfilment_cost
    , psp_twistwrap_cost
    , hn_twistwrap_cost
    , psp_box_cost
    , hn_box_cost
    , hn_insert_cost
FROM
    temp_unit_cogs
)

, temp_cogs_group as
(
SELECT
      stock_location
    , line_item_id
    , order_id
    , created_at
    , local_currency
    , cogs_format
    , addon_cogs_format
    , SUM(local_unit_cost)      AS local_unit_cost
    , SUM(local_order_cost)     AS local_order_cost
    , SUM(psp_unit_cost)        AS psp_unit_cost
    , SUM(hn_unit_cost)         AS hn_unit_cost
    , SUM(psp_fulfilment_cost)  AS psp_fulfilment_cost
    , SUM(psp_twistwrap_cost)   AS psp_twistwrap_cost
    , SUM(hn_twistwrap_cost)    AS hn_twistwrap_cost
    , SUM(psp_box_cost)         AS psp_box_cost
    , SUM(hn_box_cost)          AS hn_box_cost
    , SUM(hn_insert_cost)       AS hn_insert_cost
FROM 
    temp_cogs a
GROUP BY
    1,2,3,4,5,6,7
)

-- , temp_cogs_ratio AS
-- (
-- SELECT
--       a.stock_location
--     , a.line_item_id
--     , a.order_id
--     , a.created_at
--     , a.local_currency
--     , a.cogs_format
--     , a.addon_cogs_format

--     , (sum(coalesce(replace(a.local_unit_cost, ',','')::FLOAT, 0))      over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as local_unit_cost
--     , (sum(coalesce(replace(a.local_order_cost, ',','')::FLOAT, 0))     over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as local_order_cost
--     , (sum(coalesce(replace(a.psp_unit_cost, ',','')::FLOAT, 0))        over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as psp_unit_cost
--     , (sum(coalesce(replace(a.hn_unit_cost, ',','')::FLOAT, 0))         over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as hn_unit_cost
--     , (sum(coalesce(replace(a.psp_fulfilment_cost, ',','')::FLOAT, 0))  over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as psp_fulfilment_cost
--     , (sum(coalesce(replace(a.psp_twistwrap_cost, ',','')::FLOAT, 0))   over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as psp_twistwrap_cost
--     , (sum(coalesce(replace(a.hn_twistwrap_cost, ',','')::FLOAT, 0))    over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as hn_twistwrap_cost
--     , (sum(coalesce(replace(a.psp_box_cost, ',','')::FLOAT, 0))         over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as psp_box_cost
--     , (sum(coalesce(replace(a.hn_box_cost, ',','')::FLOAT, 0))          over (partition by a.order_id) * RATIO_TO_REPORT(nullif(b.ratio_to_order,0)) OVER (PARTITION BY a.order_id)) as hn_box_cost

-- FROM
--     temp_cogs_group a
-- INNER JOIN finance_units b
--     ON a.line_item_id = b.line_item_id
-- )

SELECT 
      a.stock_location
    , a.line_item_id
    , a.order_id 
    , a.created_at 
    , a.local_currency
    , a.cogs_format
    , a.addon_cogs_format
    
    , a.local_unit_cost     as local_unit_cost
    , a.local_order_cost    as local_order_cost
    , a.psp_unit_cost       as local_psp_unit_cost
    , a.hn_unit_cost        as local_hn_unit_cost
    , a.psp_fulfilment_cost as local_psp_fulfilment_cost
    , a.psp_twistwrap_cost  as local_psp_twistwrap_cost
    , a.hn_twistwrap_cost   as local_hn_twistwrap_cost
    , a.psp_box_cost        as local_psp_box_cost
    , a.hn_box_cost         as local_hn_box_cost
    , a.hn_insert_cost      as local_hn_insert_cost
    
    , a.local_unit_cost     / b.rate  as unit_cost
    , a.local_order_cost    / b.rate  as order_cost
    , a.psp_unit_cost       / b.rate  as psp_unit_cost
    , a.hn_unit_cost        / b.rate  as hn_unit_cost
    , a.psp_fulfilment_cost / b.rate  as psp_fulfilment_cost
    , a.psp_twistwrap_cost  / b.rate  as psp_twistwrap_cost
    , a.hn_twistwrap_cost   / b.rate  as hn_twistwrap_cost
    , a.psp_box_cost        / b.rate  as psp_box_cost
    , a.hn_box_cost         / b.rate  as hn_box_cost
    , a.hn_insert_cost      / b.rate  as hn_insert_cost
FROM temp_cogs_group a
    INNER JOIN fx b
        ON b.currency = a.local_currency
            AND b.date = a.created_at::DATE
GROUP BY ALL