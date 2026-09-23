CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_ad_insights AS

WITH ad_insights AS (SELECT * FROM bi.fivetran_facebook_plucky.ad_insights)

 SELECT date AS day
      , ad_id
      , country
      , campaign_name
      , spend
      , impressions
      , clicks
      , 0 AS inline_link_clicks
      , 0 AS total_conversions
      , 0 AS total_revenue
      , CAST('2026-09-23 06:55:09.943401+00:00' AS TIMESTAMP) AS etl_ts
   FROM ad_insights
QUALIFY ROW_NUMBER() OVER (PARTITION BY date, country, account_id, campaign_id, adset_id, ad_id ORDER BY _fivetran_synced DESC) = 1