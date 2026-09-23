

WITH line_items AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_line_items)
    ,orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_orders)
    ,fullfilment AS (SELECT * FROM bi.historical_newspapers_shopify.int_fullfilment_order_deduplication)
    ,shipping AS (SELECT * FROM bi.historical_newspapers_shopify.int_shipping_deduplication)
    ,eagle_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication)
    ,eagle_shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_shipments)
    ,eagle_printhouses AS (SELECT * FROM bi.dbt_production_intermediate.int_printhouses)
    ,price_override AS (SELECT * FROM bi.historical_newspapers_shopify.int_price_override)

    ,temp_price_override AS
    (
    select 
        order_id, 
        sum(shipping_price) as shipping_price, 
        sum(local_shipping_price) as local_shipping_price
    from price_override
    where shipping_price is not null
    group by order_id
    )

    ,base AS (

    select distinct
    o.order_id, 
    o.order_number, 
    os.shipment_id, 
    os.updated_at, 
    os.created_at, 
    os.fulfill_by, 
    CASE WHEN os.location = 'Wonderbly' then replace(ep.printhouse_name, 'Fortis', 'TJ Books') else os.location END as location, 
    os.delivery_method_min_delivery_date_time, 
    os.delivery_method_max_delivery_date_time,
    ss.shipped_at as shipped_at_solidus, 
    ss.expected_delivery_date as expected_delivery_date_solidus, 
     CASE
    WHEN ss.expected_shipping_date IS NULL
        THEN
            CASE
                WHEN DAYNAME(o.created_at) = 'Mon'
                    THEN DATEADD(day, 2, TO_DATE(o.created_at))
                WHEN DAYNAME(o.created_at) = 'Tue'
                    THEN DATEADD(day, 2, TO_DATE(o.created_at))
                WHEN DAYNAME(o.created_at) = 'Wed'
                    THEN DATEADD(day, 2, TO_DATE(o.created_at))
                WHEN DAYNAME(o.created_at) = 'Thu'
                    THEN DATEADD(day, 4, TO_DATE(o.created_at))
                WHEN DAYNAME(o.created_at) = 'Fri'
                    THEN DATEADD(day, 4, TO_DATE(o.created_at))
                WHEN DAYNAME(o.created_at) = 'Sat'
                    THEN DATEADD(day, 3, TO_DATE(o.created_at))
                WHEN DAYNAME(o.created_at) = 'Sun'
                    THEN DATEADD(day, 2, TO_DATE(o.created_at))
            END
        ELSE
                TO_TIMESTAMP(ss.expected_shipping_date)
    END AS expected_shipping_date_solidus,

    --osl.shipment_price,
    coalesce(po.shipping_price, osl.shipment_price) as shipment_price,
    osl.shipment_type,
    osl.shipment_type_2,
    --osl.local_shipping_price,
    coalesce(po.local_shipping_price, osl.local_shipping_price) as local_shipping_price,
    osl.local_shipping_currency,
    TIMESTAMPDIFF('hours', ss.expected_shipping_date, ss.expected_shipping_date_local) AS timezone_adjustment  
from orders o
inner join fullfilment os on os.order_id = o.order_id
inner join shipping osl on osl.order_id = o.order_id

left join eagle_orders so on (o.order_id::varchar = so.reseller_order_number::varchar) AND so.state <> 'canceled'
left join eagle_shipments ss on so.id = ss.order_id
left join eagle_printhouses ep on ep.id = ss.printhouse_id

left join temp_price_override po on o.order_id = po.order_id

    )

    ,shipment_cost_split AS (
    -- Step 1: Calculate the number of shipments per order and divide cost equally
    SELECT 
    order_id, 
    order_number, 
    shipment_id, 
    updated_at, 
    created_at, 
    fulfill_by, 
    location, 
    delivery_method_min_delivery_date_time, 
    delivery_method_max_delivery_date_time,
    shipped_at_solidus, 
    expected_delivery_date_solidus, 
    expected_shipping_date_solidus, 
    shipment_price,
    shipment_type,
    shipment_type_2,
    local_shipping_price,
    local_shipping_price / COUNT(*) OVER (PARTITION BY order_id) AS split_shipment_price,
    timezone_adjustment
    FROM base
)

    ,order_has_alcohol AS (
    -- Step 2: Check if an order has at least one alcohol line item
    SELECT DISTINCT order_id, 1 AS has_alcohol
    FROM line_items
    WHERE sku like '%alcohol%'
)
    
    ,shipment_with_alcohol AS (
    -- Step 3: Identify shipments that contain alcohol
    SELECT DISTINCT
        s.order_id, 
        s.shipment_id,
        MAX(CASE WHEN li.sku like '%alcohol%' THEN 1 ELSE 0 END) 
        OVER (PARTITION BY s.order_id, s.shipment_id) AS has_alcohol
    FROM fullfilment s
    LEFT JOIN line_items li ON s.order_id = li.order_id
)


    ,adjusted_shipments AS (
    -- Step 4: Adjust shipment cost by +£1/-£1 only for orders with multiple shipments
    SELECT 
        scs.order_id, 
        scs.order_number, 
        scs.shipment_id, 
        scs.updated_at as shipped_at_shopify, 
        scs.created_at, 
        scs.updated_at,
        scs.fulfill_by, 
        scs.location, 
        scs.delivery_method_min_delivery_date_time, 
        scs.delivery_method_max_delivery_date_time,
        scs.shipped_at_solidus, 
        scs.expected_delivery_date_solidus, 
        scs.expected_shipping_date_solidus, 
        scs.shipment_price,
        scs.shipment_type,
        scs.shipment_type_2,
        scs.split_shipment_price +
            CASE 
                WHEN oha.has_alcohol = 1  -- Only adjust if order has alcohol 
                     AND swa.has_alcohol = 1 
                     AND COUNT(*) OVER (PARTITION BY scs.order_id) > 1 
                     THEN 1
                WHEN oha.has_alcohol = 1  
                     AND swa.has_alcohol = 0 
                     AND COUNT(*) OVER (PARTITION BY scs.order_id) > 1 
                     THEN -1
                ELSE 0 
            END AS adjusted_shipment_price,

    DATEADD(hour, scs.timezone_adjustment, scs.updated_at)                      AS shipped_at_shopify_local,
    DATEADD(hour, scs.timezone_adjustment, scs.shipped_at_solidus)              AS shipped_at_solidus_local,
    DATEADD(hour, scs.timezone_adjustment, scs.expected_shipping_date_solidus)  AS expected_shipping_date_solidus_local,
    IFNULL(timezone_adjustment, 0) AS timezone_adjustment
            
    FROM shipment_cost_split scs
    LEFT JOIN shipment_with_alcohol swa 
        ON scs.order_id = swa.order_id 
        AND scs.shipment_id = swa.shipment_id
    LEFT JOIN order_has_alcohol oha 
        ON scs.order_id = oha.order_id
)

SELECT * FROM adjusted_shipments