--fct_hn_reorders_shopify_300726

--create or replace table bi.mark_dev.fct_hn_reorders_shopify as

WITH orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_orders_deduplication where order_id in (13037693632896, 13323018043776))
    ,order_tag AS (SELECT * FROM bi.mark_dev.int_hn_order_tag_shopify)
    ,line_items AS (SELECT * FROM bi.historical_newspapers_shopify.int_line_items_deduplcation)
    ,fulfillment_order_line AS (SELECT * FROM bi.historical_newspapers_shopify.int_fulfillment_order_line)
    ,fulfillment AS (SELECT * FROM bi.historical_newspapers_shopify.int_fulfillment)
    ,location AS (SELECT * FROM bi.historical_newspapers_shopify.int_location)
    ,shipments as (SELECT * FROM bi.historical_newspapers_shopify.int_shipments)
    ,eagle_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication)
    ,eagle_shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_shipments)
    ,eagle_printhouses AS (SELECT * FROM bi.dbt_production_intermediate.int_printhouses)
    
,replacement_orders AS
(
SELECT a.order_id, a.customer_id
FROM orders a
    INNER JOIN order_tag b
        ON a.order_id = b.order_id
WHERE lower(b.all_order_tags) LIKE '%replacement%' OR lower(b.all_order_tags) LIKE '%rplc%'
)

,reordered_orders AS
(
SELECT a.order_id, a.customer_id
FROM orders a
    INNER JOIN order_tag b
        ON a.order_id = b.order_id
WHERE lower(b.all_order_tags) LIKE '%reordered%' OR lower(b.all_order_tags) LIKE '%orig%'
)

,order_link AS
(
SELECT DISTINCT
    a.order_id AS reordered_order_id, 
    b.order_id AS replacement_order_id
FROM reordered_orders a
    FULL OUTER JOIN replacement_orders b
        ON a.customer_id = b.customer_id
            AND a.order_id != b.order_id
)

SELECT
    ol.reordered_order_id AS original_order_id,
    ol.replacement_order_id,
    o1.order_number AS original_order_number,
    o2.order_number AS replacement_order_number,
    o1.processed_at AS original_paid_at,
    CASE WHEN MIN(LOWER(o1.fulfillment_status)) = 'fulfilled'
    THEN MAX(COALESCE(s.shipped_at_solidus_local, s.shipped_at_shopify_local, s.shipped_at_solidus, s.shipped_at_shopify)) 
    END AS original_ship_local,
    CASE WHEN MIN(LOWER(o2.fulfillment_status)) = 'fulfilled'
    THEN MAX(COALESCE(s2.shipped_at_solidus_local, s2.shipped_at_shopify_local, s2.shipped_at_solidus, s2.shipped_at_shopify)) 
    END AS replacement_ship_local,
    COALESCE(ot.cs_category_code, ot2.cs_category_code) AS category_code,
    COALESCE(ot.cs_category, ot2.cs_category) AS category_name,
    COALESCE(ot.cs_reason, ot2.cs_reason) AS reason,
    COALESCE(CASE 
            WHEN loc.location_name = 'Baldoon' THEN 'Baldoon'
            ELSE REPLACE(ep.printhouse_name, 'Fortis', 'TJ Books')
        END, s.location,  -- Use shipment location if available
        'Unknown' -- Fallback for missing values
        ) AS original_stock_location,
    COALESCE(CASE 
         WHEN loc2.location_name = 'Baldoon' THEN 'Baldoon'
         ELSE REPLACE(ep2.printhouse_name, 'Fortis', 'TJ Books')
     END, s2.location,  -- Use shipment location if available
     'Unknown' -- Fallback for missing values
     ) AS replacement_stock_location,
    l1.line_item_id AS original_line_item_id,
    l2.line_item_id AS replacement_line_item_id,
    l2.sku AS replacement_sku,
    l2.name AS replacement_product_name
    FROM order_link ol
    LEFT JOIN orders o1
        ON ol.reordered_order_id = o1.order_id
    LEFT JOIN orders o2
        ON ol.replacement_order_id = o2.order_id   
    LEFT JOIN order_tag ot
        ON o1.order_id = ot.order_id
            AND lower(ot.all_order_tags) LIKE '%reordered%'
    LEFT JOIN order_tag ot2
        ON o1.order_id = ot2.order_id
            AND lower(ot2.all_order_tags) LIKE 'orig_%'
    LEFT JOIN line_items l1
        ON o1.order_id = l1.order_id
    LEFT JOIN line_items l2
        ON o2.order_id = l2.order_id
            AND l1.sku = l2.sku
        
    LEFT JOIN fulfillment_order_line fol 
        ON fol.line_item_id  = l1.line_item_id
    LEFT JOIN fulfillment f 
        ON fol.fulfillment_id = f.fulfillment_id
    LEFT JOIN location loc 
        ON f.location_id = loc.location_id
    LEFT JOIN shipments s 
        ON l1.order_id = s.order_id
    LEFT JOIN eagle_orders so 
        ON (l1.order_id::varchar = so.reseller_order_number::varchar) and so.state <> 'canceled' and so.shipment_state <> 'canceled'
    LEFT JOIN eagle_shipments ss 
        ON so.id = ss.order_id
    LEFT JOIN eagle_printhouses ep 
        ON ep.id = ss.printhouse_id  

    LEFT JOIN fulfillment_order_line fol2 
        ON fol2.line_item_id  = l2.line_item_id
    LEFT JOIN fulfillment f2 
        ON fol2.fulfillment_id = f2.fulfillment_id
    LEFT JOIN location loc2
        ON f2.location_id = loc2.location_id
    LEFT JOIN shipments s2
        ON l2.order_id = s2.order_id
    LEFT JOIN eagle_orders so2
        ON (l2.order_id::varchar = so2.reseller_order_number::varchar) and so2.state <> 'canceled' and so2.shipment_state <> 'canceled'
    LEFT JOIN eagle_shipments ss2 
        ON so2.id = ss2.order_id
    LEFT JOIN eagle_printhouses ep2 
        ON ep2.id = ss2.printhouse_id  

    GROUP BY ALL