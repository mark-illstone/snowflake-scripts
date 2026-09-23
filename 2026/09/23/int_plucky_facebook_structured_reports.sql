CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_structured_reports AS

WITH ad_insights AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_ad_insights)
   , facebook_structured_ads AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_structured_ads)

SELECT DISTINCT a.ad_key
     , to_char(b.day,'YYYYMMDD')::int as day
     , SUM(b.spend) as cost
     , SUM(b.impressions) as impressions
     , SUM(b.clicks) as clicks
     , NULL as commissions
  FROM ad_insights b
 INNER JOIN facebook_structured_ads a 
   ON a.ad_id = b.ad_id and a.country = b.country
 GROUP BY a.ad_key, b.day