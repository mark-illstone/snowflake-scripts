select *
from bi.google_sheets.working_days_by_market;

select *
from bi.google_sheets.bank_holidays_by_market;


select *
from bi.mark_dev.int_shipping_calendar;


select count(*)
from bi.mark_dev.dim_shipping_address;

--12535479

select count(*)
from bi.dbt_production_models.dim_shipping_address;

-- 12534956


select *
from bi.mark_dev.dim_shipping_address
where expected_shipping_date is not null
and expected_delivery_date is not null
and ship_country = 'United Kingdom'
order by expected_shipping_date desc;



select *
from bi.mark_dev.int_shipping_calendar
where market_code = 'DEFAULT';


SELECT shipping_service, cal_date, iso_day_of_week, has_config,
       is_service_day, is_working_day, working_day_seq
FROM bi.mark_dev.int_shipping_calendar
WHERE market_code = 'DEFAULT'
  AND cal_date BETWEEN '2026-09-28' AND '2026-10-04'
ORDER BY shipping_service, cal_date;


SELECT market_code, COUNT_IF(has_config) AS days_with_config, COUNT(*) AS days
FROM bi.mark_dev.int_shipping_calendar
GROUP BY market_code
ORDER BY market_code;



select count(*), order_id
from bi.mark_dev.dim_shipping_address
group by order_id
having count(*) > 1
limit 1000;


select count(*), order_id
from bi.dbt_production_models.dim_shipping_address
group by order_id
having count(*) > 1
limit 1000;



select *
from bi.mark_dev.dim_shipping_address
where shipping_id is null
and expected_shipping_date is not null
order by expected_shipping_date desc
limit 1000;



select count(*), shipping_id
from bi.mark_dev.dim_shipping_address
group by shipping_id
having count(*) > 1
limit 1000;


select count(*), shipping_id
from bi.dbt_production_models.dim_shipping_address
group by shipping_id
having count(*) > 1
limit 1000;


with cte1 as
(
select *
from bi.mark_dev.dim_shipping_address
where shipping_id is null
)
,cte2 as
(
select *
from bi.dbt_production_models.dim_shipping_address
where shipping_id is null  
)
select *
from cte1
where order_id not in
(
    select order_id from cte2
);


select *
from bi.mark_dev.dim_shipping_address
where order_id = 22581683;



select *
from bi.dbt_production_models.dim_shipping_address
where order_id = 22581683;


select count(*), sum(net_revenue)
from bi.mark_dev.fct_order_items;

--13772731	402173904.837822

select count(*), sum(net_revenue)
from bi.dbt_production_models.fct_order_items;

--13772731	402173904.837822



select tth_working_days, *
from bi.mark_dev.fct_order_items
limit 1000;




select *
from bi.mark_dev.int_hn_shipments_shopify
where order_number in
(
'#HN868631',
'#HN868591',
'#HN868634'
)
limit 1000;



select tth_working_days, expected_ship_date, expected_delivery_date
from bi.mark_dev.fct_hn_order_items_shopify
order by paid_at desc
limit 1000;


select count(*), order_id
from bi.fivetran_shopify_test_19.fulfillment_event
group by 2
having count(*) > 1;


select *
from bi.fivetran_shopify_test_19.fulfillment_event
where created_at like '2025-07%';


select distinct name
from bi.fivetran_shopify_test_19.order_note_attribute
order by name
limit 1000;


select *
from bi.fivetran_shopify_test_19.order_note_attribute
where order_id = 13530295533952;


select note_attributes
from bi.fivetran_shopify_test_19."ORDER"
--where note_attributes like '%estimated%'
where id = 13530295533952
limit 1000;

select *
from bi.fivetran_shopify_test_19.order_line
where order_id = 12122302808448;

select *
from bi.mark_dev.int_hn_line_items_deduplication_shopify
where product_type in ('POD Book', 'Historic Original')
order by order_id desc;


select *
from bi.mark_dev.int_hn_temp_line_items_shopify
limit 1000;



select *
from bi.mark_dev.int_hn_product_data_shopify
limit 1000;


select *
from bi.historical_newspapers_shopify.int_temp_orders
where order_number = '#SHOPLAT129123A';



select tth_working_days, expected_ship_date, expected_delivery_date, shipped_at
from bi.mark_dev.fct_hn_order_items_shopify
where product_name = 'Original Newspapers'
order by created_at desc;


select fulfill_by, *
from bi.fivetran_shopify_test_19.fulfillment_order
order by created_at desc;



select tth_working_days, shipping_type, expected_ship_date, expected_delivery_date, expected_ship_date_local, *
from bi.mark_dev.fct_plucky_order_items_shopify;


[
  {
    "name": "_heatVid",
    "order_id": null,
    "value": "6930182411356008002"
  },
  {
    "name": "_heatIdSite",
    "order_id": null,
    "value": "3361"
  },
  {
    "name": "_heatDevice",
    "order_id": null,
    "value": "3"
  },
  {
    "name": "_heatUid",
    "order_id": null,
    "value": "aaeamiea6yuqmiea"
  },
  {
    "name": "igId",
    "order_id": null,
    "value": "ig_2d488a8cf6be6ecf3053a701ab11f78bab42"
  },
  {
    "name": "Estimated between",
    "order_id": null,
    "value": "Standard: Estimated Delivery Between Monday, 05 October and Monday, 05 October"
  }
]