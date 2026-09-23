--int_interactions_12082026

create or replace table bi.mark_dev.int_interactions as

WITH facebook_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_structured_sessions)
   , google_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_google_structured_sessions)
   , bing_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_bing_structured_sessions)
   , tiktok_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_tiktok_structured_sessions)
   , affiliate_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_affiliate_structured_sessions)
   , pinterest_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_pinterest_structured_sessions)
   , raf_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_raf_structured_sessions)
   , inpack_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_inpack_structured_sessions)
   , email_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_email_structured_sessions)
   , organic_social_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_organic_social_structured_sessions)
   , organic_video_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_organic_video_structured_sessions)
   , payment_provider_tracking_issues_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_payment_provider_tracking_issues_structured_sessions)
   , organic_search_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_organic_search_structured_sessions)
   , referral_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_referral_structured_sessions)
   , direct_structured_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_direct_structured_sessions)
   , ga_sessions AS (SELECT * FROM bi.dbt_production_intermediate.int_ga_sessions)
   , ga_transactions AS (SELECT * FROM bi.dbt_production_intermediate.int_ga_transactions)
   , attributable_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_attributable_orders)
   , session_countries AS (SELECT * FROM bi.dbt_production_intermediate.int_session_countries)
   , reseller_interactions AS (SELECT * FROM bi.dbt_production_intermediate.int_reseller_interactions)
   , raf_interactions AS (SELECT * FROM bi.dbt_production_intermediate.int_raf_interactions)
   , session_user AS (SELECT * FROM bi.dbt_production_intermediate.int_session_user)
   , sms_structured_sessions AS (SELECT * FROM bi.mark_dev.int_sms_structured_sessions)

, all_temp_sessions as (
    SELECT *, 10 as channel_rank FROM facebook_structured_sessions 
    UNION ALL
    SELECT *, 20 as channel_rank FROM google_structured_sessions
    UNION ALL
    SELECT *, 30 as channel_rank FROM bing_structured_sessions
    UNION ALL
    SELECT *, 35 as channel_rank FROM tiktok_structured_sessions
    UNION ALL
    SELECT *, 40 as channel_rank FROM affiliate_structured_sessions
    --UNION ALL
    --SELECT *, 50 as channel_rank FROM bi.attribution.DISPLAY_STRUCTURED_SESSIONS
    UNION ALL
    SELECT *, 60 as channel_rank FROM pinterest_structured_sessions
    UNION ALL
    SELECT *, 70 as channel_rank FROM raf_structured_sessions
    UNION ALL
    SELECT *, 75 as channel_rank FROM inpack_structured_sessions ------------------- HERE
    UNION ALL
    SELECT *, 80 as channel_rank FROM email_structured_sessions
    UNION ALL
    SELECT *, 90 as channel_rank FROM organic_social_structured_sessions
    UNION ALL
    SELECT *, 100 as channel_rank FROM organic_video_structured_sessions
    UNION ALL
    SELECT *, 110 as channel_rank FROM payment_provider_tracking_issues_structured_sessions
    UNION ALL
    SELECT *, 120 as channel_rank FROM organic_search_structured_sessions
    UNION ALL
    SELECT *, 130 as channel_rank FROM referral_structured_sessions
    UNION ALL
    SELECT *, 140 as channel_rank FROM direct_structured_sessions
    UNION ALL
    SELECT *, 150 as channel_rank FROM sms_structured_sessions

)

, deduped_temp_sessions as (
    SELECT ad_key
         , session_id
      FROM all_temp_sessions
    -- Dedupe
    QUALIFY ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY channel_rank ASC) = 1
)

, temp_all_sessions as (
    SELECT DISTINCT CASE WHEN b.VISIT_STARTTIME::date < '2023-03-01' THEN 
    LOWER(CONCAT(COALESCE('other', '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)

                ELSE 'direct'
           END as AD_KEY
         , b.session_id
      FROM ga_sessions b
     WHERE NOT EXISTS (SELECT 1 FROM deduped_temp_sessions a WHERE a.session_id = b.session_id)

     UNION ALL 

     SELECT ad_key
          , session_id 
       FROM deduped_temp_sessions

)

-- need to flag completed orders from the rest in ga data set
, completed_orders as (
    SELECT DISTINCT b.session_id
         , a.order_number
         , 1 as order_completed
         , immediate_repeat
      FROM attributable_orders a 
     INNER JOIN ga_transactions b 
        on a.order_number = b.order_number

)

, base AS (
    SELECT DISTINCT a.ad_key
         , a.session_id
         , b.visitor_id
         , d.gclick_id
         , d.fbclick_id
         , to_char(d.visit_starttime,'YYYYMMDD')::int as day --d.visit_starttime as timestamp,
         , d.visit_starttime as interaction_timestamp
         , e.country_fk
         , g.order_number
         , g.timestamp as order_timestamp
         , 'website session' as interaction_type
         , d.user_agent
--1 as number_of_sessions
      FROM temp_all_sessions a
      LEFT JOIN session_user b 
        on a.session_id = b.session_id
--LEFT JOIN bi.staging_bq.session_properties c on a.session_id = c.session_id
      LEFT JOIN ga_sessions d 
        on a.session_id = d.session_id
      LEFT JOIN session_countries e 
        on a.session_id = e.session_id
      LEFT JOIN ga_transactions f 
        on a.session_id = f.session_id 
       AND NOT f.immediate_repeat
      LEFT JOIN attributable_orders g 
        on f.order_number = g.order_number
--LEFT JOIN bi.staging_bq.page_events h on a.session_id = h.session_id

     UNION ALL

    SELECT DISTINCT *--, 0 as number_of_sessions
      FROM reseller_interactions r 

)

, temp_all_interactions as (
    SELECT * FROM base z

     WHERE NOT EXISTS (SELECT 1 FROM raf_interactions s WHERE s.order_number = z.order_number)

     UNION ALL

    SELECT DISTINCT ad_key
         , interaction_id
         , visitor_id::VARCHAR AS visitor_id
         , NULL as gclick_id
         , NULL as fbclick_id
         , to_char(interaction_timestamp,'YYYYMMDD')::int as day
         , interaction_timestamp
         , country_fk
         , order_number
         , order_timestamp
         , 'raf order' as interaction_type
         , NULL as user_agent
    --0 as number_of_sessions
      FROM raf_interactions s
)

SELECT DISTINCT 
    LOWER(CONCAT(COALESCE('unknown', '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
     , UUID_STRING() as interaction_id -- gets randomly generated every time it runs, but it doesn't have to be the same, just unique
     , CASE WHEN b.user_id::VARCHAR IS NULL AND b.email::VARCHAR IS NOT NULL THEN b.email::VARCHAR 
            WHEN b.user_id::VARCHAR IS NULL AND b.email::VARCHAR IS NULL THEN CONCAT(NVL(b.reseller_name, '(not-set)'),b.order_number)::VARCHAR
            ELSE b.user_id::VARCHAR
       END as visitor_id
     , NULL as gclick_id
     , NULL as fbclick_id
    --  , to_char(b.timestamp,'YYYYMMDD')::int as day --b.timestamp,
    --  , b.timestamp as interaction_timestamp
    --  , b.country_fk
    --  , b.order_number
    --  , b.timestamp as order_timestamp

         , to_char(b.completed_at,'YYYYMMDD')::int as day --b.timestamp,
     , b.completed_at as interaction_timestamp
     , b.country_fk
     , b.order_number
     , b.completed_at as order_timestamp

     , 'unknown' as interaction_type
     , NULL as user_agent
--0 as number_of_sessions
  FROM attributable_orders b
 WHERE NOT EXISTS (SELECT 1 
                     FROM temp_all_interactions a 
                    WHERE a.order_number = b.order_number)
-- added by Clara
--    AND NOT EXISTS (SELECT 1 
--                      FROM GA_TRANSACTIONS a 
--                     WHERE a.order_number = b.order_number
--    AND a.immediate_repeat)

 UNION ALL
SELECT DISTINCT * 
  FROM temp_all_interactions