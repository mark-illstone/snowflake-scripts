--int_cost_per_interaction_18082026

create or replace table bi.mark_dev.int_cost_per_interaction as

WITH google_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_google_structured_reports)
   , pinterest_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_pinterest_structured_reports)
   , affiliate_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_affiliate_structured_reports)
   , bing_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_bing_structured_reports)
   , facebook_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_structured_reports)
   , tiktok_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_tiktok_structured_reports)
   , reseller_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_reseller_structured_reports)
   , manual_spend_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_manual_spend_structured_reports)
   , manual_affiliates_structured_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_manual_affiliates_structured_reports)
   , ads AS (SELECT * FROM bi.dbt_production_intermediate.int_attribution_ads)
   , attributed_interactions AS (SELECT * FROM bi.dbt_production_intermediate.int_attributed_interactions)
   , countries AS (SELECT * FROM bi.dbt_production_models.dim_countries)
   , interactions AS (SELECT * FROM bi.dbt_production_intermediate.int_interactions)

--1. Union all structured Reports
, cost_interaction_shaking as (
    SELECT * FROM google_structured_reports
     UNION ALL
    SELECT * FROM pinterest_structured_reports
     UNION ALL
    SELECT * FROM affiliate_structured_reports
     UNION ALL
    SELECT * FROM bing_structured_reports
    --UNION ALL
    --SELECT * FROM bi.attribution.DISPLAY_STRUCTURED_REPORTS
     UNION ALL
    SELECT * FROM facebook_structured_reports
     UNION ALL
    SELECT * FROM tiktok_structured_reports
     UNION ALL
    SELECT * FROM reseller_structured_reports --waiting for Amazon API to be set up
)

--2. count all interactions on ad and day level
, interaction_counts as (
    SELECT ad_key
         , interaction_day as day
         , COUNT(*) as count
      FROM attributed_interactions
     GROUP BY 1,2
)

--3. distribute costs across the interactions for each day and ad_fk
, cost_distribution as (
    SELECT a.interaction_id
         , a.ad_key
         , a.interaction_day as day
         , a.country_fk
         , a.state
         , a.customer_type
         
         , SUM(c.cost * 1.0 / b.count) AS cost
         , SUM(c.impressions * 1.0 / b.count) AS impressions
         , SUM(c.clicks * 1.0 / b.count) AS clicks
         , SUM(c.commissions * 1.0 / b.count) AS commissions
      FROM attributed_interactions a
     INNER JOIN interaction_counts b 
        ON a.ad_key = b.ad_key
       AND a.interaction_day = b.day
     INNER JOIN cost_interaction_shaking c 
        ON a.ad_key = c.ad_key
       AND a.interaction_day = c.day
     group by 1,2,3,4,5,6
)

-- 4. group the result from 3. on ad_fk, day_fk and country_fk level
, aggregated_cost_distribution AS (
    SELECT ad_key
         , day
         , country_fk
         , state
         , customer_type
         , SUM(cost) as cost
         , SUM(impressions) as impressions
         , SUM(clicks) as clicks
         , SUM(commissions) as commissions
      FROM cost_distribution
     group by 1,2,3,4,5
)

--5. select costs with no interaction on day level
, no_interaction_costs AS (
    SELECT a.*
         , b.count 
      FROM cost_interaction_shaking as a
      LEFT JOIN interaction_counts b 
        ON a.ad_key = b.ad_key
       AND a.day = b.day
     WHERE b.count is null
)

--6. country split of all costs over all days
, total_count AS (
    SELECT ad_key
         , count(*) total_count
      FROM attributed_interactions
     GROUP BY 1
)

, country_customer_count AS (
    SELECT ad_key
         , country_fk
         , state
         , customer_type
         , count(*) as country_customer_count
      FROM attributed_interactions
     group by 1,2,3,4
)

, country_customer_shares AS (
    SELECT a.ad_key
         , country_fk
         , state
         , customer_type
         , (country_customer_count / total_count) as country_customer_share
      FROM country_customer_count a
      LEFT JOIN total_count b 
        ON a.ad_key = b.ad_key
)

, distributed_cost as (
    SELECT a.ad_key
         , a.day
         , b.country_fk
         , b.state
         , customer_type
         , (a.cost * b.country_customer_share) as cost
         , (a.impressions * b.country_customer_share) as impressions
         , (a.clicks * b.country_customer_share) as clicks
         , (a.commissions * b.country_customer_share) as commissions
      FROM no_interaction_costs a
     INNER JOIN country_customer_shares b 
        on a.ad_key = b.ad_key
)

--7.discover interactions without country (if any left after above)
, no_country_interactions as (
    SELECT a.ad_key
         , a.day
        -- Substitute default UNKNOWN (key = -1) with the FB account country if possible
         , COALESCE(fb_countries.key, -1) as country_fk
         , null as state
         , 'new' as customer_type
         , a.cost
         , a.impressions
         , a.clicks
         , a.commissions
      FROM cost_interaction_shaking a 
      LEFT JOIN ads fb_ads 
        on fb_ads.ad_key = a.ad_key 
       AND fb_ads.partner in ('facebook', 'tiktok')
        -- List of account -> country substitutions for FB ads that are missing country
        -- as determined in the standard way by interaction share
      LEFT JOIN countries fb_countries 
        ON fb_countries.name =
            CASE WHEN fb_ads.campaign_name like '%_US_%' THEN 'United States'
			     WHEN fb_ads.campaign_name like '%_UK_%' THEN 'United Kingdom'
			     WHEN fb_ads.campaign_name like '%_AU_%' THEN 'Australia'
			     WHEN fb_ads.campaign_name like '%_CA_%' THEN 'Canada'
			     WHEN fb_ads.campaign_name like '%_ES_%' THEN 'Spain'
			     WHEN fb_ads.campaign_name like '%_IT_%' THEN 'Italy'
			     WHEN fb_ads.campaign_name like '%_DE_%' THEN 'Germany'
			     WHEN fb_ads.campaign_name like '%_ES_%' THEN 'Spain'
			     WHEN fb_ads.campaign_name like '%_JP_%' THEN 'Japan'
			     WHEN fb_ads.campaign_name like '%_FR_%' THEN 'France'
            END
     WHERE NOT EXISTS (SELECT 1 FROM interactions b WHERE a.ad_key = b.ad_key)
)

--8.Union all to the final table

,final_data_pre_dst AS

(
SELECT * FROM aggregated_cost_distribution

 UNION ALL

SELECT * FROM distributed_cost

 UNION ALL

SELECT * FROM no_country_interactions

 UNION ALL

SELECT ad_key
     , day
     , country_fk
     , null as state
     , 'new' AS customer_type
     , cost
     , impressions
     , clicks
     , commissions
  FROM manual_spend_structured_reports

  UNION ALL

  SELECT ad_key
     , day
     , country_fk
     , null as state
     , 'new' AS customer_type
     , cost
     , impressions
     , clicks
     , commissions
  FROM manual_affiliates_structured_reports

  )

--9.Digital Sales Tax 
  SELECT
       ad_key
     , day
     , country_fk
     , state
     , customer_type
     , CASE 
            WHEN (LOWER(ad_key) LIKE '%google%' OR (LOWER(ad_key) LIKE 'facebook%' AND to_date(to_varchar(day), 'yyyymmdd') >= '2026-07-01')) AND c.name = 'United Kingdom'  THEN cost * (1 + 2 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR (LOWER(ad_key) LIKE 'facebook%' AND to_date(to_varchar(day), 'yyyymmdd') >= '2026-07-01')) AND c.name = 'Austria'         THEN cost * (1 + 5 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR (LOWER(ad_key) LIKE 'facebook%' AND to_date(to_varchar(day), 'yyyymmdd') >= '2026-07-01')) AND c.name = 'Turkey'          THEN cost * (1 + 7 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR (LOWER(ad_key) LIKE 'facebook%' AND to_date(to_varchar(day), 'yyyymmdd') >= '2026-07-01')) AND c.name = 'Spain'           THEN cost * (1 + 3 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR (LOWER(ad_key) LIKE 'facebook%' AND to_date(to_varchar(day), 'yyyymmdd') >= '2026-07-01')) AND c.name = 'Italy'           THEN cost * (1 + 2.5 / 100)
            WHEN (LOWER(ad_key) LIKE '%google%' OR (LOWER(ad_key) LIKE 'facebook%' AND to_date(to_varchar(day), 'yyyymmdd') >= '2026-07-01')) AND c.name = 'France'          THEN cost * (1 + 2 / 100)
            ELSE cost
      END AS cost
     , impressions
     , clicks
     , commissions
     
  FROM 
    final_data_pre_dst a
        LEFT JOIN countries c
            ON a.country_fk = c.key