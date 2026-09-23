CREATE OR REPLACE TABLE bi.mark_dev.fct_plucky_marketing_performance AS

with ads as (select * from bi.mark_dev.int_plucky_ads)
   , google_structured_reports AS (SELECT * FROM bi.mark_dev.int_plucky_google_structured_reports)
   , facebook_structured_reports AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_structured_reports)
   , fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)
   , country AS (SELECT * FROM bi.google_sheets.ga_4_countries)

, performance as (
    
    select
        ad_key
        , day
        , cost
        , impressions
        , clicks
        , commissions
        , 'Retail' as trade_group
    from google_structured_reports
 
    union all  
    
    select
        ad_key
        , day
        , cost
        , impressions
        , clicks
        , commissions
        , 'Retail' as trade_group
    from facebook_structured_reports
)

,pre_dst as
(
select
    performance.ad_key
    , TO_VARCHAR(TO_DATE(performance.day::varchar,'YYYYMMDD'),'YYYY-MM-DD')::date as day

    -- ad dimensions
    , ads.channel
    , ads.channel_groups
    , ads.channel_paid_or_unpaid
    , ads.partner
    --, ads.country
    , coalesce(country.country_name, ads.country) as country
    , ads.account_id
    , ads.account_name
    , ads.campaign_id
    , ads.campaign_name
    , ads.ad_group_id
    , ads.ad_id
    , ads.ad_name
    , ads.keyword_id
    , ads.keyword_name

    -- metrics
    -- facebook sends spend already converted to GBP
    , CASE WHEN ads.country = 'UK' OR ads.partner = 'facebook' THEN COALESCE(performance.cost, 0)
           WHEN ads.country = 'USA' AND ads.partner <> 'facebook' THEN COALESCE(performance.cost, 0)/usd.rate
           ELSE COALESCE(performance.cost, 0)
           END as cost
    , performance.impressions
    , performance.clicks
    , performance.commissions
    , performance.trade_group


from performance
left join ads
    on ads.ad_key = performance.ad_key
left join fx usd 
    on to_char(usd.date::date,'YYYYMMDD')::int = performance.day 
        and usd.currency = 'USD'
left join country
 on case
        when ads.country = 'USA' then 'US'
        when ads.country = 'UK'  then 'GB'
        when ads.country = 'IRL' then 'IE'
        else ads.country
    end = country.country_code
)

select 
    * exclude(cost)
    , CASE 
            WHEN (LOWER(ad_key) LIKE '%google%' OR LOWER(ad_key) LIKE 'facebook%') AND day >= '2026-07-01' AND country = 'United Kingdom'  THEN cost * (1 + 2 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR LOWER(ad_key) LIKE 'facebook%') AND day >= '2026-07-01' AND country = 'Austria'         THEN cost * (1 + 5 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR LOWER(ad_key) LIKE 'facebook%') AND day >= '2026-07-01' AND country = 'Turkey'          THEN cost * (1 + 7 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR LOWER(ad_key) LIKE 'facebook%') AND day >= '2026-07-01' AND country = 'Spain'           THEN cost * (1 + 3 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR LOWER(ad_key) LIKE 'facebook%') AND day >= '2026-07-01' AND country = 'Italy'           THEN cost * (1 + 2.5 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR LOWER(ad_key) LIKE 'facebook%') AND day >= '2026-07-01' AND country = 'France'          THEN cost * (1 + 2 / 100)
            ELSE cost
      END AS cost
from pre_dst