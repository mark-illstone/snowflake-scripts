SELECT count(*), acronym
FROM bi.google_sheets.marketing_product_categories
GROUP BY acronym
HAVING count(*) > 1;

SELECT acronym, id
FROM bi.google_sheets.marketing_product_categories
WHERE acronym in
(
'SGNP-M',
'CFY',
'SGNP-D',
'YLNH',
'SGNP-BP',
'ILY',
'NHTM'
)
order by acronym, id;

SELECT count(*), acronym
FROM bi.google_sheets.marketing_acronym_adjustment
GROUP BY acronym
HAVING count(*) > 1;

select *
from bi.google_sheets.marketing_acronym_adjustment;


select ad_id, sum(amount_spent) as total_spent
from bi.mark_dev.fct_facebook_granular_data
group by ad_id;

--825,224

select sum(amount_spent) as total_spent
from bi.mark_dev.fct_facebook_granular_data;
--29237572.89

select sum(amount_spent) as total_spent
from bi.dbt_production_models.fct_facebook_granular_data;
--29266926.87

select count(*), ad_id, day
from bi.dbt_production_models.fct_facebook_granular_data
group by ad_id, day
having count(*) > 1;

--785,488

with cte1 as(
select sum(amount_spent) as total_spent, day
from bi.mark_dev.fct_facebook_granular_data
group by day
),
cte2 as(
select sum(amount_spent) as total_spent, day
from bi.dbt_production_models.fct_facebook_granular_data
group by day
)
select *
from cte1
inner join cte2
on cte1.day = cte2.day
and round(cte1.total_spent, 0) != round(cte2.total_spent, 0)
order by cte1.day desc;



select count(*), ad_id
from bi.mark_dev.fct_facebook_granular_data
where day = '2025-04-22'
group by ad_id
having count(*) > 1;

select count(*), ad_id
from bi.dbt_production_models.fct_facebook_granular_data
where day = '2025-04-22'
group by ad_id
having count(*) > 1;

select *
from bi.dbt_production_models.fct_facebook_granular_data
where day = '2025-04-22'
and ad_id = '6649098656922';

select *
from bi.mark_dev.fct_facebook_granular_data
where day = '2025-04-22'
and ad_id = '6649098656922';



select sum(amount_spent) as total_spent
from bi.mark_dev.fct_facebook_granular_data;
--29,237,572.89

select sum(amount_spent) as total_spent
from bi.dbt_production_models.fct_facebook_granular_data;
--29,266,926.87

--£29,354

select count(DISTINCT ad_id, day)
from bi.mark_dev.fct_facebook_granular_data
where keepsake_kids IS NOT NULL;
--700,205 / 781,194  = 89.63%

select count(DISTINCT ad_id, day)
from bi.dbt_production_models.fct_facebook_granular_data
where keepsake_kids IS NOT NULL;
--562176 / 781,194 = 71.96%

--increase of 17.67% in the number of rows with keepsake_kids populated



select distinct upper(acronym) as acronym
from bi.mark_dev.fct_facebook_granular_data
where keepsake_kids IS NULL
order by acronym;

select distinct upper(acronym) as acronym
from bi.mark_dev.fct_granular_google_pmax
where keepsake_kids IS NULL
order by acronym;

select distinct upper(acronym) as acronym
from bi.mark_dev.fct_granular_google_shopping
where keepsake_kids IS NULL
order by acronym;





SELECT campaign_id, product_custom_attribute_2
FROM BI.FIVETRAN_GRANULAR_GOOGLE_ADS_2.GRANULAR_SHOPPING_DAILY
QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id, product_custom_attribute_2 ORDER BY date DESC) = 1;


select id, date
from bi.fivetran_granular_google_ads_2.granular_campaign_daily
order by date desc;

select *
from bi.fivetran_granular_google_ads_2.granular_shopping_daily
where campaign_id = '24040503065';

select *
from bi.fivetran_granular_google_ads_3.granular_pmax_daily
where campaign_id = '24040503065';


select distinct subcategory
from bi.mark_dev.fct_facebook_granular_data;



select count(*), day, campaign_id
from bi.dbt_production_models.fct_granular_google_campaigns
--where campaign_id = '1352590234'
group by day, campaign_id
having count(*) > 1;


select count(*), day, campaign_id
from bi.mark_dev.fct_granular_google_campaigns
--where campaign_id = '1352590234'
group by day, campaign_id
having count(*) > 1;


select *
from bi.mark_dev.fct_granular_google_campaigns
where day = '2024-08-21'
and campaign_id = '751562157';