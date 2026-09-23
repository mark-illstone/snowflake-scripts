--fct_granular_google_keywords_06082026

-- Grain: keyword_id × match_type × ad_group_id × date
-- Source: granular_keywords_daily (Fivetran custom report)
-- Search only — never union with campaign or shopping tables
-- Campaign dimensions left-joined from stg_campaign_daily

create or replace table bi.mark_dev.fct_granular_google_keywords as

WITH source AS (SELECT * FROM bi.fivetran_granular_google_ads_2.granular_keywords_daily)

-- Pull campaign-level derived dims from the campaign staging model
-- so we don't duplicate parsing logic
, campaigns AS (
    SELECT DISTINCT
        campaign_id,
        campaign_name,
        market,
        language,
        channel,
        category,
        type,
        theme,
        country,
        countries_top_8
    FROM bi.mark_dev.fct_granular_google_campaigns
)

, renamed AS (
    SELECT
        s.date::DATE                        AS day,
        s.campaign_id,                  
        s.ad_group_id,
        s.ad_group_name,
        s.keyword_text,
        s.keyword_match_type,

        -- Campaign dimensions from lookup
        c.campaign_name,
        c.market,
        c.language,
        c.channel,
        c.category,
        c.type,
        c.theme,
        c.country,
        c.countries_top_8,

        -- Metrics
        SUM(s.impressions)                  AS impressions,
        SUM(s.clicks)                       AS clicks,
        SUM(s.cost_micros / 1000000.0)      AS cost,
        SUM(s.interactions)                 AS interactions,
        SUM(s.conversions)                  AS conversions,
        SUM(s.conversions_value)            AS conversions_value,

        MAX(CAST('2026-08-06 07:45:22.763066+00:00' AS TIMESTAMP)) AS etl_ts

    FROM source s
    LEFT JOIN campaigns c ON c.campaign_id = s.campaign_id
    GROUP BY
        s.date::DATE,
        s.campaign_id,
        s.ad_group_id,
        s.ad_group_name,
        s.keyword_text,
        s.keyword_match_type,
        c.campaign_name,
        c.market,
        c.language,
        c.channel,
        c.category,
        c.type,
        c.theme,
        c.country,
        c.countries_top_8
)

SELECT * FROM renamed