select *
from bi.dbt_production_intermediate.int_attribution_ads
where channel = 'AI Assistant'
limit 1000;



select *
from bi.dbt_production_models.fct_marketing_attribution
where channel = 'AI Assistant'
order by date desc
limit 1000;


select *
from bi.mark_dev.int_interactions
where ad_key like 'chatgpt%'
order by day desc
limit 1000;

select *
from bi.dbt_production_intermediate.int_interactions
where ad_key like 'chatgpt%'
and day like '202607%';

select revenue, *
from bi.mark_dev.fct_marketing_attribution
where channel = 'AI Assistant'
order by date desc
limit 1000;



select revenue, *
from bi.mark_dev.fct_marketing_attribution
where lower(channel) like '%referral%'
order by ad_key asc
limit 1000;




select distinct medium
from bi.dbt_production_intermediate.int_ga_sessions
where visit_starttime::date like '2026-07%'
and source like '%chatgpt%';



select *
from bi.dbt_production_intermediate.int_attribution_ads
where channel = 'AI Assistant'
limit 1000;



select count(distinct user_pseudo_id)
from bi.dbt_production_ga4.dedupe_event_params
where event_date like '2026-07%'
and event_params_value like '%chatgpt%'
--and event_name = 'purchase'
limit 1000;


select source, medium, *
from bi.DBT_PRODUCTION_GA4.transform_session_details
where visitor_id in
(
select distinct user_pseudo_id
from bi.dbt_production_ga4.dedupe_event_params
where event_date like '2026-07%'
and event_params_value like '%chatgpt%'
and event_name = 'purchase'
)
and funnel_checkoutv3 > 0
and source like 'chatgpt%';


SELECT *
FROM bi.dbt_production_intermediate.int_attributable_orders
limit 1000;




select source, medium, *
from bi.DBT_PRODUCTION_GA4.transform_session_details
where visitor_id in
(
select distinct user_pseudo_id
from bi.dbt_production_ga4.dedupe_event_params
where event_date like '2026-07%'
and event_params_value like '%chatgpt%'
and event_name = 'purchase'
)
and funnel_checkoutv3 > 0
and source like 'chatgpt%';





select distinct split_part(ad_key, '@', 1)
from bi.dbt_production_intermediate.int_interactions
where day LIKE '202607%'
order by split_part(ad_key, '@', 1)
limit 1000;



select *
from bi.dbt_production_intermediate.int_interactions
where day LIKE '202607%'
and ad_key like 'chatgpt.com%'
and order_number is not null;



select *
from bi.dbt_production_intermediate.int_attribution_ads
where ad_key in
(
select ad_key
from bi.dbt_production_intermediate.int_interactions
where (ad_key like '%chatgpt%'
or ad_key like '%claude%'
or ad_key like '%gemini%'
or ad_key like '%perplexity%'
or ad_key like '%copilot%'
or ad_key like '%.ai')
)
and channel != 'AI Assistant';






select *
from bi.dbt_production_intermediate.int_interactions
where (ad_key like '%chatgpt%'
or ad_key like '%claude%'
or ad_key like '%gemini%'
or ad_key like '%perplexity%'
or ad_key like '%copilot%'
or ad_key like '%.ai')
and day like '202607%';