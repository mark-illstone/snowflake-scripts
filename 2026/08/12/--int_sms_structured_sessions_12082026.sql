--int_sms_structured_sessions_12082026

create or replace table bi.mark_dev.int_sms_structured_sessions as

WITH ga_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_ga_sessions)

SELECT DISTINCT 
    LOWER(CONCAT(COALESCE(source, '(none)'), '@',
                 COALESCE(medium::varchar(10000), '(none)'), '@',
                 COALESCE(campaign::varchar(10000), '(none)'), '@',
                 COALESCE(content::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
     , session_id
  FROM ga_sessions
WHERE 
    lower(medium) = 'sms';