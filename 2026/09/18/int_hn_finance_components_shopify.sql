create or replace table bi.mark_dev.int_finance_components as

WITH line_items AS (SELECT * FROM bi.mark_dev.int_product_data)
    ,orders AS (SELECT * FROM bi.mark_dev.int_temp_orders)
    ,fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)
    ,component_prices AS (SELECT * FROM bi.google_sheets.hn_component_prices)
    ,shipments AS (SELECT * FROM bi.mark_dev.int_shipments)
    ,refunds as (SELECT * FROM bi.historical_newspapers_shopify.fct_refunds)

,line_sum as
(
 SELECT 
    o.order_id,
    SUM(coalesce(l.local_price, 0) + coalesce(l.local_addon_price, 0) + coalesce(l.local_addon_deluxe_price, 0)) as local_price
 FROM orders o
        INNER JOIN line_items l 
            ON o.order_id = l.order_id
GROUP BY 1
)

,partial_refund as
(
SELECT 
    order_id, 
    sum(refunded_amount) as partial_refund_amount
FROM bi.historical_newspapers_shopify.fct_refunds
WHERE 
    financial_status = 'partially_refunded'
AND 
order_id NOT IN (SELECT order_id FROM bi.historical_newspapers_shopify.int_line_items_deduplcation WHERE refund_order_line_id IS NOT NULL)
AND round(shipping) != round(refunded_amount)
GROUP BY 1
)

,giftbox as
(
    SELECT 
        o.order_id, 
        l.line_item_id,
        'giftbox' as component_type,
        l.local_addon_price as local_price,
        CASE
            WHEN o.promo_code_shipping_value > 0 
                THEN (o.local_discount * (l.local_addon_price / NULLIF(s.local_price, 0))) - ((sh.shipment_price * fx.rate) * (l.local_addon_price / NULLIF(s.local_price, 0)))
            ELSE
                o.local_discount * (l.local_addon_price / NULLIF(s.local_price, 0))
        END AS local_discount,      
        (sh.shipment_price * fx.rate) * (l.local_addon_price / NULLIF(s.local_price, 0)) as local_shipment_price,
        l.local_addon_price / NULLIF(s.local_price, 0) as ratio_to_order,
        l.local_currency,
        fx.rate,
        coalesce((pr.partial_refund_amount * fx.rate) * (l.local_addon_price / NULLIF(s.local_price, 0)),0) as local_partial_refund
    FROM orders o
        INNER JOIN line_items l 
            ON o.order_id = l.order_id
        LEFT JOIN line_sum s
            ON o.order_id = s.order_id
        LEFT JOIN shipments sh
            ON o. order_id = sh.order_id
        LEFT JOIN fx
            ON l.local_currency = fx.currency
            AND o.created_at::date = fx.date
        LEFT JOIN partial_refund pr
            ON o.order_id = pr.order_id
    WHERE l.addon_sku is not null
)

,deluxe_content as
(
    SELECT 
        o.order_id, 
        l.line_item_id, 
        'deluxe_content' as component_type,
        l.local_addon_deluxe_price as local_price,
        CASE
            WHEN o.promo_code_shipping_value > 0 
                THEN (o.local_discount * (l.local_addon_deluxe_price / NULLIF(s.local_price, 0))) - ((sh.shipment_price * fx.rate) * (l.local_addon_deluxe_price / NULLIF(s.local_price, 0)))
            ELSE
                o.local_discount * (l.local_addon_deluxe_price / NULLIF(s.local_price, 0))
        END AS local_discount,  
        (sh.shipment_price * fx.rate) * (l.local_addon_deluxe_price / NULLIF(s.local_price, 0)) as local_shipment_price,
        l.local_addon_deluxe_price / NULLIF(s.local_price, 0) as ratio_to_order,
        l.local_currency,
        fx.rate,
         coalesce((pr.partial_refund_amount * fx.rate) * (l.local_addon_deluxe_price / NULLIF(s.local_price, 0)), 0) as local_partial_refund
    FROM orders o
        INNER JOIN line_items l 
            ON o.order_id = l.order_id
        LEFT JOIN line_sum s
            ON o.order_id = s.order_id
        LEFT JOIN shipments sh
            ON o. order_id = sh.order_id
        LEFT JOIN fx
            ON l.local_currency = fx.currency
            AND o.created_at::date = fx.date
        LEFT JOIN partial_refund pr
            ON o.order_id = pr.order_id
    WHERE l.addon_deluxe_sku is not null
)

,pictorial_cover as
(
    SELECT 
        o.order_id, 
        l.line_item_id, 
        'pictorial_cover' as component_type,
        coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) as local_price,
        CASE
            WHEN o.promo_code_shipping_value > 0 
                THEN (o.local_discount * (coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) / NULLIF(s.local_price, 0))) - ((sh.shipment_price * fx.rate) * (coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) / NULLIF(s.local_price, 0)))
            ELSE
                o.local_discount * (coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) / NULLIF(s.local_price, 0))
        END AS local_discount,  
        (sh.shipment_price * fx.rate) * (coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) / NULLIF(s.local_price, 0)) as local_shipment_price,
        coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) / NULLIF(s.local_price, 0) as ratio_to_order,
        l.local_currency,
        fx.rate,
         coalesce((pr.partial_refund_amount * fx.rate) * (coalesce(c1.pictorial, ceil(c2.pictorial * fx.rate, 0)) / NULLIF(s.local_price, 0)), 0) as local_partial_refund
    FROM orders o
        INNER JOIN line_items l 
            ON o.order_id = l.order_id
        LEFT JOIN component_prices c1
            ON l.local_currency = c1.currency
            AND o.order_tag = c1.locale
            AND o.created_at BETWEEN TO_DATE(c1.effective_date_from, 'DD/MM/YYYY') AND TO_DATE(c1.effective_date_to, 'DD/MM/YYYY')
        LEFT JOIN component_prices c2
            ON c2.currency = 'GBP'
            AND o.created_at::date BETWEEN TO_DATE(c2.effective_date_from, 'DD/MM/YYYY') AND TO_DATE(c2.effective_date_to, 'DD/MM/YYYY')
        LEFT JOIN fx
            ON l.local_currency = fx.currency
            AND o.created_at::date = fx.date
        LEFT JOIN line_sum s
            ON o.order_id = s.order_id
        LEFT JOIN shipments sh
            ON o. order_id = sh.order_id
        LEFT JOIN partial_refund pr
            ON o.order_id = pr.order_id
    WHERE lower(l.cover_type) like '%with picture%'
)

,foil_cover as
(
    SELECT 
        o.order_id, 
        l.line_item_id, 
        'foil_cover' as component_type, 
        coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) as local_price,
        CASE
            WHEN o.promo_code_shipping_value > 0 
                THEN (o.local_discount * (coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) / NULLIF(s.local_price, 0))) - ((sh.shipment_price * fx.rate) * (coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) / NULLIF(s.local_price, 0)))
            ELSE
                o.local_discount * (coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) / NULLIF(s.local_price, 0))
        END AS local_discount,  
        (sh.shipment_price * fx.rate) * (coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) / NULLIF(s.local_price, 0)) as local_shipment_price,
        coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) / NULLIF(s.local_price, 0) as ratio_to_order,
        l.local_currency,
        fx.rate,
         coalesce((pr.partial_refund_amount * fx.rate) * (coalesce(c1.foil, ceil(c2.foil * fx.rate, 0)) / NULLIF(s.local_price, 0)),0) as local_partial_refund
    FROM orders o
        INNER JOIN line_items l 
            ON o.order_id = l.order_id
        LEFT JOIN component_prices c1
            ON l.local_currency = c1.currency
            AND o.order_tag = c1.locale
            AND o.created_at BETWEEN TO_DATE(c1.effective_date_from, 'DD/MM/YYYY') AND TO_DATE(c1.effective_date_to, 'DD/MM/YYYY')
        LEFT JOIN component_prices c2
            ON c2.currency = 'GBP'
            AND o.created_at::date BETWEEN TO_DATE(c2.effective_date_from, 'DD/MM/YYYY') AND TO_DATE(c2.effective_date_to, 'DD/MM/YYYY')
        LEFT JOIN fx
            ON l.local_currency = fx.currency
            AND o.created_at::date = fx.date
        LEFT JOIN line_sum s
            ON o.order_id = s.order_id
        LEFT JOIN shipments sh
            ON o. order_id = sh.order_id
        LEFT JOIN partial_refund pr
            ON o.order_id = pr.order_id
    WHERE lower(l.cover_type) like '%foil%'
)

,product as
(
    SELECT 
        o.order_id, 
        l.line_item_id, 
        'product' as component_type,
        l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0) as local_price, 
        CASE
            WHEN o.promo_code_shipping_value > 0 
                THEN (o.local_discount * ((l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0)) / NULLIF(s.local_price, 0))) - ((sh.shipment_price * fx.rate) *  ((l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0)) / NULLIF(s.local_price, 0)))
            ELSE
                o.local_discount * ((l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0)) / NULLIF(s.local_price, 0))
        END AS local_discount,  
        (sh.shipment_price * fx.rate) *  ((l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0)) / NULLIF(s.local_price, 0)) as local_shipment_price,
        (l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0)) / NULLIF(s.local_price, 0) as ratio_to_order,
        l.local_currency,
        fx.rate,
         coalesce((pr.partial_refund_amount * fx.rate) * ((l.local_price - coalesce(p.local_price, 0) - coalesce(f.local_price, 0)) / NULLIF(s.local_price, 0)),0) as local_partial_refund
    FROM orders o
        INNER JOIN line_items l 
            ON o.order_id = l.order_id
        LEFT JOIN pictorial_cover p
            ON l.line_item_id = p.line_item_id
        LEFT JOIN foil_cover f
            ON l.line_item_id = f.line_item_id
        LEFT JOIN line_sum s
            ON o.order_id = s.order_id
        LEFT JOIN shipments sh
            ON o. order_id = sh.order_id
        LEFT JOIN fx
            ON l.local_currency = fx.currency
            AND o.created_at::date = fx.date
        LEFT JOIN partial_refund pr
            ON o.order_id = pr.order_id
)

,component_union as
(
SELECT * FROM product
UNION ALL
SELECT * FROM giftbox
UNION ALL
SELECT * FROM deluxe_content
UNION ALL
SELECT * FROM pictorial_cover
UNION ALL
SELECT * FROM foil_cover
)

SELECT *
FROM component_union
WHERE local_price > 0