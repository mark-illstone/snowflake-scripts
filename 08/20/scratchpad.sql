select a.slug, max(a.retail_category) as retail_category, max(a.pdc) as pdc, max(b.theme) as retail_sub_category,
    max(to_date(a.brand_launch_date, 'DD/MM/YYYY')) as brand_launch_date, max(b.evergreen_occasion) as trading_category,
    max(b.evergreen_occasion_sub_cat) as evergreen_occasion_sub_cat,
    max(b.keepsake_kids_sub_cat) as keepsake_kids_sub_cat,
    max(b.keepsake_kids) as keepsake_kids

    from bi.google_sheets.skus_mapping a
    left join bi.google_sheets.product_categories b on a.brand = b.brand
    group by slug
    order by slug;



select to_timestamp(funnel_timestamp)
, *from bi.dbt_production_ga4.clean_session_funnel_events
where session_id = '1488089077.17557338571755733856'
and funnel_type = 'product'
and funnel_step = 'creation'
order by funnel_timestamp;


select *
from bi.dbt_production_ga4.page_registry
where product_name = 'when-you-were-born-book'
and page_type = 'product'
and page_step = 'creation'
--and query_params is null
order by first_timestamp;


select product_name, min(first_timestamp), max(first_timestamp), count(*)
from bi.dbt_production_ga4.page_registry
where page_type = 'product'
and page_step = 'creation'
and product_name RLIKE '[a-z-]+'
group by product_name
order by max(first_timestamp) desc;


create or replace table bi.mark_dev.clean_session_funnel_events_to_updated_210826 as
select *
from bi.dbt_production_ga4.clean_session_funnel_events
where funnel_type = 'product'
and funnel_step = 'creation'
and product RLIKE '[a-z-]+'
and product NOT IN
(
'poetry-valentines-edition',
'poetry-birthday-edition',
'poetry-graduation-edition',
'poetry-retirement-edition',
'poetry-anniversary-edition',
'poetry-wedding-edition',
'poetry-christmas-edition',
'poetry-new-parents-edition'
);



select count(*)
from bi.mark_dev.clean_session_funnel_events_to_updated_210826
limit 1000;



select *
from bi.dbt_production_ga4.page_registry
where page_location_id = '/personalized-products/where-are-you-adult-book?-';

--/personalized-products/where-are-you-adult-book?-


select count(*)
from bi.mark_dev.clean_session_funnel_events_to_updated_210826 a
left join  bi.dbt_production_ga4.page_registry b
on concat(a.product_page_path, '?-') = b.page_location_id;

--3648774
--3648726
--3648726
--3648774



select count(*)
from bi.dbt_production_ga4.preprocess_session_funnel_events
where first_product_seen RLIKE '[a-z-]+'
limit 1000;

--458477


select a.first_product_page_path_seen, b.product_name
from bi.dbt_production_ga4.preprocess_session_funnel_events a
left join  bi.dbt_production_ga4.page_registry b
on concat(a.first_product_page_path_seen, '?-') = b.page_location_id
where first_product_seen RLIKE '[a-z-]+';



select *
from bi.mark_dev.preprocess_session_funnel_events_210826 limit 1000;