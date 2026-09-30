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