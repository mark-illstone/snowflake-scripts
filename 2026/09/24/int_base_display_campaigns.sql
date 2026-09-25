CREATE OR REPLACE TABLE bi.mark_dev.int_base_display_campaigns AS

WITH display_campaigns_daily_update AS (SELECT * FROM bi.fivetran_google_ads.campaigns_daily)

SELECT date::date AS day
     , id AS campaign_id
     , name AS campaign_name
     , advertising_channel_sub_type
     , advertising_channel_type
     , SUM(impressions) AS impressions
     , SUM(clicks) AS clicks
     , SUM(cost_micros/1000000) AS cost
     , SUM(interactions) AS interactions
     , MAX(CAST('2026-09-24 07:45:21.633519+00:00' AS TIMESTAMP)) AS etl_ts
FROM display_campaigns_daily_update
WHERE lower(name) LIKE '%-dc-%'
AND customer_id NOT IN ('3544478401', '5313500033') --filter out Plucky Books and MLIAB accounts
GROUP BY ALL