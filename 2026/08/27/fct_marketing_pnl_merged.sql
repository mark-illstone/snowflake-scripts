

WITH fct_pnl_by_country_category AS (SELECT * FROM bi.dbt_production_models.fct_pnl_by_country_category)
,  fct_paid_marketing_by_channel_pivoted AS (SELECT * FROM bi.dbt_production_models.fct_paid_marketing_by_channel_pivoted)



, marketing_agg AS (
    SELECT
        day,
        CASE
            WHEN market IN ('ROW-EN', 'ROW-FR', 'ROW-DE', 'ROW-ES', 'ROW-JP') THEN 'ROW'
            ELSE market
        END AS market,
        keepsake_kids,
        keepsake_kids_subcategory,
        product,
 
        SUM(google_pmax_spend)        AS google_pmax_spend,
        SUM(google_pmax_clicks)       AS google_pmax_clicks,
        SUM(google_pmax_impressions)  AS google_pmax_impressions,
 
        SUM(google_shopping_spend)       AS google_shopping_spend,
        SUM(google_shopping_clicks)      AS google_shopping_clicks,
        SUM(google_shopping_impressions) AS google_shopping_impressions,
 
        SUM(meta_ads_spend)        AS meta_ads_spend,
        SUM(meta_ads_clicks)       AS meta_ads_clicks,
        SUM(meta_ads_impressions)  AS meta_ads_impressions,
 
        SUM(meta_dpa_spend)        AS meta_dpa_spend,
        SUM(meta_dpa_clicks)       AS meta_dpa_clicks,
        SUM(meta_dpa_impressions)  AS meta_dpa_impressions,
 
        SUM(search_brand_spend)        AS search_brand_spend,
        SUM(search_brand_clicks)       AS search_brand_clicks,
        SUM(search_brand_impressions)  AS search_brand_impressions,
 
        SUM(search_nonbrand_spend)        AS search_nonbrand_spend,
        SUM(search_nonbrand_clicks)       AS search_nonbrand_clicks,
        SUM(search_nonbrand_impressions)  AS search_nonbrand_impressions,
 
        SUM(affiliates_affiliate_spend)  AS affiliates_affiliate_spend,
        SUM(affiliates_ambassador_spend) AS affiliates_ambassador_spend,
        
        SUM(total_spend) AS total_spend

 
        -- cpc/cpm/ctr intentionally excluded - recompute as DIV0(spend, clicks/impressions)
        -- downstream if needed; never sum pre-computed per-row ratios.
 
    FROM fct_paid_marketing_by_channel_pivoted
    GROUP BY
        day,
        CASE
            WHEN market IN ('ROW-EN', 'ROW-FR', 'ROW-DE', 'ROW-ES', 'ROW-JP') THEN 'ROW'
            ELSE market
        END,
        keepsake_kids,
        keepsake_kids_subcategory,
        product
)
SELECT
    COALESCE(m.day, p.day) AS day,
    COALESCE(m.market, p.trade_country_group) AS market,

    COALESCE(NULLIF(COALESCE(m.keepsake_kids,             p.sub_category    ), ''), 'Not attributed') AS keepsake_kids,
    COALESCE(NULLIF(COALESCE(m.keepsake_kids_subcategory, p.sub_product_type), ''), 'Not attributed') AS keepsake_kids_subcategory,
    COALESCE(NULLIF(COALESCE(m.product,                   p.brand           ), ''), 'Not attributed') AS product,

    m.* EXCLUDE (day, market, keepsake_kids, product, keepsake_kids_subcategory),
    p.* EXCLUDE (day, trade_country_group, sub_category, brand, sub_product_type),


FROM marketing_agg m
FULL OUTER JOIN fct_pnl_by_country_category p
    ON  m.day = p.day
    AND m.market = p.trade_country_group
    AND m.keepsake_kids = p.sub_category
    AND LOWER(m.product) = LOWER(p.brand)
    AND m.keepsake_kids_subcategory = p.sub_product_type