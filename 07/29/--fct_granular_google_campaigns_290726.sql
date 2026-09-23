--fct_granular_google_campaigns

CREATE OR REPLACE TABLE bi.mark_dev.fct_granular_google_campaigns AS

WITH  source AS (SELECT * FROM bi.fivetran_granular_google_ads_2.granular_campaign_daily)
    , shopping AS (SELECT * FROM bi.fivetran_granular_google_ads_2.granular_shopping_daily)
    , pmax AS (SELECT * FROM bi.fivetran_granular_google_ads_3.granular_pmax_daily)
    , product_categories AS (SELECT * FROM bi.google_sheets.marketing_product_categories)
    , acronym_adjustment AS (SELECT * FROM bi.google_sheets.marketing_acronym_adjustment)

    , dedupe_product_categories AS (
        SELECT *
        FROM product_categories
        QUALIFY ROW_NUMBER() OVER (PARTITION BY acronym ORDER BY _row DESC) = 1
)

    , dedupe_shopping AS (
        SELECT campaign_id, product_custom_attribute_2
        FROM shopping
        QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id, product_custom_attribute_2 ORDER BY date DESC) = 1
    )

    , dedupe_pmax AS (
        SELECT campaign_id, product_custom_attribute_2
        FROM pmax
        QUALIFY ROW_NUMBER() OVER (PARTITION BY campaign_id, product_custom_attribute_2 ORDER BY date DESC) = 1
    )


, renamed AS (

    SELECT
        s.date::DATE                          AS day,
        s.id                                  AS campaign_id,
        s.name                                AS campaign_name,
        s.advertising_channel_type,
        s.advertising_channel_sub_type,

        -- Derived dimensions: parse these from campaign_name conventions
        -- Adjust SPLIT logic to match your actual naming convention
        -- e.g. "UK_EN_Search_Books_Brand_Exact" → market=UK, language=EN, etc.
        SPLIT_PART(s.name, '_', 1)            AS market,
        SPLIT_PART(s.name, '_', 2)            AS language,
        SPLIT_PART(s.name, '_', 3)            AS channel,
        SPLIT_PART(s.name, '_', 4)            AS category,
        SPLIT_PART(s.name, '_', 5)            AS type,
        SPLIT_PART(s.name, '_', 6)            AS theme,
        SPLIT_PART(s.name, '_', 7)            AS misc,

        -- Metrics (cost_micros → GBP/EUR)
        SUM(s.impressions)                    AS impressions,
        SUM(s.clicks)                         AS clicks,
        SUM(s.cost_micros / 1000000.0)        AS cost,
        SUM(s.interactions)                   AS interactions,
        SUM(s.conversions)                    AS conversions,
        SUM(s.conversions_value)              AS conversions_value,

         MAX(CAST('2026-07-29 07:45:21.889197+00:00' AS TIMESTAMP)) AS etl_ts,

         CASE WHEN (lower(campaign_name) LIKE '%mum%' OR lower(campaign_name) LIKE '%mother%' OR lower(campaign_name) LIKE '%dad%' OR lower(campaign_name) LIKE '%father%')
              THEN 'Occasion'
              ELSE 'Evergreen'
        END AS trading_category,

        aa.keepsake_kids

    FROM source s
    LEFT JOIN dedupe_shopping ds ON s.id = ds.campaign_id AND s.advertising_channel_type = 'SHOPPING'
    LEFT JOIN dedupe_pmax dp ON s.id = dp.campaign_id AND s.advertising_channel_type = 'PERFORMANCE_MAX'
    LEFT JOIN acronym_adjustment aa ON LOWER(COALESCE(ds.product_custom_attribute_2, dp.product_custom_attribute_2)) = LOWER(aa.acronym)
    LEFT JOIN product_categories p ON LOWER(aa.final_acronym) = LOWER(p.acronym)
    GROUP BY
        s.date::DATE,
        s.id,
        s.name,
        s.advertising_channel_type,
        s.advertising_channel_sub_type,
        aa.keepsake_kids
)

SELECT * FROM renamed