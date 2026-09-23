CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_ads_base AS

WITH ads AS (SELECT * FROM bi.fivetran_facebook_plucky.ad_history)
   , creatives AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_creatives_base)

, ads_deduplicated AS (
     SELECT a.id::integer AS ad_id
          , a.name::varchar AS ad_name
          , a.ad_set_id::integer AS adset_id
          , b.creative_id::integer AS creative_id
       FROM ads a 
      INNER JOIN creatives b 
         ON a.id = b.ad_id
    QUALIFY ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a._fivetran_synced DESC) = 1
)

SELECT ad_id
     , ad_name
     , adset_id
     , creative_id
  FROM ads_deduplicated