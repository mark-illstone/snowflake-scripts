select count(*), max(to_date(funnel_timestamp)), min(to_date(funnel_timestamp))
from bi.dbt_production_ga4.clean_session_funnel_events
where event_interaction_key like '%add_to_cart%';

select *
from bi.dbt_production_ga4.clean_session_funnel_events
where event_interaction_key like '%add_to_cart%'
limit 1000;

create or replace transient table bi.mark_dev.clean_session_funnel_events_15092026 clone bi.dbt_production_ga4.clean_session_funnel_events;

update bi.dbt_production_ga4.clean_session_funnel_events
set interaction_type = 'add_to_cart',
    funnel_type = 'add_to_cart',
    funnel_step = 'add_to_cart'
where event_interaction_key like '%add_to_cart%';


create or replace transient table bi.mark_dev.preprocess_session_funnel_events_15092026 clone bi.dbt_production_ga4.preprocess_session_funnel_events;

update bi.dbt_production_ga4.preprocess_session_funnel_events
set funnel_add_to_cart = 1
where session_id in
(
    select distinct session_id
    from bi.dbt_production_ga4.clean_session_funnel_events
    where funnel_type = 'add_to_cart'
);