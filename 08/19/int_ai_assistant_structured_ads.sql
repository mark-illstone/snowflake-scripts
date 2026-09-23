create or replace table bi.mark_dev.int_ai_assistant_structured_ads as

WITH ga_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_ga_sessions)

SELECT DISTINCT 
    LOWER(CONCAT(COALESCE(source, '(none)'), '@',
                 COALESCE(medium::varchar(10000), '(none)'), '@',
                 COALESCE(campaign::varchar(10000), '(none)'), '@',
                 COALESCE(content::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
     , source as  partner
     , NULL as account_id
     , NULL as account_name
     , NULL as campaign_id
     , NULL as campaign_name
     , NULL as ad_group_id
     , NULL as ad_group_name
     , NULL as  ad_id
     , NULL as ad_name
     , NULL as keyword_id
     , NULL as keyword_name
--   FROM (
--     --Deduping by selecting most recent campaign_name since these were updated multiple times
--         SELECT DISTINCT campaign, content, source, medium,
--                    ROW_NUMBER() OVER (
--       PARTITION BY ad_group_id, criteria_id
--       ORDER BY VISIT_STARTTIME DESC
--     ) AS reverse_rank
--     FROM bi.attribution.ga_sessions
-- ) a
 FROM ga_sessions
WHERE 
    (
       lower(source) LIKE '%chatgpt%' 
    OR lower(source) LIKE '%claude%' 
    OR lower(source) LIKE '%gemini%' 
    OR lower(source) LIKE '%perplexity%'
    OR lower(source) LIKE '%copilot%'
    OR lower(source) like '%.ai'
    )