

WITH cp AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_country_product)

, ad_insights AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_ad_insights)

    , product_categories as (select * from bi.google_sheets.marketing_product_categories)
    , acronym_adjustment as (select * from bi.google_sheets.marketing_acronym_adjustment)


, named AS (
    SELECT
        cp.*,
        ai.campaign_name,
        ai.campaign_id,
        ai.campaign_name_gsheet,
        ai.adset_name,
        ai.adset_id,
        ai.ad_name,
        ai.ad_name_gsheet,
        ai.created_date,
        UPPER(COALESCE(ai.campaign_name_gsheet, ai.campaign_name)) AS campaign_name_upper
    FROM cp
    LEFT JOIN ad_insights ai ON cp.ad_id = ai.ad_id AND cp.day = ai.day
)

, country_derived AS (
    SELECT
        *,
        CASE
            WHEN CONTAINS(campaign_name_upper, 'ROW') OR CONTAINS(campaign_name_upper, 'GLOBAL') OR CONTAINS(campaign_name_upper, '_ALL_') THEN
                CASE
                    WHEN CONTAINS(campaign_name_upper, '_JP') OR CONTAINS(campaign_name_upper, '-JP') THEN 'ROW-JP'
                    WHEN CONTAINS(campaign_name_upper, '_DE') OR CONTAINS(campaign_name_upper, '-DE') THEN 'ROW-DE'
                    WHEN CONTAINS(campaign_name_upper, '_NL') OR CONTAINS(campaign_name_upper, '-NL') THEN 'ROW-NL'
                    WHEN CONTAINS(campaign_name_upper, '_ES') OR CONTAINS(campaign_name_upper, '-ES') THEN 'ROW-ES'
                    WHEN CONTAINS(campaign_name_upper, '_FR') OR CONTAINS(campaign_name_upper, '-FR') THEN 'ROW-FR'
                    ELSE 'ROW-EN'
                END
            WHEN CONTAINS(campaign_name_upper, '_UK') OR CONTAINS(campaign_name_upper, '-UK') OR CONTAINS(campaign_name_upper, '_GBR') THEN 'UK'
            WHEN CONTAINS(campaign_name_upper, '_US') OR CONTAINS(campaign_name_upper, '-US') OR CONTAINS(campaign_name_upper, '_USA') THEN 'US'
            WHEN CONTAINS(campaign_name_upper, '_AU') OR CONTAINS(campaign_name_upper, '-AU') OR CONTAINS(campaign_name_upper, '_AUS') THEN 'AU'
            WHEN CONTAINS(campaign_name_upper, '_CA') OR CONTAINS(campaign_name_upper, '-CA') OR CONTAINS(campaign_name_upper, '_CAN') THEN 'CA'
            WHEN CONTAINS(campaign_name_upper, '_FR') OR CONTAINS(campaign_name_upper, '-FR') OR CONTAINS(campaign_name_upper, '_FRA') THEN 'FR'
            WHEN CONTAINS(campaign_name_upper, '_ES') OR CONTAINS(campaign_name_upper, '-ES') OR CONTAINS(campaign_name_upper, '_ESP') THEN 'ES'
            WHEN CONTAINS(campaign_name_upper, '_IT') OR CONTAINS(campaign_name_upper, '-IT') OR CONTAINS(campaign_name_upper, '_ITA') THEN 'IT'
            WHEN CONTAINS(campaign_name_upper, '_DE') OR CONTAINS(campaign_name_upper, '-DE') OR CONTAINS(campaign_name_upper, '_DEU') THEN 'DE'
            ELSE 'ROW-EN'
        END AS country
    FROM named
)

,temp as(
SELECT
    ad_id,
    day,
    feed_product_id,
    meta_ad_type,
    amount_spent,
    impressions,
    action_link_click,
    campaign_name,
    campaign_id,
    campaign_name_gsheet,
    adset_name,
    adset_id,
    ad_name,
    ad_name_gsheet,
    created_date,
    country,
    country AS market,
    CASE WHEN country LIKE 'ROW-%' THEN 'ROW' ELSE country END AS countries_top_8,
    COALESCE(pc_by_product.subcategory, pc_by_name.subcategory,
             CASE WHEN feed_product_id = 'Unattributed' THEN 'Unattributed' END) AS subcategory,
    COALESCE(pc_by_product.keepsake_kids, pc_by_name.keepsake_kids,
             CASE WHEN feed_product_id = 'Unattributed' THEN 'Unattributed' END) AS keepsake_kids,
    pc_by_name.id as product_slug,
    LOWER(SPLIT_PART(COALESCE(cd.ad_name_gsheet, cd.ad_name), '_', 2)) as acronym
FROM country_derived cd
LEFT JOIN product_categories pc_by_product ON LOWER(cd.feed_product_id) = LOWER(pc_by_product.id)
LEFT JOIN acronym_adjustment aa ON LOWER(SPLIT_PART(COALESCE(cd.ad_name_gsheet, cd.ad_name), '_', 2)) = LOWER(aa.acronym)
LEFT JOIN product_categories pc_by_name ON LOWER(aa.final_acronym) = LOWER(pc_by_name.acronym)
)

select sum(amount_spent)
from temp
where day >= '2026-08-17'
order by 1