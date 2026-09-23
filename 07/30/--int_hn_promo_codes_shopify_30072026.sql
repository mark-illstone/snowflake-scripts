--int_hn_promo_codes_shopify_30072026

create or replace table bi.mark_dev.int_promo_codes as

with promo_codes AS (SELECT * FROM bi.historical_newspapers_shopify.int_discount_application)
    ,discount_allocation AS (SELECT * FROM bi.historical_newspapers_shopify.int_discount_allocation)
    ,line_items_raw AS (SELECT * FROM bi.historical_newspapers_shopify.int_line_items_deduplcation)

, promo_codes_temp AS
(
    SELECT
        a.order_id,
        a.line_item_id,
        b.promo_code AS promo_code,
        NULL AS promo_code_shipping,
        b.promo_code_value AS promo_code_value,
        NULL AS promo_code_shipping_value,
        b.promo_code_value_type AS promo_code_value_type,
        NULL AS promo_code_shipping_value_type,
        b.fivetran_synced
    from line_items_raw a
    left join promo_codes b
    on a.order_id = b.order_id
    inner join discount_allocation c
    on a.line_item_id = c.order_line_id
    and b.index = c.discount_application_index
    and a.index = c.index
    WHERE promo_code_type = 'line_item'

    UNION ALL
    SELECT
        order_id,
        NULL as line_item_id,
        NULL AS promo_code,
        promo_code AS promo_code_shipping,
        NULL AS promo_code_value,
        promo_code_value AS promo_code_shipping_value,
        NULL AS promo_code_value_type,
        promo_code_value_type AS promo_code_shipping_value_type,
        fivetran_synced
    FROM promo_codes
    WHERE promo_code_type = 'shipping_line'
)

SELECT
    ORDER_ID,
    MIN(line_item_id) as line_item_id,
    MIN(PROMO_CODE) AS promo_code,
    MIN(PROMO_CODE_SHIPPING) AS promo_code_shipping,
    MIN(PROMO_CODE_VALUE) AS promo_code_value,
    MIN(PROMO_CODE_VALUE_TYPE) AS promo_code_value_type,
    MIN(PROMO_CODE_SHIPPING_VALUE) AS promo_code_shipping_value,
    MIN(PROMO_CODE_SHIPPING_VALUE_TYPE) AS promo_code_shipping_value_type       
FROM promo_codes_temp
GROUP BY ORDER_ID