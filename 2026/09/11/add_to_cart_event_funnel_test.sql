select *
from bi.dbt_production_ga4.event_registry
limit 1000;

create or replace transient table bi.mark_dev.event_registry clone bi.dbt_production_ga4.event_registry;

select *
from bi.mark_dev.event_registry;

create table bi.mark_dev.funnel_event_gsheet as
select 1 as idx, 'add_to_cart' as event_name, 'add_to_cart' as funnel_type, 'add_to_cart' as funnel_step;


select *
from bi.mark_dev.funnel_event_gsheet;


select *
from bi.dbt_production_ga4.dedupe_event_params
WHERE event_date >= DATEADD(day, -3, CURRENT_DATE())
and event_name = 'add_to_cart'
limit 1000;


SELECT * 
FROM bi.DBT_PRODUCTION_GA4.dedupe_event_params 
WHERE event_date >= DATEADD(day, -5, CURRENT_DATE()) 
and user_pseudo_id= '2053015261.1788982832'
and event_name = 'add_to_cart'
order by event_timestamp, event_name, event_params_key;


--1087988494.1789271198

--1087988494.17892711981789271198

select *
from bi.dbt_production_ga4.dedupe_event_params
where event_params_key = 'Product Name'
order by event_date desc
limit 1000;



select count(*), event_interaction_key
from bi.mark_dev.clean_session_funnel_events
group by 2
having count(*)>1;



select funnel_add_to_cart, *
from bi.mark_dev.preprocess_session_funnel_events
order by 1 desc
limit 1000;



select funnel_add_to_cart, *
from bi.mark_dev.fct_conversion_funnel_refactored
where date > '2026-09-11'
order by 1 desc;



select count(*), count(distinct session_id), count(distinct event_interaction_key)
from bi.mark_dev.clean_session_funnel_events
where to_date(funnel_timestamp) > '2026-09-11'
and event_interaction_key like '%add_to_cart%';

--2198795	140402	2198795
--12539	10557	12539


select count(*), count(distinct session_id), count(distinct event_interaction_key)
from bi.dbt_production_ga4.clean_session_funnel_events
where to_date(funnel_timestamp) > '2026-09-11'
and event_interaction_key like '%add_to_cart%';

--2198795	140402	2198795
--12539	10557	12539




select *
from bi.mark_dev.clean_session_funnel_events
where to_date(funnel_timestamp) > '2026-09-11'
and event_interaction_key like '%add_to_cart%';

select *
from bi.dbt_production_ga4.clean_session_funnel_events
where to_date(funnel_timestamp) > '2026-09-11'
and event_interaction_key like '%add_to_cart%';




select count(*), sum(reached_formats)
from bi.mark_dev.fct_conversion_funnel_refactored
where date > '2026-09-11';

--136457	12069


select count(*), sum(reached_formats)
from bi.dbt_production_models.fct_conversion_funnel_refactored
where date > '2026-09-11';

--136457	12069



select *
from bi.dbt_production;


create or replace transient table bi.mark_dev.preprocess_session_funnel_events_backup_15092026 clone bi.dbt_production_ga4.preprocess_session_funnel_events;

alter table BI.GA4_DELETED_SESSIONS_ARCHIVE.PREPROCESS_SESSION_FUNNEL_EVENTS add column funnel_add_to_cart NUMBER(2,0);


select * from BI.GA4_DELETED_SESSIONS_ARCHIVE.PREPROCESS_SESSION_FUNNEL_EVENTS;


create or replace table BI.GA4_DELETED_SESSIONS_ARCHIVE.PREPROCESS_SESSION_FUNNEL_EVENTS_BACKUP CLONE BI.GA4_DELETED_SESSIONS_ARCHIVE.PREPROCESS_SESSION_FUNNEL_EVENTS;


alter table BI.GA4_DELETED_SESSIONS_ARCHIVE.PREPROCESS_SESSION_FUNNEL_EVENTS drop column ARCHIVED_AT;

alter table BI.GA4_DELETED_SESSIONS_ARCHIVE.PREPROCESS_SESSION_FUNNEL_EVENTS add column ARCHIVED_AT TIMESTAMP_NTZ(9);