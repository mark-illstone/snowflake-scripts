--int_hn_finance_units_shopify_13082026

--CREATE OR REPLACE TABLE bi.mark_dev.int_finance_units as

WITH line_items AS (SELECT * FROM bi.historical_newspapers_shopify.int_product_data where order_id = 13278956945792)
, orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_orders) 
, fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)
, shipments as (SELECT * FROM bi.historical_newspapers_shopify.int_shipments)
, refund as (SELECT * FROM bi.historical_newspapers_shopify.int_refunds)
, order_adjustment as (SELECT * FROM bi.historical_newspapers_shopify.int_order_refunds)
, components AS (SELECT * FROM bi.historical_newspapers_shopify.int_finance_components)
, refund_payments as (SELECT * FROM bi.historical_newspapers_shopify.int_refund_payments)

, order_tax as (
    SELECT 
        o.order_id, 
        o.order_tax,
        max(COUNT(CASE WHEN lower(li.sku) like '%alcohol%' then 1 END) )
            OVER (PARTITION BY o.order_id) AS alcohol_item_count,
        o.shipping_address_country_code,
        COUNT(DISTINCT li.line_item_id) AS item_count
    FROM orders o
    JOIN line_items li ON o.order_id = li.order_id
    group by all
)

, order_tax_split as (
    SELECT distinct
    li.order_id, 
    li.line_item_id,
    CASE 
        WHEN lower(li.sku) like '%alcohol%' then o.order_tax / NULLIF(o.alcohol_item_count, 0)
        ELSE 0
    END AS split_tax
FROM line_items li
JOIN order_tax o ON li.order_id = o.order_id

)

, order_tax_new as (

SELECT
    li.order_id,
    li.line_item_id,
    li.price / 6 AS line_item_tax
FROM line_items li 
WHERE lower(li.sku) like '%alcohol%'

)

,us_order_tax_split as (

SELECT distinct
    li.order_id, 
    li.line_item_id,
    CASE 
        WHEN upper(o.shipping_address_country_code) = 'US' then o.order_tax / NULLIF(o.item_count, 0)
        ELSE 0
    END AS split_us_tax,
    CASE 
        WHEN upper(o.shipping_address_country_code) = 'US' then (o.order_tax / NULLIF(o.item_count, 0)) * fx.rate
        ELSE 0
    END AS local_split_us_tax
FROM line_items li
JOIN order_tax o ON li.order_id = o.order_id
JOIN fx ON li.created_at::date = fx.date AND li.local_currency = fx.currency

)

, shipping_discount as
(
SELECT
    o.order_id,
    CASE WHEN promo_code_shipping_value = 100 THEN shipment_price ELSE 0 END AS shipping_discount,
    CASE WHEN promo_code_shipping_value = 100 THEN adjusted_shipment_price ELSE 0 END AS local_shipping_discount
FROM orders o
    INNER JOIN shipments s
     ON o.order_id = s.order_id
)

, order_gross as
(
SELECT 
    li.order_id,
    SUM(COALESCE(li.local_price, 0) + COALESCE(li.local_addon_price, 0) + COALESCE(li.local_addon_deluxe_price, 0)) AS order_line_sum,
    SUM(COALESCE(li.local_price, 0)) AS order_line_sum_no_addons,
    SUM(COALESCE(li.local_addon_price, 0) + COALESCE(li.local_addon_deluxe_price, 0)) AS order_addons_sum,
    SUM(CASE WHEN li.addon_price > 0 THEN 1 ELSE 0 END) AS addon_count,
    SUM(CASE WHEN li.addon_deluxe_price > 0 THEN 1 ELSE 0 END) AS addon_deluxe_count
FROM 
    line_items li
GROUP BY
    1
HAVING SUM(COALESCE(li.local_price, 0) + COALESCE(li.local_addon_price, 0) + COALESCE(li.local_addon_deluxe_price, 0)) > 0
)

, discount_ratio as
(
SELECT      
    li.order_id,
    li.line_item_id,
    (COALESCE(li.local_price, 0) + COALESCE(li.local_addon_price, 0) + COALESCE(li.local_addon_deluxe_price, 0)) / order_line_sum AS ratio,
   -- COALESCE(li.local_price, 0) / order_line_sum AS ratio_no_addons,
    order_addons_sum / order_line_sum AS ratio_addons_to_order
FROM
    line_items li
       INNER JOIN order_gross og
            ON li.order_id = og.order_id
)

, split_discount as (
SELECT DISTINCT
        li.order_id, 
        li.line_item_id,
        o.local_discount_currency,
        CASE 
            WHEN o.promo_code IS NOT NULL 
            AND lower(o.promo_code) NOT LIKE '%test%' 
            AND lower(o.promo_code) NOT LIKE '%sample%' 
            AND lower(o.promo_code) NOT LIKE '%staff%' 
            AND free_giftbox = 'Yes' 
        THEN 0 
        ELSE (o.local_discount - sd.local_shipping_discount) * dr.ratio 
        END AS local_split_total_discount,
        sd.local_shipping_discount * dr.ratio AS local_split_shipping_discount,
        CASE WHEN li.addon_price > 0 THEN ((o.local_discount - sd.local_shipping_discount) * ratio_addons_to_order) / (addon_count + addon_deluxe_count) ELSE 0 END AS local_split_addon_discount,
        CASE WHEN li.addon_deluxe_price > 0 THEN ((o.local_discount - sd.local_shipping_discount) * ratio_addons_to_order) / (addon_count + addon_deluxe_count) ELSE 0 END AS local_split_addon_deluxe_discount,
        dr.ratio
FROM line_items li
LEFT JOIN orders o 
    ON li.order_id = o.order_id
LEFT JOIN shipping_discount sd
    ON li.order_id = sd.order_id
LEFT JOIN discount_ratio dr
    ON li.line_item_id = dr.line_item_id
LEFT JOIN order_gross og
    ON li.order_id = og.order_id
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
group by 1
)

, split_order_refund as (
SELECT
    order_id, line_item_id, refund_currency, sum(local_order_refund) as local_order_refund
FROM(
 select distinct 
        li.order_id, 
        li.line_item_id,
        o.refund_currency,
        --o.refund_amount / COUNT(*) OVER (PARTITION BY li.order_id) AS local_order_refund,
        --rp.local_payment / COUNT(*) OVER (PARTITION BY li.order_id) as local_order_refund,
        case 
            when pr.order_id is not null 
                then rp.local_payment / COUNT(*) OVER (PARTITION BY li.order_id)
            else o.refund_amount / COUNT(*) OVER (PARTITION BY li.order_id)
        end as local_order_refund
FROM line_items li
left join order_adjustment o on li.order_id = o.order_id
LEFT JOIN refund_payments rp on li.order_id = rp.order_id
left join partial_refund pr
    ON li.order_id = pr.order_id
        AND pr.line_count = pr.refund_line_count
where o.refund_type = 'refund_discrepancy'
)
GROUP BY all

)


, split_shipping_refund as (
 select distinct 
        li.order_id, 
        li.line_item_id,
        o.refund_currency,
        o.refund_amount / COUNT(*) OVER (PARTITION BY li.order_id) AS local_shipment_refund
FROM line_items li
left join order_adjustment o on li.order_id = o.order_id
where o.refund_type = 'shipping_refund'

)

, aggregated_shipments as (
    select order_id,
           sum(adjusted_shipment_price) as adjusted_shipment_price,
           max(shipped_at_shopify) as shipping_date
    from shipments
    group by all

)

, shipping_promo_code_deduction as
(
select
    a.order_id,
    case when promo_code_shipping_value_type = 'percentage' then (100 - promo_code_shipping_value) * adjusted_shipment_price
         when promo_code_shipping_value_type = 'fixed_amount' then adjusted_shipment_price - promo_code_shipping_value
         else adjusted_shipment_price
         end as discounted_shipment_price
from orders a
    inner join aggregated_shipments b
        on a.order_id = b.order_id
        
)

, rrp_temp as
(
SELECT
    line_items.line_item_id,
    (line_items.rrp + coalesce(line_items.addon_deluxe_price,0)) AS rrp,
    (line_items.rrp + coalesce(line_items.addon_deluxe_price,0)) * fx.rate AS local_rrp
FROM
    line_items
        INNER JOIN fx
            ON line_items.created_at::date = fx.date
                AND line_items.local_currency = fx.currency
        LEFT JOIN split_discount sd
            ON line_items.line_item_id = sd.line_item_id
)

,usd_fx as
(
SELECT
    line_items.line_item_id,
    fx.rate
FROM
    line_items
        INNER JOIN fx
            ON line_items.created_at::date = fx.date
                AND fx.currency = 'USD'
)

,marketplace_shipping_fix as
(
SELECT
    l.line_item_id, 
    l.order_id, 
    l.rrp AS price, 
   CASE WHEN l.price - l.rrp < 0 THEN 0 ELSE l.price - l.rrp END AS shipping
FROM
    line_items l
        INNER JOIN orders o
            ON l.order_id = o.order_id
WHERE o.marketplace_tag in ('HISETSY', 'HISNOTHS')
AND o.order_tag != 'UK'
AND o.created_at <= '2026-06-11 11:00:00.000'

UNION ALL

SELECT --rrp was reduced £10 sitewide from 11th June - have to add this back on for these US marketplaces
    l.line_item_id, 
    l.order_id, 
    l.rrp + 10 AS price, 
   CASE WHEN (l.price - l.rrp) - 10 < 0 THEN 0 ELSE l.price - l.rrp - 10 END AS shipping
FROM
    line_items l
        INNER JOIN orders o
            ON l.order_id = o.order_id
WHERE o.marketplace_tag in ('HISETSY', 'HISNOTHS')
AND o.order_tag != 'UK'
AND o.created_at > '2026-06-11 11:00:00'

)

 , temp_units AS (

SELECT distinct

line_items.order_id,

line_items.line_item_id, 

CASE 
WHEN pr.order_id IS NOT NULL
THEN  
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_price, 0)  + 
    COALESCE(line_items.local_addon_deluxe_price, 0) + 
    COALESCE(us_order_tax_split.local_split_us_tax, 0) - 
    COALESCE(split_order_refund.local_order_refund, 0)
ELSE 
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_price, 0)  + 
    COALESCE(line_items.local_addon_deluxe_price, 0) + 
    COALESCE(us_order_tax_split.local_split_us_tax, 0) - 
    COALESCE(refund.refund_amount, 0) - 
    COALESCE(split_order_refund.local_order_refund, 0)
END AS calculated_local_price,

CASE 
WHEN pr.order_id IS NOT NULL
THEN 
    ((
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_price, 0) + 
    COALESCE(line_items.local_addon_deluxe_price, 0) - 
    COALESCE(split_discount.local_split_total_discount, 0) - 
    COALESCE(order_tax_split.split_tax, 0)) - 
    COALESCE(split_order_refund.local_order_refund, 0)) * 
    COALESCE((100 - orders.sales_tax_percentage) / 100, 1)
WHEN LOWER(orders.promo_code) LIKE '%bulk%'
THEN 
    ((
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_deluxe_price, 0) - 
    COALESCE(order_tax_split.split_tax, 0) ) - 
    COALESCE(refund.refund_amount, 0) - 
    coalesce(split_order_refund.local_order_refund, 0)) * 
    COALESCE((100 - orders.sales_tax_percentage) / 100, 1)
ELSE 
    ((
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_price, 0) + 
    COALESCE(line_items.local_addon_deluxe_price, 0) - 
    COALESCE(split_discount.local_split_total_discount, 0) - 
    COALESCE(order_tax_split.split_tax, 0)) - 
    COALESCE(refund.refund_amount, 0) - 
    COALESCE(split_order_refund.local_order_refund, 0)) * 
    COALESCE((100 - orders.sales_tax_percentage) / 100, 1)
END AS local_adjusted_price,

CASE 
WHEN pr.order_id IS NOT NULL
THEN  
    ((
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_deluxe_price, 0) - 
    COALESCE(split_discount.local_split_total_discount, 0) - 
    COALESCE(split_discount.local_split_addon_deluxe_discount, 0) - 
    COALESCE(order_tax_split.split_tax, 0) ) - 
    COALESCE(split_order_refund.local_order_refund, 0)) * 
    COALESCE((100 - orders.sales_tax_percentage) / 100, 1) + 
    COALESCE(split_discount.local_split_addon_discount, 0)
WHEN LOWER(orders.promo_code) LIKE '%bulk%'
THEN 
    ((
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_deluxe_price, 0) - 
    COALESCE(order_tax_split.split_tax, 0) ) - 
    COALESCE(refund.refund_amount, 0) - 
    coalesce(split_order_refund.local_order_refund, 0)) * 
    COALESCE((100 - orders.sales_tax_percentage) / 100, 1)
ELSE 
    ((
    COALESCE(msf.price, line_items.local_price, 0) + 
    COALESCE(line_items.local_addon_deluxe_price, 0) - 
    COALESCE(split_discount.local_split_total_discount, 0) - 
    COALESCE(split_discount.local_split_addon_deluxe_discount, 0) - 
    COALESCE(order_tax_split.split_tax, 0) ) - 
    COALESCE(refund.refund_amount, 0) - 
    coalesce(split_order_refund.local_order_refund, 0)) * 
    COALESCE((100 - orders.sales_tax_percentage) / 100, 1) + 
    COALESCE(split_discount.local_split_addon_discount, 0)
 END AS local_adjusted_price_without_addons,


COALESCE(split_discount.local_split_total_discount, 0) + COALESCE(split_discount.local_split_shipping_discount, 0) AS local_discount,

CASE WHEN line_items.created_at >= '2025-04-04 17:00:00' THEN COALESCE(order_tax_new.line_item_tax, 0)
     ELSE COALESCE(order_tax_split.split_tax, 0) 
     END AS local_vat,


orders.created_at, 
orders.order_number, 
line_items.local_currency, 

CASE
    WHEN msf.line_item_id IS NOT NULL 
    THEN msf.shipping
    ELSE shipping_promo_code_deduction.discounted_shipment_price  / COUNT(distinct line_items.line_item_id) OVER (PARTITION BY line_items.order_id) 
END AS local_discounted_shipment_price,

CASE
    WHEN msf.line_item_id IS NOT NULL 
    THEN msf.shipping
    ELSE aggregated_shipments.adjusted_shipment_price / COUNT(distinct line_items.line_item_id) OVER (PARTITION BY line_items.order_id) 
END AS local_shipment_price,

CASE WHEN lower(orders.marketplace_tag) in ('etsy', 'hisetsy') THEN ((((local_adjusted_price + local_discounted_shipment_price) / 100 * 10.5) + 0.45) + ((((local_adjusted_price + local_discounted_shipment_price)/ 100 * 10.5) + 0.45) /100 * 20) )
         WHEN lower(orders.marketplace_tag) = 'hisnoths' THEN (((local_adjusted_price + local_discounted_shipment_price) / 100 * 25) + (((local_adjusted_price + local_discounted_shipment_price) / 100 * 25) /100 * 20)) 
         WHEN lower(orders.marketplace_tag) = 'hisebay' THEN (((local_adjusted_price + local_discounted_shipment_price) / 100 * 16.17))
         WHEN lower(orders.marketplace_tag) in ('hisamazp', 'amazusp') THEN (((local_adjusted_price + local_discounted_shipment_price) / 100 * 31.75))
         WHEN lower(orders.marketplace_tag) in ('hisamaz', 'amazus' ) THEN (((local_adjusted_price + local_discounted_shipment_price) / 100 * 15.3))
    ELSE 0
    END AS marketplace_fees,

coalesce(split_shipping_refund.local_shipment_refund, 0) as local_shipment_refund,

CASE WHEN ROUND(SUM(local_adjusted_price) OVER (PARTITION BY order_number), 2) != 0
     THEN RATIO_TO_REPORT(local_adjusted_price) OVER (PARTITION BY order_number)
     WHEN ROUND(SUM(calculated_local_price) OVER (PARTITION BY order_number), 2) != 0
     THEN RATIO_TO_REPORT(calculated_local_price) OVER (PARTITION BY order_number)
     ELSE RATIO_TO_REPORT(1) OVER (PARTITION BY order_number)
END AS ratio_to_order,

COALESCE(us_order_tax_split.split_us_tax, 0) AS us_taxes,

COALESCE(us_order_tax_split.local_split_us_tax, 0) AS local_us_taxes,

COALESCE(orders.sales_tax_percentage, 0) AS sales_taxes,

COALESCE(line_items.local_addon_price, 0) AS local_addon_price,

COALESCE(line_items.local_addon_deluxe_price, 0) AS local_addon_deluxe_price,

rrp_temp.rrp AS rrp,
rrp_temp.local_rrp AS local_rrp,

usd_fx.rate AS usd_rate,

 cp.local_price AS local_product_price,
 cg.local_price AS local_giftbox_price,
cdc.local_price AS local_deluxe_content_price,
cfc.local_price AS local_foil_cover_price,
cpc.local_price AS local_pictorial_cover_price, 

 cp.local_discount AS local_product_discount,
 cg.local_discount AS local_giftbox_discount,
cdc.local_discount AS local_deluxe_content_discount,
cfc.local_discount AS local_foil_cover_discount,
cpc.local_discount AS local_pictorial_cover_discount,

 cp.ratio_to_order AS product_ratio,
 cg.ratio_to_order AS giftbox_ratio,
cdc.ratio_to_order AS deluxe_content_ratio,
cfc.ratio_to_order AS foil_cover_ratio,
cpc.ratio_to_order AS pictorial_cover_ratio,

 cp.local_partial_refund  AS local_product_refund,
 cg.local_partial_refund  AS local_giftbox_refund,
cdc.local_partial_refund  AS local_deluxe_content_refund,
cfc.local_partial_refund  AS local_foil_cover_refund,
cpc.local_partial_refund  AS local_pictorial_cover_refund

FROM line_items
INNER JOIN orders                           ON line_items.order_id = orders.order_id
LEFT JOIN order_tax_split                   ON line_items.order_id = order_tax_split.order_id       AND line_items.line_item_id = order_tax_split.line_item_id
LEFT JOIN order_tax_new                     ON line_items.order_id = order_tax_new.order_id         AND line_items.line_item_id = order_tax_new.line_item_id 
LEFT JOIN us_order_tax_split                ON line_items.order_id = us_order_tax_split.order_id    AND line_items.line_item_id = us_order_tax_split.line_item_id
LEFT JOIN split_discount                    ON line_items.order_id = split_discount.order_id        AND line_items.line_item_id = split_discount.line_item_id
LEFT JOIN shipping_promo_code_deduction     ON shipping_promo_code_deduction.order_id = orders.order_id
LEFT JOIN refund                            ON refund.line_item_id = line_items.line_item_id
LEFT JOIN split_order_refund                ON split_order_refund.line_item_id = line_items.line_item_id 
LEFT JOIN split_shipping_refund             ON split_shipping_refund.line_item_id = line_items.line_item_id 
LEFT JOIN aggregated_shipments              ON aggregated_shipments.order_id = line_items.order_id
LEFT JOIN rrp_temp                          ON rrp_temp.line_item_id = line_items.line_item_id
LEFT JOIN usd_fx                            ON usd_fx.line_item_id = line_items.line_item_id

LEFT JOIN components  cp                    ON line_items.line_item_id = cp.line_item_id            AND cp.component_type = 'product'
LEFT JOIN components  cg                    ON line_items.line_item_id = cg.line_item_id            AND cg.component_type = 'giftbox'
LEFT JOIN components cdc                    ON line_items.line_item_id = cdc.line_item_id           AND cdc.component_type = 'deluxe_content'
LEFT JOIN components cfc                    ON line_items.line_item_id = cfc.line_item_id           AND cfc.component_type = 'foil_cover'
LEFT JOIN components cpc                    ON line_items.line_item_id = cpc.line_item_id           AND cpc.component_type = 'pictorial_cover'

LEFT JOIN partial_refund pr                 ON line_items.order_id = pr.order_id                    AND pr.line_count = pr.refund_line_count

LEFT JOIN marketplace_shipping_fix msf      ON line_items.line_item_id = msf.line_item_id

 )


SELECT DISTINCT
order_id,
line_item_id, 
calculated_local_price as local_price,
local_adjusted_price_without_addons,
local_adjusted_price_without_addons / fx.rate as adjusted_price_without_addons,
local_adjusted_price,
 calculated_local_price / fx.rate AS price,
local_adjusted_price / fx.rate AS adjusted_price,
local_discount,
local_discount / fx.rate AS discount, 
local_vat AS local_vat_value,
local_vat / fx.rate AS vat_value,
created_at, 
order_number, 
temp_units.local_currency as currency,  
local_shipment_price - local_shipment_refund as local_shipment_price,
local_discounted_shipment_price - local_shipment_refund AS local_discounted_shipment_price,
(local_shipment_price - local_shipment_refund) / fx.rate AS shipment_price,
(local_discounted_shipment_price - local_shipment_refund) / fx.rate AS discounted_shipment_price,
fx.rate,
ratio_to_order,
marketplace_fees / fx.rate as marketplace_fees,
us_taxes,
local_us_taxes,
sales_taxes as sales_taxes,
local_addon_price,
local_addon_price / fx.rate as addon_price,
local_addon_deluxe_price,
local_addon_deluxe_price / fx.rate as addon_deluxe_price,
rrp,
local_rrp,
usd_rate,
local_product_price / fx.rate as product_price,
local_giftbox_price / fx.rate as giftbox_price,
local_deluxe_content_price / fx.rate as deluxe_content_price,
local_foil_cover_price / fx.rate as foil_cover_price,
local_pictorial_cover_price / fx.rate as pictorial_cover_price,
local_product_discount / fx.rate as product_discount,
local_giftbox_discount / fx.rate as giftbox_discount,
local_deluxe_content_discount / fx.rate as deluxe_content_discount,
local_foil_cover_discount / fx.rate as foil_cover_discount,
local_pictorial_cover_discount / fx.rate as pictorial_cover_discount,
product_ratio,
giftbox_ratio,
deluxe_content_ratio,
foil_cover_ratio,
pictorial_cover_ratio,
local_product_refund / fx.rate         as product_refund,
local_giftbox_refund / fx.rate         as giftbox_refund,
local_deluxe_content_refund / fx.rate  as deluxe_content_refund,
local_foil_cover_refund / fx.rate      as foil_cover_refund,
local_pictorial_cover_refund / fx.rate as pictorial_cover_refund
FROM temp_units

JOIN fx ON temp_units.created_at::DATE = fx.date AND temp_units.local_currency = fx.currency