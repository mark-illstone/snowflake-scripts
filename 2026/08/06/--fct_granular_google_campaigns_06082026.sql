--fct_granular_google_campaigns_06082026

create or replace table bi.mark_dev.fct_granular_google_campaigns as

WITH source AS (SELECT * FROM bi.fivetran_granular_google_ads_2.granular_campaign_daily)
    ,marketing_country_grouping AS (SELECT * FROM bi.google_sheets.marketing_country_grouping)

, renamed AS (

    SELECT
        date::DATE                          AS day,
        id                                  AS campaign_id,
        name                                AS campaign_name,
        advertising_channel_type,
        advertising_channel_sub_type,

        -- Derived dimensions: parse these from campaign_name conventions
        -- Adjust SPLIT logic to match your actual naming convention
        -- e.g. "UK_EN_Search_Books_Brand_Exact" → market=UK, language=EN, etc.
        --SPLIT_PART(name, '_', 1)            AS market,
        IFNULL(mcg.market, 'Other')        AS market,
        SPLIT_PART(name, '_', 2)            AS language,
        SPLIT_PART(name, '_', 3)            AS channel,
        SPLIT_PART(name, '_', 4)            AS category,
        SPLIT_PART(name, '_', 5)            AS type,
        SPLIT_PART(name, '_', 6)            AS theme,
        SPLIT_PART(name, '_', 7)            AS misc,

        -- Metrics (cost_micros → GBP/EUR)
        SUM(impressions)                    AS impressions,
        SUM(clicks)                         AS clicks,
        SUM(cost_micros / 1000000.0)        AS cost,
        SUM(interactions)                   AS interactions,
        SUM(conversions)                    AS conversions,
        SUM(conversions_value)              AS conversions_value,

         MAX(CAST('2026-08-06 07:45:22.763066+00:00' AS TIMESTAMP)) AS etl_ts,

         CASE WHEN (lower(campaign_name) LIKE '%mum%' OR lower(campaign_name) LIKE '%mother%' OR lower(campaign_name) LIKE '%dad%' OR lower(campaign_name) LIKE '%father%')
              THEN 'Occasion'
              ELSE 'Evergreen'
        END AS trading_category,

        IFNULL(mcg.country, 'Other')        AS country,
        IFNULL(mcg.countries_top_8, 'Other') AS countries_top_8

    FROM source
        LEFT JOIN marketing_country_grouping AS mcg
            ON LOWER(source.name) LIKE CONCAT('%', LOWER(mcg.campaign_name_contains), '%')
    GROUP BY
        date::DATE,
        id,
        name,
        advertising_channel_type,
        advertising_channel_sub_type,
        IFNULL(mcg.market, 'Other'),
        IFNULL(mcg.country, 'Other'),
        IFNULL(mcg.countries_top_8, 'Other')
)

SELECT *
FROM renamed