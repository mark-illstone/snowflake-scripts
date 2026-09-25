select distinct campaign_name
from bi.dbt_production_models.fct_marketing_attribution
where date >= '2026-09-20'
order by 1
limit 1000;



select *
from bi.fivetran_google_ads.campaigns_daily
where customer_id = '3544478401'
limit 1000;

select *
from bi.fivetran_google_ads.account_history
where id in (3544478401, 5313500033)
limit 1000;


select distinct id
from bi.fivetran_google_ads.account_history
where lower(descriptive_name) not in ('mliab', 'plucky books')
and _fivetran_active = true;



select count(*), sum(impressions), sum(clicks), sum(cost), sum(interactions)
from bi.mark_dev.int_base_criteria_reports;

--1688337	4497101213	60286475	48810885.433115	77269301

select count(*), sum(impressions), sum(clicks), sum(cost), sum(interactions)
from bi.dbt_production_intermediate.int_base_criteria_reports;

--1688558	4497423034	60292397	48819572.978210	77279118




select count(*), sum(impressions), sum(clicks), sum(cost), sum(interactions)
from bi.mark_dev.int_base_display_campaigns;

--14134	219881383	7665426	818959.878025	8120431

select count(*), sum(impressions), sum(clicks), sum(cost), sum(interactions)
from bi.dbt_production_intermediate.int_base_display_campaigns;

--14134	219881383	7665426	818959.878025	8120431




select count(*), sum(impressions), sum(clicks), sum(cost), sum(interactions)
from bi.mark_dev.int_base_performance_max_spend;

--100407	1602142359	15701030	14443953.191544	28447187

select count(*), sum(impressions), sum(clicks), sum(cost), sum(interactions)
from bi.dbt_production_intermediate.int_base_performance_max_spend;

--100455	1602224857	15702172	14444958.177231	28452224



select *
from bi.mark_dev.int_base_criteria_reports
where campaign_name in
(
'Plucky_AdvantagePlus',
'UK_EN_PMAX_Romantic_Husband',
'UK_EN_Search_NB_Evergreen',
'UK_EN_Shopping_Evergreen',
'USA_EN_PMAX_Romantic_Husband',
'USA_EN_Search_NB_Evergreen'
);


select sum(cost)
from bi.mark_dev.int_plucky_google_campaigns_daily;


select sum(cost)
from bi.plucky_shopify.int_google_campaigns_daily;