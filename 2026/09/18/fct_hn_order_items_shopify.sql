create or replace table bi.mark_dev.fct_order_items as

WITH temp_orders AS (SELECT * FROM bi.mark_dev.int_temp_orders)
, unit_and_profit AS (SELECT * FROM bi.mark_dev.int_finance_units_profit_and_loss)
, shipments as (select * from bi.mark_dev.int_shipments)
, product_data as (select * from bi.mark_dev.int_product_data)
, historical_data as (select * from bi.historical_newspapers.fct_order_items)

, base as (
SELECT
unit_and_profit.line_item_id,
NULL as is_personalised, 
temp_orders.created_at, 
max(shipments.expected_shipping_date_solidus) as expected_ship_date,
product_data.newspaper_date as paper_date,
unit_and_profit.order_number, 
temp_orders.hn_user_id as user_id, 
temp_orders.financial_status as order_state, 
unit_and_profit.order_number as reseller_reference, 
temp_orders.promo_code as promo_code,
coalesce(unit_and_profit.paid_at, temp_orders.created_at) as paid_at,
unit_and_profit.payment_provider as payment_type,
product_data.title as product_name, 
unit_and_profit.rrp,
NULL as us_rrp,
NULL as product_description, 
product_data.sku, 
NULL as sku2, 
NULL as product_category, 
NULL as product_sub_category,
NULL as reseller_discount_pct, 
case when temp_orders.marketplace_tag is null and temp_orders.order_tag = 'UK' then 'NET'
     when temp_orders.marketplace_tag is null and coalesce(temp_orders.order_tag, '') != 'UK' then concat('HIS', temp_orders.order_tag)
     when lower(temp_orders.all_order_tags) like '%pos%' and lower(temp_orders.all_order_tags) not like '%postal%'
     or lower(temp_orders.all_order_tags) like '%kiosk%'
     or lower(temp_orders.promo_code) like '%westfield%' then 'POS'
     else temp_orders.marketplace_tag
end as reseller_name,
case when temp_orders.marketplace_tag in 
    ('ETSY' , 'NOTHS', 'AMAZONUK', 'AMAZONUS', 'AMAZUS', 'AMAZUSP', 'HISAMAZ', 'HISAMAZP', 'HISEBAY', 'HISETSY', 'HISNOTHS') then 'Marketplace'
     when temp_orders.marketplace_tag in 
    ('HISTEL', 'HISMBI', 'UNCOM', 'LATS', 'NYDN', 'HISMIRROR', 'WASHPS') then 'Trade'
    when lower(temp_orders.all_order_tags) like '%pos%' and lower(temp_orders.all_order_tags) not like '%postal%'
    or lower(temp_orders.all_order_tags) like '%kiosk%'
    or lower(temp_orders.promo_code) like '%westfield%' then 'POS'
     else 'Retail' 
end as reseller_channel,
'Yes' as traded_with_since_acquired_by_wonderbly,
product_data.royaltor as royalty_name,
unit_and_profit.marketplace_fees,
NULL as access_company,
'Still Trading' as is_reseller_active,
product_data.stock_location, 
NULL as stock_location_city,
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
NULL as product_code,
product_data.product_launch_date,
unit_and_profit.discount,
unit_and_profit.adjustment,
NULL as vat_code,
unit_and_profit.revenue_post_discount,
unit_and_profit.net_revenue,
unit_and_profit.net_revenue_shipping,
unit_and_profit.local_net_revenue_shipping,
unit_and_profit.local_income,
NULL as local_price_without_embossing,
unit_and_profit.local_adjusted_price_without_addons,
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
unit_and_profit.hn_unit_cost,
unit_and_profit.psp_fulfilment_cost,
unit_and_profit.psp_twistwrap_cost,
unit_and_profit.hn_twistwrap_cost,
unit_and_profit.psp_box_cost,
unit_and_profit.hn_box_cost,
unit_and_profit.royalty_fees,
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
newspaper_title,

max(shipments.shipped_at_shopify) as shipped_at_shopify,
max(shipments.shipped_at_solidus) as shipped_at_solidus,
temp_orders.order_tag,
temp_orders.marketplace_tag,
temp_orders.all_order_tags,
unit_and_profit.local_order_cost,
unit_and_profit.local_unit_cost,
unit_and_profit.local_psp_unit_cost, 
unit_and_profit.local_hn_unit_cost,
unit_and_profit.local_psp_fulfilment_cost,
unit_and_profit.local_psp_twistwrap_cost,
unit_and_profit.local_hn_twistwrap_cost,
unit_and_profit.local_psp_box_cost,
unit_and_profit.local_hn_box_cost,
product_data.page_bucket,
product_data.total_page_count,
product_data.colour_pages,
product_data.mono_pages,

primary_category,
sports_category,
theme_category,
secondary_category,
sports_team,
newspaper_brand,
product_type,

product_data.tracking_number,
case when temp_orders.reorder_tag = 'Reordered' then 'Yes' else 'No' end as reorder_tag,
temp_orders.promo_code_shipping,
product_data.solidus_order_number,
product_data.cover_colour,
product_data.cover_design,
product_data.product_format,
unit_and_profit.local_royalty_fees,
product_data.carrier as carrier_shopify,
product_data.solidus_created_at,
unit_and_profit.local_rrp as local_rrp,
product_data.cover_type,

unit_and_profit.local_sales_tax_amount,
max(shipments.expected_delivery_date_solidus) as expected_delivery_date,
unit_and_profit.order_id,
concat('https://admin.shopify.com/store/e51b1a-69/orders/', unit_and_profit.order_id) as shopify_url,

unit_and_profit.addon_deluxe_price,
unit_and_profit.local_addon_deluxe_price,
product_data.addon_sku as addon_giftbox_sku,
product_data.addon_name as addon_giftbox_name,
product_data.addon_deluxe_sku,
product_data.addon_deluxe_name,
product_data.addon_deluxe_licencee as addon_deluxe_royalty_name,
product_data.cover_licencee as cover_royalty_name,

unit_and_profit.product_royalty_fees,
unit_and_profit.cover_royalty_fees,
unit_and_profit.addon_deluxe_royalty_fees,

unit_and_profit.local_product_royalty_fees,
unit_and_profit.local_cover_royalty_fees,
unit_and_profit.local_addon_deluxe_royalty_fees,

unit_and_profit.cover_upsell_price,
unit_and_profit.local_cover_upsell_price,

unit_and_profit.gross_revenue_product,
unit_and_profit.gross_revenue_giftbox,
unit_and_profit.gross_revenue_deluxe_content,
unit_and_profit.gross_revenue_foil_cover,
unit_and_profit.gross_revenue_pictorial_cover,
unit_and_profit.net_revenue_product,
unit_and_profit.net_revenue_giftbox,
unit_and_profit.net_revenue_deluxe_content,
unit_and_profit.net_revenue_foil_cover,
unit_and_profit.net_revenue_pictorial_cover,

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

product_data.us_state_speed,
product_data.free_giftbox,

local_royalty_base_value,
royalty_base_value,

unit_and_profit.local_hn_insert_cost,
unit_and_profit.hn_insert_cost

from unit_and_profit 
inner join  temp_orders on temp_orders.order_id = unit_and_profit.order_id
left join shipments on shipments.order_id = unit_and_profit.order_id
left join product_data on product_data.line_item_id = unit_and_profit.line_item_id
where temp_orders.created_at::date >= '2025-02-11'

GROUP BY ALL


UNION ALL

select *, 

NULL as shipped_at_shopify, 
NULL as shipped_at_solidus,
NULL as order_tag,
NULL as marketplace_tag,
NULL as all_order_tags,
NULL as local_order_cost,
NULL as local_unit_cost,
NULL as local_psp_unit_cost, 
NULL as local_hn_unit_cost,
NULL as local_psp_fulfilment_cost,
NULL as local_psp_twistwrap_cost,
NULL as local_hn_twistwrap_cost,
NULL as local_psp_box_cost,
NULL as local_hn_box_cost,
NULL as page_bucket,
NULL as total_page_count,
NULL as colour_pages,
NULL as mono_pages,
case when product_category in ('Original Newspapers') then 'Original Newspapers'
     when product_category in ('Football Newspaper Books','US Sports Newspaper Books','Sports Newspaper Books','Rugby Newspaper Books') then 'Sports'
     when product_category in ('Bespoke Newspaper Books','US Bespoke Newspaper Books') then 'Date'
     when product_category in ('Theme Newspaper Books','US Theme Newspaper Books') then 'Theme'
     when product_category in ('Wines, Beers & Spirits + Paper') then 'Alcohol'
     else 'Other (Legacy)' 
end as primary_category,
NULL as sports_category,
NULL as theme_category,
NULL as secondary_category,
NULL as sports_team,
NULL as newspaper_brand,
NULL as product_type,
--NULL as newspaper_title,
NULL AS tracking_number,
NULL as reorder_tag,
NULL as promo_code_shipping,
NULL as solidus_order_number,
NULL as cover_colour,
NULL as cover_design,
NULL as product_format,
NULL as local_royalty_fees,
NULL as carrier_shopify,
NULL as solidus_created_at,
NULL as local_rrp,
NULL as cover_type,
NULL as local_sales_tax_amount,
NULL as expected_delivery_date,
NULL as order_id,
NULL as shopify_url,
NULL as addon_deluxe_price,
NULL as local_addon_deluxe_price,
NULL as addon_giftbox_sku,
NULL as addon_giftbox_name,
NULL as addon_deluxe_sku,
NULL as addon_deluxe_name,
NULL as addon_deluxe_royalty_name,
NULL as cover_royalty_name,

NULL as product_royalty_fees,
NULL as cover_royalty_fees,
NULL as addon_deluxe_royalty_fees,
NULL as local_product_royalty_fees,
NULL as local_cover_royalty_fees,
NULL as local_addon_deluxe_royalty_fees,
NULL as cover_upsell_price,
NULL as local_cover_upsell_price,

NULL as gross_revenue_product,
NULL as gross_revenue_giftbox,
NULL as gross_revenue_deluxe_content,
NULL as gross_revenue_foil_cover,
NULL as gross_revenue_pictorial_cover,
NULL as net_revenue_product,
NULL as net_revenue_giftbox,
NULL as net_revenue_deluxe_content,
NULL as net_revenue_foil_cover,
NULL as net_revenue_pictorial_cover,

NULL as gross_revenue_shipping,

NULL as expected_ship_date_local,
NULL as shipped_at_local,
NULL as timezone_adjustment,
NULL as late_by,

NULL as us_state_speed,
NULL as free_giftbox,

NULL as local_royalty_base_value,
NULL as royalty_base_value,

NULL as local_hn_insert_cost,
NULL as hn_insert_cost

from historical_data

 )

 , ranked_orders as (
     select *,  rank() over (partition by user_id order by paid_at asc) as order_rank
 from base
 )

 select *, case when order_rank = 1 then 'New' else 'Repeat' end as customer_type
       
 from ranked_orders