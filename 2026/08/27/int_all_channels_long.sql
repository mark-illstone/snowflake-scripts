

WITH pmax AS (SELECT * FROM bi.dbt_production_models.fct_granular_google_pmax)

, shopping AS (SELECT * FROM bi.dbt_production_models.fct_granular_google_shopping)

, meta_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_categorised)

, search AS (SELECT * FROM bi.dbt_production_models.fct_granular_google_campaigns)

, transaction_details AS (SELECT * FROM BI.shareasale.transaction_details)

, impact_reports AS (SELECT * FROM bi.dbt_production_intermediate.int_impact_structured_reports)

, manual_affiliate_ads AS (SELECT * FROM bi.google_sheets.manual_affiliates_cost)




, google_pmax AS (
    SELECT
        day,
        country,
        case when market = 'Other' then 'ROW' else market end as market, 
        CASE WHEN countries_top_8 = 'Other' THEN 'ROW' ELSE countries_top_8 END AS countries_top_8,
        product_slug AS product,
        keepsake_kids,
        subcategory,
        keepsake_kids_subcategory,
        'Google PMAX' AS channel,
        cost,
        clicks,
        impressions
    FROM pmax
)

, google_shopping AS (
    SELECT
        day,
        country,
        case when market = 'Other' then 'ROW' else market end as market, 
        CASE WHEN countries_top_8 = 'Other' THEN 'ROW' ELSE countries_top_8 END AS countries_top_8,
        product_slug AS product,
        keepsake_kids,
        subcategory,
        keepsake_kids_subcategory,
        'Google Shopping' AS channel,
        cost,
        clicks,
        impressions
    FROM shopping
)

, meta AS (
    -- reads straight from int_facebook_categorised now — fct_facebook_granular_data
    -- no longer needed as a separate intermediate
    SELECT
        day,
        country,
        market,
        countries_top_8,
        product_slug AS product,
        keepsake_kids,
        subcategory,
        keepsake_kids_subcategory,
        meta_ad_type AS channel,
        amount_spent AS cost,
        action_link_click AS clicks,
        impressions
    FROM meta_ads
)

, google_search AS (
    SELECT
        day,
        country,
        market,
        countries_top_8,
        CAST(NULL AS VARCHAR) AS product,
        CAST(NULL AS VARCHAR) AS keepsake_kids,
        CAST(NULL AS VARCHAR) AS subcategory,
        CAST(NULL AS VARCHAR) AS keepsake_kids_subcategory,
        -- CASE
        --     WHEN LOWER(type) = 'brand' THEN 'Google Search - Brand'
        --     ELSE 'Google Search - Non-Brand'
        -- END AS channel,
        CASE
            WHEN LOWER(campaign_name) like '%brand%' THEN 'Google Search - Brand'
            ELSE 'Google Search - Non-Brand'
        END AS channel,
        cost,
        clicks,
        impressions
    FROM search  
    WHERE advertising_channel_type = 'SEARCH'
)

, affiliate_spend AS (
       SELECT
        to_char(to_date(CASE WHEN dateofclick = '' THEN dateoftrans ELSE dateofclick END), 'YYYYMMDD')::int AS day,
        SUM(commission) + SUM(ssamount) AS cost
    FROM transaction_details
    GROUP BY 1

    UNION ALL

    SELECT day, cost FROM impact_reports
)
 
, affiliates AS (
    SELECT
        TO_DATE(day::VARCHAR, 'YYYYMMDD') AS day,
        CAST(NULL AS VARCHAR) AS country,
        CAST(NULL AS VARCHAR) AS market,
        CAST(NULL AS VARCHAR) AS countries_top_8,
        CAST(NULL AS VARCHAR) AS product,
        CAST(NULL AS VARCHAR) AS keepsake_kids,
        CAST(NULL AS VARCHAR) AS subcategory,
        CAST(NULL AS VARCHAR) AS keepsake_kids_subcategory,
        'Affiliates - Affiliate' AS channel,
        cost,
        CAST(NULL AS NUMBER) AS clicks,
        CAST(NULL AS NUMBER) AS impressions
    FROM affiliate_spend
)
 
, manual_affiliates AS (
    SELECT
        TO_DATE(to_varchar(date::date, 'YYYYMMDD'), 'YYYYMMDD') AS day,
        CAST(NULL AS VARCHAR) AS country,
        CAST(NULL AS VARCHAR) AS market,
        CAST(NULL AS VARCHAR) AS countries_top_8,
        CAST(NULL AS VARCHAR) AS product,
        CAST(NULL AS VARCHAR) AS keepsake_kids,
        CAST(NULL AS VARCHAR) AS subcategory,
        CAST(NULL AS VARCHAR) AS keepsake_kids_subcategory,
        CASE
            WHEN LOWER(type) = 'ambassadors' THEN 'Affiliates - Ambassador'
            ELSE 'Affiliates - Affiliate'
        END AS channel,
        COALESCE(REPLACE(cost_gbp, ',', '')::FLOAT, 0) AS cost,
        CAST(NULL AS NUMBER) AS clicks,
        CAST(NULL AS NUMBER) AS impressions
    FROM manual_affiliate_ads
    WHERE date::date <= CURRENT_DATE
)
 
SELECT * FROM google_pmax
UNION ALL
SELECT * FROM google_shopping
UNION ALL
SELECT * FROM meta
UNION ALL
SELECT * FROM google_search
UNION ALL
SELECT * FROM affiliates
UNION ALL
SELECT * FROM manual_affiliates