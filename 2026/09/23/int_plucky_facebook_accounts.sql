CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_accounts AS

WITH ad_insights AS (SELECT * FROM bi.fivetran_facebook_plucky.ad_insights)

 SELECT account_id
      , account_name
   FROM ad_insights
QUALIFY ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY _fivetran_synced DESC) = 1