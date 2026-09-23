

WITH all_channels_long AS (SELECT * FROM bi.dbt_production_intermediate.int_all_channels_long)


SELECT
    day,
    country,
    market,
    countries_top_8,
    product,
    keepsake_kids,
    subcategory,
    keepsake_kids_subcategory,

    SUM(CASE WHEN channel = 'Google PMAX' THEN cost END) AS google_pmax_spend,
    SUM(CASE WHEN channel = 'Google PMAX' THEN clicks END) AS google_pmax_clicks,
    SUM(CASE WHEN channel = 'Google PMAX' THEN impressions END) AS google_pmax_impressions,
    DIV0(SUM(CASE WHEN channel = 'Google PMAX' THEN cost END), SUM(CASE WHEN channel = 'Google PMAX' THEN clicks END)) AS google_pmax_cpc,
    DIV0(SUM(CASE WHEN channel = 'Google PMAX' THEN cost END), SUM(CASE WHEN channel = 'Google PMAX' THEN impressions END)) * 1000 AS google_pmax_cpm,
    DIV0(SUM(CASE WHEN channel = 'Google PMAX' THEN clicks END), SUM(CASE WHEN channel = 'Google PMAX' THEN impressions END)) AS google_pmax_ctr,

    SUM(CASE WHEN channel = 'Google Shopping' THEN cost END) AS google_shopping_spend,
    SUM(CASE WHEN channel = 'Google Shopping' THEN clicks END) AS google_shopping_clicks,
    SUM(CASE WHEN channel = 'Google Shopping' THEN impressions END) AS google_shopping_impressions,
    DIV0(SUM(CASE WHEN channel = 'Google Shopping' THEN cost END), SUM(CASE WHEN channel = 'Google Shopping' THEN clicks END)) AS google_shopping_cpc,
    DIV0(SUM(CASE WHEN channel = 'Google Shopping' THEN cost END), SUM(CASE WHEN channel = 'Google Shopping' THEN impressions END)) * 1000 AS google_shopping_cpm,
    DIV0(SUM(CASE WHEN channel = 'Google Shopping' THEN clicks END), SUM(CASE WHEN channel = 'Google Shopping' THEN impressions END)) AS google_shopping_ctr,

    SUM(CASE WHEN channel = 'Meta Ads' THEN cost END) AS meta_ads_spend,
    SUM(CASE WHEN channel = 'Meta Ads' THEN clicks END) AS meta_ads_clicks,
    SUM(CASE WHEN channel = 'Meta Ads' THEN impressions END) AS meta_ads_impressions,
    DIV0(SUM(CASE WHEN channel = 'Meta Ads' THEN cost END), SUM(CASE WHEN channel = 'Meta Ads' THEN clicks END)) AS meta_ads_cpc,
    DIV0(SUM(CASE WHEN channel = 'Meta Ads' THEN cost END), SUM(CASE WHEN channel = 'Meta Ads' THEN impressions END)) * 1000 AS meta_ads_cpm,
    DIV0(SUM(CASE WHEN channel = 'Meta Ads' THEN clicks END), SUM(CASE WHEN channel = 'Meta Ads' THEN impressions END)) AS meta_ads_ctr,

    SUM(CASE WHEN channel = 'Meta DPA' THEN cost END) AS meta_dpa_spend,
    SUM(CASE WHEN channel = 'Meta DPA' THEN clicks END) AS meta_dpa_clicks,
    SUM(CASE WHEN channel = 'Meta DPA' THEN impressions END) AS meta_dpa_impressions,
    DIV0(SUM(CASE WHEN channel = 'Meta DPA' THEN cost END), SUM(CASE WHEN channel = 'Meta DPA' THEN clicks END)) AS meta_dpa_cpc,
    DIV0(SUM(CASE WHEN channel = 'Meta DPA' THEN cost END), SUM(CASE WHEN channel = 'Meta DPA' THEN impressions END)) * 1000 AS meta_dpa_cpm,
    DIV0(SUM(CASE WHEN channel = 'Meta DPA' THEN clicks END), SUM(CASE WHEN channel = 'Meta DPA' THEN impressions END)) AS meta_dpa_ctr,

    SUM(CASE WHEN channel = 'Google Search - Brand' THEN cost END) AS search_brand_spend,
    SUM(CASE WHEN channel = 'Google Search - Brand' THEN clicks END) AS search_brand_clicks,
    SUM(CASE WHEN channel = 'Google Search - Brand' THEN impressions END) AS search_brand_impressions,
    DIV0(SUM(CASE WHEN channel = 'Google Search - Brand' THEN cost END), SUM(CASE WHEN channel = 'Google Search - Brand' THEN clicks END)) AS search_brand_cpc,
    DIV0(SUM(CASE WHEN channel = 'Google Search - Brand' THEN cost END), SUM(CASE WHEN channel = 'Google Search - Brand' THEN impressions END)) * 1000 AS search_brand_cpm,
    DIV0(SUM(CASE WHEN channel = 'Google Search - Brand' THEN clicks END), SUM(CASE WHEN channel = 'Google Search - Brand' THEN impressions END)) AS search_brand_ctr,

    SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN cost END) AS search_nonbrand_spend,
    SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN clicks END) AS search_nonbrand_clicks,
    SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN impressions END) AS search_nonbrand_impressions,
    DIV0(SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN cost END), SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN clicks END)) AS search_nonbrand_cpc,
    DIV0(SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN cost END), SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN impressions END)) * 1000 AS search_nonbrand_cpm,
    DIV0(SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN clicks END), SUM(CASE WHEN channel = 'Google Search - Non-Brand' THEN impressions END)) AS search_nonbrand_ctr,

    SUM(CASE WHEN channel = 'Affiliates - Affiliate' THEN cost END) AS affiliates_affiliate_spend,
    NULL AS affiliates_affiliate_clicks,
    NULL AS affiliates_affiliate_impressions,
    NULL AS affiliates_affiliate_cpc,
    NULL AS affiliates_affiliate_cpm,
    NULL AS affiliates_affiliate_ctr,

    SUM(CASE WHEN channel = 'Affiliates - Ambassador' THEN cost END) AS affiliates_ambassador_spend,
    NULL AS affiliates_ambassador_clicks,
    NULL AS affiliates_ambassador_impressions,
    NULL AS affiliates_ambassador_cpc,
    NULL AS affiliates_ambassador_cpm,
    NULL AS affiliates_ambassador_ctr,

    COALESCE(google_pmax_spend, 0)
  + COALESCE(google_shopping_spend, 0)
  + COALESCE(meta_ads_spend, 0)
  + COALESCE(meta_dpa_spend, 0)
  + COALESCE(search_brand_spend, 0)
  + COALESCE(search_nonbrand_spend, 0)
  + COALESCE(affiliates_affiliate_spend, 0) 
  + COALESCE(affiliates_ambassador_spend, 0) AS total_spend

FROM all_channels_long
GROUP BY day, country, market, countries_top_8, product, keepsake_kids, subcategory, keepsake_kids_subcategory