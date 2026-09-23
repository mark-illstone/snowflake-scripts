CREATE OR REPLACE TABLE bi.mark_dev.event_funnel_registry AS

WITH event_funnels AS (SELECT * FROM bi.google_sheets.ga_event_funnel)

SELECT
     idx::int AS idx
    ,event_name::varchar AS event_name
    ,funnel_type::varchar AS funnel_type
    ,funnel_step::varchar AS funnel_step
FROM
    event_funnels;




    WITH event_funnels AS (SELECT * FROM bi.google_sheets.ga_event_funnel)

SELECT
     idx::int AS idx
    ,event_name::varchar AS event_name
    ,funnel_type::varchar AS funnel_type
    ,funnel_step::varchar AS funnel_step
FROM
    event_funnels