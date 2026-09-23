-- Grain: product_item_id × asset_group_id × campaign_id × date
-- Source: granular_shopping_daily (Fivetran custom report)
-- PMax and Shopping campaigns only — never union with search/keyword tables
-- Campaign dimensions left-joined from stg_campaign_daily

WITH source AS (
    SELECT * FROM bi.fivetran_granular_google_ads_2.granular_shopping_daily)

-- Pull campaign-level derived dims from the campaign staging model
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
        trading_category,
        country,
        countries_top_8
    FROM bi.dbt_production_models.fct_granular_google_campaigns
)


, acronym_adjustment AS (
    SELECT *
    FROM bi.google_sheets.marketing_acronym_adjustment
    QUALIFY ROW_NUMBER() OVER (PARTITION BY acronym ORDER BY _row DESC) = 1
)

, product_categories as (select * from bi.google_sheets.marketing_product_categories)

-- , product_categories AS (
--     SELECT *
--     FROM bi.google_sheets.marketing_product_categories
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY acronym ORDER BY _row DESC) = 1
-- )

, acronym_adjustment AS (
    SELECT *
    FROM bi.google_sheets.marketing_acronym_adjustment
    QUALIFY ROW_NUMBER() OVER (PARTITION BY acronym ORDER BY _row DESC) = 1
)

, renamed AS (
    SELECT
        s.date::DATE                        AS day,
        s.campaign_id,
        s.campaign_advertising_channel_type,
        --s.advertising_channel_sub_type,

        -- Asset group (PMax specific)
        -- Add these if your custom report includes them:
        -- s.asset_group_id,
        -- s.asset_group_name,

        -- Product dimensions
         s.product_item_id,                -- add if in your report
         s.product_title,                  -- add if in your report
        -- s.item_group_id,                  -- add if in your report
        s.product_custom_attribute_0,
        s.product_custom_attribute_1,
        s.product_custom_attribute_2,
        s.product_custom_attribute_3,
        s.product_custom_attribute_4,

        -- Campaign dimensions from lookup
        c.campaign_name,
        c.market,
        c.language,
        c.channel,
        c.category,
        c.type,
        c.theme,
        c.trading_category,
        c.country,
        c.countries_top_8,

        -- Metrics
        SUM(s.impressions)                  AS impressions,
        SUM(s.clicks)                       AS clicks,
        SUM(s.cost_micros / 1000000.0)      AS cost,
       -- SUM(s.interactions)                 AS interactions,
        SUM(s.conversions)                  AS conversions,
        SUM(s.conversions_value)            AS conversions_value,

        MAX(CAST('2026-08-27 08:53:55.490179+00:00' AS TIMESTAMP)) AS etl_ts,

        COALESCE(NULLIF(aa.keepsake_kids, ''), 'Acronym not matched') AS keepsake_kids,
        COALESCE(NULLIF(aa.subcategory,   ''), 'Acronym not matched') AS keepsake_kids_subcategory,

        p.subcategory,
        p.id AS product_slug

    FROM source s
    LEFT JOIN campaigns c ON c.campaign_id = s.campaign_id
    LEFT JOIN acronym_adjustment aa ON lower(s.product_custom_attribute_2) = lower(aa.acronym)
    LEFT JOIN product_categories p ON LOWER(aa.final_acronym) = lower(p.acronym)
    GROUP BY
        s.date::DATE,
        s.campaign_id,
        s.campaign_advertising_channel_type,
        --s.advertising_channel_sub_type,
        s.product_custom_attribute_0,
        s.product_custom_attribute_1,
        s.product_custom_attribute_2,
        s.product_custom_attribute_3,
        s.product_custom_attribute_4,
        s.product_item_id,
        s.product_title,
        c.campaign_name,
        c.market,
        c.language,
        c.channel,
        c.category,
        c.type,
        c.theme,
        c.trading_category,
        c.country,
        c.countries_top_8,
        aa.keepsake_kids,
        aa.subcategory,
        p.subcategory,
        p.id
)

SELECT * FROM renamed