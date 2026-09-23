CREATE OR REPLACE TABLE bi.mark_dev.clean_session_funnel_events AS

WITH dedupe_event_params_filtered AS (SELECT * FROM bi.DBT_PRODUCTION_GA4.dedupe_event_params WHERE event_date >= DATEADD(day, -3, CURRENT_DATE()))

-- select the relevant page_view data
,page_view_events AS (
    SELECT  event_index.session_id,
            event_index.event_timestamp,
            event_index.event_key,
            event_index.event_name,
            -- page_path.event_params_value AS page_path,
            -- query_params.event_params_value AS query_params,
            page_path.event_params_value || '?' || COALESCE(query_params.event_params_value, '-') AS page_location_id
    FROM bi.DBT_PRODUCTION_GA4.clean_events_index event_index
    LEFT JOIN dedupe_event_params_filtered page_path
            ON event_index.event_key = page_path.event_key
            AND page_path.event_params_key = 'page_path'
    LEFT JOIN dedupe_event_params_filtered query_params
              ON event_index.event_key = query_params.event_key
              AND query_params.event_params_key = 'query_params'
    

    -- this filter will only be applied on an incremental run
    WHERE TO_DATE(TO_TIMESTAMP(event_index.event_timestamp)) >= DATEADD(day, -3, CURRENT_DATE())
    
),


-- select the relevant data from the track event
track_event_params AS (
    SELECT event_params.event_key,
           event_params.event_timestamp,
           event_params_key,
           ind.session_id,
           event_params_value
    FROM dedupe_event_params_filtered event_params
    LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_events_index ind
        ON event_params.event_key = ind.event_key
    WHERE event_params.event_name in ('search', 'track', 'authentication', 'consent_banner_selection', 'optimizely_decision_web')
    AND user_pseudo_id IS NOT NULL

    
),

-- pivot the track event table
track_event_pivoted AS (
    SELECT *
    FROM track_event_params PIVOT (MAX (event_params_value) FOR event_params_key IN (
    'eventCategory', 'eventAction', 'eventLabel', 'page_path', 'query_params'))
    AS p (event_key, event_timestamp, session_id,
    event_category, event_action, event_label, page_path, query_params)
    WHERE session_id IS NOT NULL
),

-- add keys for the join with the page_registry and event_registry tables
track_event_with_joining_key AS (
SELECT  *,
        COALESCE(page_path, '-') || '?' || COALESCE(query_params, '-') AS page_location_id,
        event_category || '?' || COALESCE(event_action, '-')  || '#' || COALESCE(event_label, '-') AS track_event_id
FROM track_event_pivoted
)

,pre_dedupe AS
(
-- final table containing the cleaned funnel step and type for each relevant interaction during each session
SELECT  'page view'::varchar AS interaction_type,
        session_id,
        event_timestamp AS funnel_timestamp,
        event_key || '#' || 'page view'  AS event_interaction_key,
        registry.page_type AS funnel_type,
        registry.page_step AS funnel_step,
        NULL AS funnel_step_detailed,
        NULL AS funnel_step_detailed2,
        registry.product_name AS product,
        registry.page_path AS product_page_path,
        registry.engagement,

-- TODO discuss introducing this step later during preprocess by combining both page_view and track_events here
        -- ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY event_timestamp ASC) page_number,
        -- 0 AS temp_stitched_pages.event_number,
        NULL AS context_page_funnel_type,
        NULL AS context_page_funnel_step,
        NULL AS context_page_product_name,
        NULL AS context_page_engagement,
        '2' as dedupe_priority
FROM page_view_events
LEFT JOIN bi.DBT_PRODUCTION_GA4.page_registry registry
    USING(page_location_id)

UNION ALL

SELECT event_registry.interaction_type,
       events.session_id,
       events.event_timestamp                       AS funnel_timestamp,
       events.event_key || '#' || COALESCE(event_registry.interaction_type, '-') AS event_interaction_key,


       -- temp_stitched_conversion_funnel_events.page_number,
       -- temp_stitched_conversion_funnel_events.event_number,
       event_registry.funnel_type,
       CASE
           WHEN event_registry.funnel_type = 'product' AND COALESCE(event_registry.funnel_type, '') = ''
               THEN page_registry.page_step
           ELSE event_registry.funnel_step
       END                                          AS funnel_step,
       event_registry.event_type                    AS funnel_step_detailed,
       event_registry.event_name                    AS funnel_step_detailed2,
       CASE
           WHEN COALESCE(event_registry.product_name, '') != '' THEN event_registry.product_name
           ELSE COALESCE(page_registry.product_name, '')
       END                                          AS product,
       page_registry.page_path                      AS product_page_path,
       COALESCE(event_registry.engagement::int, 0)  AS engagement,
       page_registry.page_type                      AS context_page_funnel_type,
       page_registry.page_step                      AS context_page_funnel_step,
       page_registry.product_name                   AS context_page_product_name,
       page_registry.engagement                     AS context_page_engagement,
       '3' as dedupe_priority
    FROM track_event_with_joining_key events
    LEFT JOIN bi.DBT_PRODUCTION_GA4.page_registry page_registry
              USING(page_location_id)
    LEFT JOIN bi.DBT_PRODUCTION_GA4.event_registry event_registry
        USING(track_event_id)

UNION ALL

SELECT  page_view_events.event_name AS interaction_type,
        session_id,
        page_view_events.event_timestamp AS funnel_timestamp,
        page_view_events.event_key || '#' || 'page view'  AS event_interaction_key,
        event_funnel.funnel_type AS funnel_type,
        event_funnel.funnel_step AS funnel_step,
        NULL AS funnel_step_detailed,
        NULL AS funnel_step_detailed2,
        NULL AS product,
        page_path.event_params_value AS product_page_path,
        NULL AS engagement,
        NULL AS context_page_funnel_type,
        NULL AS context_page_funnel_step,
        NULL AS context_page_product_name,
        NULL AS context_page_engagement,
        '1' as dedupe_priority
FROM page_view_events
INNER JOIN bi.mark_dev.event_funnel_registry event_funnel
    USING(event_name)
LEFT JOIN dedupe_event_params_filtered page_path
    ON page_view_events.event_key = page_path.event_key
        AND page_path.event_params_key = 'page_path'
)

SELECT * EXCLUDE dedupe_priority
FROM pre_dedupe
QUALIFY row_number() OVER(PARTITION BY event_interaction_key ORDER BY dedupe_priority) = 1