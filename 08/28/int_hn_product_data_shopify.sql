create or replace table bi.mark_dev.int_product_data as

WITH   line_items AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_line_items)
     , temp_orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_orders)
     , fulfillment_order_line AS (SELECT * FROM bi.historical_newspapers_shopify.int_fulfillment_order_line)
     , fulfillment AS (SELECT * FROM bi.historical_newspapers_shopify.int_fulfillment)
     , location AS (SELECT * FROM bi.historical_newspapers_shopify.int_location)
     , shipments as (SELECT * FROM bi.historical_newspapers_shopify.int_shipments)
     , eagle_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication)
     , eagle_shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_shipments)
     , eagle_printhouses AS (SELECT * FROM bi.dbt_production_intermediate.int_printhouses)
     , eagle_line_items AS (SELECT * FROM bi.dbt_production_intermediate.int_order_items_deduplication)
     , eagle_customisations AS (SELECT * FROM bi.dbt_production_intermediate.int_customisations_metadata)
     , psp_speed_mapping AS (SELECT * FROM bi.google_sheets.psp_speed_mapping)


,temp_line_items as
(
    SELECT * 
    FROM line_items
    WHERE lower(sku) not like '%giftbox%'
      AND lower(sku) not like '%addon%'
)

,temp_giftbox_addon as
(
    SELECT * 
    FROM line_items
    WHERE lower(sku) like '%giftbox%'
)

,temp_deluxe_addon as
(
    SELECT * 
    FROM line_items
    WHERE lower(sku) like '%addon%'
)

,dedupe_shipments as
(
    SELECT 
        order_id, 
        MAX(shipped_at_shopify::date) AS shipped_at
    FROM shipments
    GROUP BY order_id
)

select distinct
        li.order_id,
        listagg(distinct so.number, ', ') within group(order by so.number) as solidus_order_number,
        li.line_item_id,
        o.created_at,
        o.shipping_address_country,
        li.addon_id,
        li.product_id,
        li.variant_id,
        li.name,
        li.title,
        li.vendor,
        li.local_currency,
        CASE
            WHEN o.marketplace_tag = 'HISTEL' AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  li.price * 0.45
            WHEN o.marketplace_tag = 'HISMIRROR' AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  li.price * 0.5
            WHEN o.marketplace_tag IN ('LATS', 'NYDN', 'UNCOM') AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  li.price * 0.4
            ELSE
                li.price
        END AS price,
        CASE
            WHEN o.marketplace_tag = 'HISTEL' AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  li.local_price * 0.45
            WHEN o.marketplace_tag = 'HISMIRROR' AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  li.local_price * 0.5
            WHEN o.marketplace_tag IN ('LATS', 'NYDN', 'UNCOM') AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  li.local_price * 0.4
            ELSE
                li.local_price
        END AS local_price,
        li.grams,
        li.sku,
        CASE 
            WHEN li.name = 'Original Newspapers' AND DATEADD(day, -92, o.created_at) <= li.newspaper_date AND o.created_at >= '2025-08-05 06:19:56.000'
                THEN CONCAT('original-newspaper:', REPLACE(LOWER(RIGHT(li.newspaper_origin, 2)), 'gb', 'uk'), ':backissue')
            WHEN li.name = 'Original Newspapers' AND DATEADD(day, -92, o.created_at) > li.newspaper_date AND o.created_at >= '2025-08-05 06:19:56.000'
                THEN CONCAT('original-newspaper:', REPLACE(LOWER(RIGHT(li.newspaper_origin, 2)), 'gb', 'uk'))
                
            WHEN li.sku like '%alcohol%' 
                THEN REGEXP_REPLACE(li.sku, '^hn:', '')
                
            WHEN li.name = 'Original Newspapers' and coalesce(li.newspaper_origin, '') IN ('en-GB', 'en-US') AND DATEADD(day, -92, o.created_at) <= li.newspaper_date AND o.created_at < '2025-08-05 06:19:56.000'
                THEN CONCAT('original-newspaper:', REPLACE(LOWER(RIGHT(li.newspaper_origin, 2)), 'gb', 'uk'), ':backissue')
            WHEN li.name = 'Original Newspapers' and coalesce(li.newspaper_origin, '') IN ('en-GB', 'en-US') AND DATEADD(day, -92, o.created_at) > li.newspaper_date AND o.created_at < '2025-08-05 06:19:56.000'
                THEN CONCAT('original-newspaper:', REPLACE(LOWER(RIGHT(li.newspaper_origin, 2)), 'gb', 'uk'))
                
            WHEN li.name = 'Original Newspapers' and coalesce(li.newspaper_origin, '') NOT IN ('en-GB', 'en-US') AND DATEADD(day, -92, o.created_at) <= li.newspaper_date AND o.created_at < '2025-08-05 06:19:56.000'
                THEN 'original-newspaper:uk:backissue'
            WHEN li.name = 'Original Newspapers' and coalesce(li.newspaper_origin, '') NOT IN ('en-GB', 'en-US') AND DATEADD(day, -92, o.created_at) > li.newspaper_date AND o.created_at < '2025-08-05 06:19:56.000'
                THEN 'original-newspaper:uk'
        ELSE li.cogs_format END as cogs_format,
        
        li.gift_card,
        li.requires_shipping,
        li.taxable,
        li.cover_type,
        li.product_exists,
        li.fulfillment_status,
        li.tax_code,
        li.quantity,
        li.media_code,
        li.newspaper_date,
        li.newspaper_title,
        li.newspaper_origin,
        
        li.primary_category,
        li.sports_category,
        li.theme_category,
        li.secondary_category,
        li.sports_team,
        li.newspaper_brand,
        li.product_type,
        
        li.category, 
        li.royaltor,
        
case when li.cogs_format = 'Tabloid:Costco:PIL' then 'Exception'
     when li.cogs_format = 'Tabloid:Amazon:PIL' then 'Exception'
     when li.cogs_format = 'A4:Amazon:PIL' then 'Exception'
     when coalesce(TRY_CAST(da.total_page_count AS INTEGER), TRY_CAST(li.total_page_count AS INTEGER), TRY_CAST(ec.page_count AS INTEGER)) between 50 and 141 then 'Low'
     when coalesce(TRY_CAST(da.total_page_count AS INTEGER), TRY_CAST(li.total_page_count AS INTEGER), TRY_CAST(ec.page_count AS INTEGER)) between 142 and 181 then 'Mid'
     when coalesce(TRY_CAST(da.total_page_count AS INTEGER), TRY_CAST(li.total_page_count AS INTEGER), TRY_CAST(ec.page_count AS INTEGER)) between 182 and 250 then 'High'
     else 'Exception'
end as page_bucket,
coalesce(TRY_CAST(da.total_page_count AS INTEGER), TRY_CAST(li.total_page_count AS INTEGER), TRY_CAST(ec.page_count AS INTEGER)) as total_page_count,
        coalesce(da.colour_pages, li.colour_pages) as colour_pages,
        coalesce(da.mono_pages, li.mono_pages) as mono_pages,
        ga.name as addon_name,
        ga.sku as addon_sku, 
        ga.cogs_format as addon_cogs_format,
        CASE
             WHEN ga.free_giftbox = 'Yes' THEN 0
             WHEN o.marketplace_tag = 'HISTEL' AND o.created_at < '2025-06-16 09:00:00.000' and li.price_overridden = false
                THEN  ga.price * 0.45
            WHEN o.marketplace_tag = 'HISMIRROR' AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  ga.price * 0.5
            WHEN o.marketplace_tag IN ('UNCOM', 'LATS') AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  ga.price * 0.4
            WHEN o.marketplace_tag = 'NYDN' AND o.created_at < '2025-06-16 09:00:00.000' and li.price_overridden = false
                THEN  ga.price * 0.4
            ELSE
                ga.price
        END AS addon_price,
        CASE
            WHEN ga.free_giftbox = 'Yes' THEN 0
            WHEN o.marketplace_tag = 'HISTEL' AND o.created_at < '2025-06-16 09:00:00.000' and li.price_overridden = false
                THEN  ga.local_price * 0.45
            WHEN o.marketplace_tag = 'HISMIRROR' AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  ga.local_price * 0.5
            WHEN o.marketplace_tag IN ('UNCOM', 'LATS') AND o.created_at < '2025-06-11 09:00:00.000' and li.price_overridden = false
                THEN  ga.local_price * 0.4
            WHEN o.marketplace_tag = 'NYDN' AND o.created_at < '2025-06-16 09:00:00.000' and li.price_overridden = false
                THEN  ga.local_price * 0.4
            ELSE
                ga.local_price
        END AS local_addon_price,
        coalesce(ga.grams, 0) as addon_grams,

        COALESCE(CASE 
            WHEN loc.location_name = 'Baldoon' THEN 'Baldoon'
            WHEN o.all_order_tags LIKE '%POS%' THEN 'Precision Proco'
            ELSE REPLACE(ep.printhouse_name, 'Fortis', 'TJ Books')
        END, s.location,  -- Use shipment location if available
        'Unknown' -- Fallback for missing values
        ) AS stock_location,

        f.tracking_company as carrier,
        f.tracking_number as tracking_number,

        li.product_launch_date as product_launch_date,
        li.cover_colour as cover_colour,
        li.cover_design as cover_design,
        li.product_format as product_format,
        min(so.created_at) as solidus_created_at,

        li.rrp,

        da.name as addon_deluxe_name,
        da.sku as addon_deluxe_sku, 
        da.price as addon_deluxe_price,
        da.local_price as local_addon_deluxe_price,
        coalesce(da.grams, 0) as addon_deluxe_grams,

        da.product_additional_licenced_content as addon_deluxe_licencee,
        li.product_variant_additional_licenced_content as cover_licencee,

        psm.speed as us_state_speed,

        ga.free_giftbox

from temp_line_items li  
left join temp_giftbox_addon ga on li.order_id = ga.order_id and li.addon_id = ga.addon_id and li.product_type <> 'AddOn'
left join temp_deluxe_addon da on li.order_id = da.order_id and li.addon_id = da.addon_id and li.product_type <> 'AddOn'
inner join temp_orders o on li.order_id = o.order_id


left join fulfillment_order_line fol on fol.line_item_id  = li.line_item_id
LEFT JOIN fulfillment f ON fol.fulfillment_id = f.fulfillment_id
LEFT JOIN location loc ON f.location_id = loc.location_id

left join shipments s on o.order_id = s.order_id

left join eagle_orders so on (o.order_id::varchar = so.reseller_order_number::varchar) and so.state <> 'canceled' and so.shipment_state <> 'canceled'
left join eagle_shipments ss on so.id = ss.order_id
left join eagle_printhouses ep on ep.id = ss.printhouse_id

left join eagle_line_items eli on li.line_item_id = eli.reseller_line_item_reference::varchar
left join eagle_customisations ec on ec.order_item_id = eli.id

left join dedupe_shipments ds on o.order_id = ds.order_id

LEFT JOIN psp_speed_mapping psm
    ON LOWER(o.shipping_address_province) = LOWER(psm.state)
    AND LOWER(stock_location) = LOWER(psm.psp)
    AND ds.shipped_at BETWEEN TO_DATE(psm.effective_from, 'DD/MM/YYYY') AND TO_DATE(psm.effective_to, 'DD/MM/YYYY')
    AND LOWER(brand) = 'hn'

group by all