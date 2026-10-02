CREATE OR REPLACE TABLE bi.mark_dev.fct_plucky_order_items_shopify AS

WITH temp_orders AS (SELECT * FROM bi.plucky_shopify.int_temp_orders)
, unit_and_profit AS (SELECT * FROM bi.plucky_shopify.int_finance_unit_profit_and_loss)
, shipments as (select * from bi.mark_dev.int_plucky_shipments_shopify)
, product_data as (select * from bi.plucky_shopify.int_product_data)
    

, base as (
SELECT
unit_and_profit.line_item_id,
temp_orders.created_at, 
max(shipments.expected_shipping_date_solidus) as expected_ship_date,
unit_and_profit.order_number, 
temp_orders.hn_user_id as user_id, 
case when temp_orders.user_email like '%wonderbly%' or temp_orders.user_email like '%historic-newspapers%' THEN TRUE ELSE FALSE END AS is_employee,
temp_orders.financial_status as order_state, 
unit_and_profit.order_number as reseller_reference, 
temp_orders.promo_code as promo_code,
coalesce(unit_and_profit.paid_at, temp_orders.created_at) as paid_at,
unit_and_profit.payment_provider as payment_type,
product_data.title as product_name, 
product_data.sku, 
product_data.stock_location, 
case when min(lower(temp_orders.fulfillment_status)) = 'fulfilled' or (min(lower(temp_orders.fulfillment_status)) is null and min(shipments.shipped_at_solidus) is not null)
     then max(coalesce(shipments.shipped_at_solidus, shipments.shipped_at_shopify)) 
     end as shipped_at,
max(shipments.shipment_type_2) as shipping_method, 
unit_and_profit.carrier,
temp_orders.shipping_address_country as shipping_country_name,
temp_orders.shipping_address_address_1 as address_1,
temp_orders.shipping_address_address_2 as address_2,
temp_orders.shipping_address_city as shipping_city,
upper(temp_orders.shipping_address_province) as shipping_country_state,
temp_orders.shipping_address_postcode as postcode,
product_data.product_launch_date,
unit_and_profit.discount,
unit_and_profit.adjustment,
unit_and_profit.revenue_post_discount,
unit_and_profit.net_revenue,
unit_and_profit.net_revenue_shipping,
unit_and_profit.local_net_revenue_shipping,
unit_and_profit.local_income,
--unit_and_profit.local_adjusted_price_without_addons,
unit_and_profit.income,
unit_and_profit.gross_revenue,
unit_and_profit.rate,
unit_and_profit.currency as local_currency,
unit_and_profit.gross_profit,
unit_and_profit.unit_cost,
unit_and_profit.order_cost,
unit_and_profit.production_cost,
unit_and_profit.payment_fees,
unit_and_profit.psp_unit_cost,
unit_and_profit.plucky_unit_cost,
unit_and_profit.psp_fulfilment_cost,
unit_and_profit.psp_twistwrap_cost,
unit_and_profit.plucky_twistwrap_cost,
unit_and_profit.psp_box_cost,
unit_and_profit.plucky_box_cost,
unit_and_profit.cogs_format,
unit_and_profit.addon_cogs_format,
unit_and_profit.shipping_margin,
unit_and_profit.shipping_cost,
unit_and_profit.weight_in_grams::varchar as weight_in_grams,
unit_and_profit.weight_ratio,
unit_and_profit.shipping_type,
unit_and_profit.adjusted_price_without_addons,
unit_and_profit.addon_price,
unit_and_profit.local_addon_price,
unit_and_profit.usd_rate,
unit_and_profit.local_net_revenue,
unit_and_profit.local_discount,
unit_and_profit.local_adjustment,

max(shipments.shipped_at_shopify) as shipped_at_shopify,
max(shipments.shipped_at_solidus) as shipped_at_solidus,
temp_orders.all_order_tags,
unit_and_profit.local_order_cost,
unit_and_profit.local_unit_cost,
unit_and_profit.local_psp_unit_cost, 
unit_and_profit.local_plucky_unit_cost,
unit_and_profit.local_psp_fulfilment_cost,
unit_and_profit.local_psp_twistwrap_cost,
unit_and_profit.local_plucky_twistwrap_cost,
unit_and_profit.local_psp_box_cost,
unit_and_profit.local_plucky_box_cost,
product_data.page_bucket,
product_data.total_page_count,
product_data.colour_pages,
product_data.mono_pages,

product_data.tracking_number,
case when temp_orders.reorder_tag = 'Reordered' then 'Yes' else 'No' end as reorder_tag,
temp_orders.promo_code_shipping,
product_data.solidus_order_number,
product_data.cover_colour,
product_data.cover_design,
product_data.product_format,
--unit_and_profit.local_royalty_fees,
product_data.carrier as carrier_shopify,
product_data.solidus_created_at,
unit_and_profit.local_rrp as local_rrp,
product_data.cover_type,

unit_and_profit.local_sales_tax_amount,
max(shipments.expected_delivery_date_solidus) as expected_delivery_date,
unit_and_profit.order_id,
concat('https://admin.shopify.com/store/e51b1a-69/orders/', unit_and_profit.order_id) as shopify_url,

product_data.addon_sku as addon_giftbox_sku,
product_data.addon_name as addon_giftbox_name,

unit_and_profit.gross_revenue_product,
unit_and_profit.gross_revenue_giftbox,
unit_and_profit.net_revenue_product,
unit_and_profit.net_revenue_giftbox,

unit_and_profit.gross_revenue_shipping,

max(shipments.expected_shipping_date_solidus_local) as expected_ship_date_local,
case when min(lower(temp_orders.fulfillment_status)) = 'fulfilled' or (min(lower(temp_orders.fulfillment_status)) is null and min(shipments.shipped_at_solidus) is not null)
     then max(coalesce(shipments.shipped_at_solidus_local, shipments.shipped_at_shopify_local, shipments.shipped_at_solidus, shipments.shipped_at_shopify)) 
     end as shipped_at_local,
timezone_adjustment,

case when coalesce(expected_ship_date_local, expected_ship_date) > coalesce(shipped_at_local, shipped_at) then null 
     else ltrim(concat(case when floor(datediff(seconds, coalesce(expected_ship_date_local, expected_ship_date), coalesce(shipped_at_local, shipped_at))/60/60/24) = 0 
                            then '' when floor(datediff(seconds, coalesce(expected_ship_date_local, expected_ship_date), coalesce(shipped_at_local, shipped_at))/60/60/24) = 1 
                            then '1 day' else concat(floor(datediff(seconds, coalesce(expected_ship_date_local, expected_ship_date), coalesce(shipped_at_local, shipped_at))/60/60/24), ' days') end, ' ',  --late days
    concat( lpad(floor(datediff(seconds, coalesce(expected_ship_date_local, expected_ship_date), coalesce(shipped_at_local, shipped_at))/60/60%24)::STRING, 2, '0'),':', --late hours
            lpad(floor(datediff(seconds, coalesce(expected_ship_date_local, expected_ship_date), coalesce(shipped_at_local, shipped_at))/60%60)::STRING, 2, '0'),':', --late minutes
            lpad(floor(datediff(seconds, coalesce(expected_ship_date_local, expected_ship_date), coalesce(shipped_at_local, shipped_at))%60)::STRING, 2, '0')))) --late seconds 
end as late_by,

max(shipments.tth_working_days) as tth_working_days

from unit_and_profit 
inner join  temp_orders on temp_orders.order_id = unit_and_profit.order_id
left join shipments on shipments.order_id = unit_and_profit.order_id
left join product_data on product_data.line_item_id = unit_and_profit.line_item_id
where temp_orders.created_at::date >= '2025-02-11'

GROUP BY ALL
)

, ranked_orders as (
    select *,  rank() over (partition by user_id order by paid_at asc) as order_rank
from base
)

select *, case when order_rank = 1 then 'New' else 'Repeat' end as customer_type
       
from ranked_orders