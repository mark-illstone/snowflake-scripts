create or replace table bi.mark_dev.int_referral_structured_sessions as

WITH ga_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_ga_sessions)

SELECT DISTINCT 
    LOWER(CONCAT(COALESCE(a.source, '(none)'), '@',
                 COALESCE(a.medium::varchar(10000), '(none)'), '@',
                 COALESCE(a.campaign::varchar(10000), '(none)'), '@',
                 COALESCE(a.content::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
     , a.session_id
  FROM ga_sessions a
 WHERE lower(source) NOT LIKE '%facebook%' 
   AND lower(source) NOT LIKE '%instagram%'
   AND lower(source) NOT LIKE '%smart.bio%'
   AND lower(source) NOT LIKE '%tapjoy%'
   AND lower(source) NOT LIKE '%shareasale%'
   AND lower(source) NOT LIKE '%mention-me%'
   AND lower(source) NOT LIKE '%lostmy.us6.list-manage%'
   AND lower(source) NOT LIKE '%yahoo%'
   AND lower(source) NOT LIKE '%pinterest%'
   AND lower(source) NOT LIKE '%chatgpt%' 
   AND lower(source) NOT LIKE '%claude%' 
   AND lower(source) NOT LIKE '%gemini%' 
   AND lower(source) NOT LIKE '%perplexity%'
   AND lower(source) NOT LIKE '%copilot%'
   AND lower(source) NOT like '%.ai'
   AND lower(medium) = 'referral' 