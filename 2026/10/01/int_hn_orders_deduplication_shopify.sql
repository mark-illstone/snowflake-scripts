CREATE OR REPLACE TABLE bi.mark_dev.int_hn_orders_deduplication_shopify AS

WITH orders AS (SELECT * FROM bi.fivetran_shopify_test_19."ORDER")


,extracted_properties AS (
    SELECT 
        orders.id,
        MAX(CASE WHEN value:"name"::STRING = 'Estimated between' THEN value:"value"::STRING ELSE NULL END) AS estimated_delivery
    FROM orders,
    LATERAL FLATTEN(input => note_attributes) AS js
    GROUP BY orders.id
)

SELECT
        orders.id::integer as order_id,
        regexp_replace(name, '[\r\n]', '')::varchar as order_number,
        financial_status::varchar as financial_status,
        fulfillment_status:: varchar as fulfillment_status,
        confirmed::varchar as confirmed,
        created_at::timestampntz as created_at,
        updated_at::timestampntz as updated_at,
        processed_at::timestampntz as processed_at,
        taxes_included::varchar as taxes_included,
        currency::varchar as currency,
        total_discounts_set:"presentment_money"."amount"::float AS local_discount,
        total_discounts_set:"presentment_money"."currency_code"::varchar AS local_discount_currency,
        subtotal_price::double as order_price_without_shipping,
        total_tax::double as order_tax,
        total_price::double as order_price,
        total_discounts::double as order_discounts,
        total_weight::integer as order_weight,
        source_name::varchar as source_name,
        buyer_accepts_marketing::varchar as buyer_accepts_marketing,
        customer_id::varchar as customer_id,
        user_id::varchar as user_id,
        email::varchar as user_email,
        customer_locale::varchar as customer_locale,
        shipping_address_address_1::varchar as shipping_address_address_1,
        shipping_address_address_2::varchar as shipping_address_address_2,
        shipping_address_city::varchar as shipping_address_city,
        shipping_address_country::varchar as shipping_address_country,
        shipping_address_country_code::varchar as shipping_address_country_code,
        shipping_address_zip::varchar as shipping_address_postcode,
        shipping_address_province::varchar as shipping_address_province,
        billing_address_phone::varchar as billing_address_phone,
        billing_address_address_1::varchar as billing_address_address_1,
        billing_address_address_2::varchar as billing_address_address_2,
        billing_address_city::varchar as billing_address_city,
        billing_address_country::varchar as billing_address_country,
        billing_address_country_code::varchar as billing_address_country_code,
        billing_address_zip::varchar as billing_address_postcode,
        referring_site::varchar as referring_site,
        cancel_reason::varchar as cancel_reason,
        cancelled_at::timestampntz as cancelled_at,
        closed_at::timestampntz as closed_at,
        note_attributes:"estimated_between"."value"::varchar AS estimated_between,
        estimated_delivery::varchar as estimated_delivery
from orders
left join extracted_properties ep
    on orders.id = ep.id

where not _fivetran_deleted 

and not test and name not like '%TEST%' and source_name != 'Matrixify App'

QUALIFY ROW_NUMBER() OVER (PARTITION BY orders.id, number ORDER BY updated_at DESC) = 1