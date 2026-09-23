CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_adsets AS

WITH ad_insights AS (SELECT * FROM bi.fivetran_facebook_plucky.ad_insights)

 SELECT adset_id
      , adset_name
      , country
      , campaign_id
   FROM ad_insights
   where country <> 'unknown'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY adset_id, country ORDER BY _fivetran_synced DESC) = 1