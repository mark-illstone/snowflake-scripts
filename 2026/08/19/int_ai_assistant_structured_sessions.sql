create or replace table bi.mark_dev.int_ai_assistant_structured_sessions as

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
 WHERE 
    (
       lower(source) LIKE '%chatgpt%' 
    OR lower(source) LIKE '%claude%' 
    OR lower(source) LIKE '%gemini%' 
    OR lower(source) LIKE '%perplexity%'
    OR lower(source) LIKE '%copilot%'
    OR lower(source) like '%.ai'
    )