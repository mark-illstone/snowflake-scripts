CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_campaigns AS

WITH ad_insights AS (SELECT * FROM bi.fivetran_facebook_plucky.ad_insights)

 SELECT campaign_id
      , campaign_name
      , account_id
   FROM ad_insights
QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY _fivetran_synced DESC) = 1