--int_hn_temp_orders_shopify_30072026

create or replace table bi.mark_dev.int_temp_orders as

WITH orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_orders_deduplication)
    , order_tag AS (SELECT * FROM bi.historical_newspapers_shopify.int_order_tag)
    , promo_codes AS (SELECT * FROM bi.mark_dev.int_promo_codes)
    , sales_taxes as (SELECT * FROM bi.google_sheets.hn_sales_tax)


--This CTE creates a hash used to identify new or repat customers, retail orders will generally hash based on the email address, MP and trade orders will always hash on the shipping address as the email isn't included in the import
, temp_orders as (
    SELECT  orders.order_id,
        MD5(COALESCE(NULLIF(user_email, ''),NVL(shipping_address_address_1, '') || NVL(shipping_address_postcode, ''))) AS hn_user_id
    FROM orders 
)


SELECT
        o.order_id,
        o.order_number,
        o.financial_status,
        o.fulfillment_status,
        o.confirmed,
        o.created_at,
        o.updated_at,
        o.processed_at,
        o.taxes_included,
        o.currency,
        o.order_price_without_shipping,
        o.order_tax,
        o.order_price,
        o.order_discounts,
        o.local_discount,
        o.local_discount_currency,
        o.order_weight,
        o.source_name,
        o.buyer_accepts_marketing,
        o.customer_id,
        o.user_id,
        tmp.hn_user_id,
        o.user_email,
        o.customer_locale,
        o.shipping_address_address_1,
        o.shipping_address_address_2,
        o.shipping_address_city,
        o.shipping_address_country,
        o.shipping_address_country_code,
        o.shipping_address_province,
        o.shipping_address_postcode,
        o.billing_address_phone,
        o.billing_address_address_1,
        o.billing_address_address_2,
        o.billing_address_city,
        o.billing_address_country,
        o.billing_address_country_code,
        o.billing_address_postcode,
        o.referring_site,
        o.cancel_reason,
        o.cancelled_at,
        o.closed_at,
        ot.order_tag,
        ot.marketplace_tag,
        ot.reorder_tag,
        ot.all_order_tags,
        dcd.promo_code,
        dcd.promo_code_shipping,
        dcd.promo_code_value,
        dcd.promo_code_value_type,
        dcd.promo_code_shipping_value,
        dcd.promo_code_shipping_value_type,
        coalesce(bst.percentage::integer, 0) + coalesce(rst.percentage::integer, 0) as sales_tax_percentage
from orders o 
left join temp_orders tmp on o.order_id = tmp.order_id
left join order_tag ot on ot.order_id = o.order_id
left join promo_codes dcd on o.order_id = dcd.order_id
left join sales_taxes bst on o.shipping_address_country = bst.shipping_country and o.created_at::date >= bst.date_from::date and bst.shipping_region is null and ot.marketplace_tag is null
left join sales_taxes rst on o.shipping_address_country = rst.shipping_country and o.shipping_address_province = rst.shipping_region and o.created_at::date >= rst.date_from::date and rst.shipping_region is not null and ot.marketplace_tag is null


where 
    cancelled_at is null 
and COALESCE(ot.all_order_tags, '') not like '%TEST%'
and COALESCE(ot.all_order_tags, '') not like '%OpsCS_Exclude%'