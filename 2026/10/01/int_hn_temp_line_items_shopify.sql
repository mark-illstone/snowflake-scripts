


WITH line_items_raw AS (SELECT * FROM bi.historical_newspapers_shopify.int_line_items_deduplcation)
,incremental_page_count AS (SELECT * FROM bi.historical_newspapers_shopify.int_incremental_page_counts)
,incremental_rrp AS (SELECT * FROM bi.historical_newspapers_shopify.int_incremental_rrp)
,price_override AS (SELECT * FROM bi.historical_newspapers_shopify.int_price_override)
,orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_orders)
,promo_codes AS (SELECT * FROM bi.historical_newspapers_shopify.int_promo_codes)

,line_items_temp AS
(
SELECT
    li.*,
    ip.page_count as page_count_corrected,
    ir.rrp as rrp_corrected,
    CASE 
        WHEN LOWER(sku) LIKE '%giftbox%' AND pc.promo_code_value = '100' AND pc.promo_code_value_type = 'percentage' 
        THEN 'Yes'
    END AS free_giftbox
FROM line_items_raw li
    LEFT JOIN incremental_page_count ip
        ON li.line_item_id = ip.line_item_id
    LEFT JOIN incremental_rrp ir
        ON li.line_item_id = ir.line_item_id
    LEFT JOIN promo_codes pc
        ON li.line_item_id = pc.line_item_id
)

,partial_refund as
(
select 
    a.order_id, 
    count(line_item_id) as line_count, 
    count(refund_order_line_id) as refund_line_count
from bi.historical_newspapers_shopify.int_orders_deduplication a
left join bi.historical_newspapers_shopify.int_line_items_deduplcation b
    on a.order_id = b.order_id
where a.financial_status = 'partially_refunded'
and b.sku not like '%giftbox%'
group by 1
)

,numbers AS 
(
SELECT seq4() AS seq4 
FROM TABLE(GENERATOR(ROWCOUNT => 100)) 
)

--split line items into new line items where quantity is greater than 1
    ,expanded_line_items AS (
    
    SELECT 
        order_id,
        -- Keep the original line item ID for the first item, add suffix for additional items
        CASE 
            WHEN ROW_NUMBER() OVER (PARTITION BY order_id, line_item_id ORDER BY seq4) = 1 
            THEN line_item_id 
            ELSE line_item_id || '-' || (ROW_NUMBER() OVER (PARTITION BY order_id, line_item_id ORDER BY seq4) - 1)
        END AS line_item_id,
        product_id,
        variant_id,
        name,
        title,
        vendor,
        local_currency,
        price,
        local_price,
        grams,
        sku,
        gift_card,
        requires_shipping,
        taxable,
        cover_type,
        product_exists,
        fulfillment_status,
        tax_code,
        1 AS quantity,  -- Each new row gets quantity 1
        media_code,
        newspaper_date,
        newspaper_title,
        newspaper_origin,
        addon_id,
        category,
        royaltor,
        page_count_corrected,

        primary_category,
        sports_category,
        theme_category,
        secondary_category,
        sports_team,
        newspaper_brand,
        product_type,
        product_launch_date,
        cover_colour,
        cover_design,
        product_format,

        refund_order_line_id,
        fulfillment_order_line_id,
        rrp_corrected,

        product_additional_licenced_content,
        product_variant_additional_licenced_content,

        free_giftbox

    FROM line_items_temp
    JOIN numbers gen ON gen.seq4 < quantity -- Generate rows based on quantity
    WHERE quantity > 1

    UNION ALL

    SELECT 
        order_id,
        line_item_id, -- Keep original line item ID for quantity = 1
        product_id,
        variant_id,
        name,
        title,
        vendor,
        local_currency,
        price,
        local_price,
        grams,
        sku,
        gift_card,
        requires_shipping,
        taxable,
        cover_type,
        product_exists,
        fulfillment_status,
        tax_code,
        quantity,
        media_code,
        newspaper_date,
        newspaper_title,
        newspaper_origin,
        addon_id,
        category, 
        royaltor,
        page_count_corrected,

        primary_category,
        sports_category,
        theme_category,
        secondary_category,
        sports_team,
        newspaper_brand,
        product_type,
        product_launch_date,
        cover_colour,
        cover_design,
        product_format,

        refund_order_line_id,
        fulfillment_order_line_id,
        rrp_corrected,
        
        product_additional_licenced_content,
        product_variant_additional_licenced_content,

        free_giftbox

    FROM line_items_temp
    WHERE quantity = 1
)

select 
        el.order_id,
        el.line_item_id,
        product_id,
        variant_id,
        name,
        title,
        vendor,
        el.local_currency,
        case
            when sku LIKE '%giftbox%' 
        then coalesce(po.addon_price, price)
        else coalesce(po.item_price, price)
        end as price,
        --price,
        case
        when sku LIKE '%giftbox%' 
        then coalesce(po.local_addon_price, local_price)
        else coalesce(po.local_item_price, local_price)
        end as local_price,
        --local_price,
        grams,
        CASE 
            WHEN sku LIKE '%enhanced-foil%'
            THEN coalesce(REGEXP_SUBSTR(sku, '^[^:]+:[^:]+:([^:]+:.+)', 1, 1, 'e', 1), sku) 
            ELSE CONCAT('hn:', 
                CASE 
                    WHEN name = 'Original Newspapers' 
                    THEN concat('newspaper','-', media_code,'-',newspaper_date)             
                    ELSE coalesce(REGEXP_SUBSTR(sku, '^[^:]+:[^:]+:([^:]+:[^:-]+)', 1, 1, 'e', 1), sku) 
                END) 
        END as cogs_format,
        sku,
        gift_card,
        requires_shipping,
        taxable,
        cover_type,
        product_exists,
        fulfillment_status,
        tax_code,
        quantity,
        media_code,
        TO_DATE(LEFT(REGEXP_REPLACE(newspaper_date::VARCHAR, '[^0-9]', ''), 8), 'YYYYMMDD') as newspaper_date,
        newspaper_title,
        newspaper_origin,
        addon_id,
        
        primary_category,
        sports_category,
        theme_category,
        secondary_category,
        sports_team,
        newspaper_brand,
        product_type,
        product_launch_date,
        cover_colour,
        cover_design,
        product_format,

        category, 
        royaltor,
        SPLIT_PART(page_count_corrected, '/', 1) AS total_page_count,
        SPLIT_PART(page_count_corrected, '/', 2) AS colour_pages,
        COALESCE(NULLIF(total_page_count, ''), 0)::INTEGER - COALESCE(NULLIF(colour_pages, ''), 0)::INTEGER as mono_pages,
        rrp_corrected as rrp,

        case when po.line_item_id is not null then true else false end as price_overridden,

        product_additional_licenced_content,
        product_variant_additional_licenced_content,

        free_giftbox
        
from expanded_line_items  el
left join price_override po
    on el.line_item_id = po.line_item_id
left join partial_refund pr
    ON el.order_id = pr.order_id
        AND pr.line_count = pr.refund_line_count
WHERE 
    (refund_order_line_id IS NULL or pr.order_id is not null)
AND el.order_id  NOT IN (SELECT order_id FROM orders WHERE financial_status = 'refunded')
QUALIFY ROW_NUMBER() OVER (PARTITION BY el.line_item_id, el.order_id ORDER BY el.line_item_id DESC) = 1