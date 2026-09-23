select to_timestamp(event_timestamp), *
from bi.dbt_production_ga4.dedupe_event_params
where event_date >= '2026-09-01'
--and event_params_value like '%cart%'
--and event_name = 'purchase'
and user_pseudo_id = '718416533.1788470369'
--and event_name = 'add_to_cart'
order by event_timestamp, event_name, event_params_key;



select distinct event_name
from bi.dbt_production_ga4.dedupe_event_params
where event_date >= '2026-09-01'
--and event_params_value like '%cart%'
--and event_name = 'purchase'
and user_pseudo_id = '718416533.1788470369'
--and event_name = 'add_to_cart'
order by 1;


select distinct event_name
from bi.dbt_production_ga4.dedupe_event_params
where event_date >= '2026-09-01'
order by 1;


select *
from bi.dbt_production_ga4.dedupe_event_params
where event_date >= '2026-09-01'
--and event_params_key = 'eventAction'
--or event_params_key = 'eventLabel'
and event_params_key = 'eventCategory'
and event_name = 'search'
order by 1
limit 1000;


select *
from bi.dbt_production_ga4.event_registry
limit 1000;


select distinct page_step
from bi.dbt_production_ga4.page_registry
where page_type = 'cart'
order by 1
limit 1000;


--event_name: add_to_cart
--event_type: cart
--event_step: cart



--event_name: page_view
--event_type: creation

select *
from bi.dbt_production_ga4.clean_events_index
where session_id = '718416533.17884703691788470368'
order by event_timestamp;

select *
from bi.DBT_PRODUCTION_GA4.clean_session_funnel_events
WHERE session_id = '718416533.17884703691788470368'
order by funnel_timestamp
limit 1000;



select *
from bi.DBT_PRODUCTION_GA4.clean_session_funnel_events
where to_date(funnel_timestamp) >= '2026-09-01'
and event_interaction_key like '%add_to_cart%'
limit 1000;