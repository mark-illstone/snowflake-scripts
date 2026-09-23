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
    SELECT *,

    CASE
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(ROW|GLOBAL|ALL)([_-]|$).*') THEN
            CASE
                WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(JP|JPN)([_-]|$).*')  THEN 'ROW-JP'
                WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(DE|DEU)([_-]|$).*')  THEN 'ROW-DE'
                WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(NL|NLD)([_-]|$).*')  THEN 'ROW-NL'
                WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(ES|ESP)([_-]|$).*')  THEN 'ROW-ES'
                WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(FR|FRA)([_-]|$).*')  THEN 'ROW-FR'
            END
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(UK|GBR)([_-]|$).*') THEN 'UK'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(AU|AUS)([_-]|$).*') THEN 'AU'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(US|USA)([_-]|$).*') THEN 'US'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(CA|CAN)([_-]|$).*') THEN 'CA'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(FR|FRA)([_-]|$).*') THEN 'FR'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(ES|ESP)([_-]|$).*') THEN 'ES'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(IT|ITA)([_-]|$).*') THEN 'IT'
        WHEN REGEXP_LIKE(UPPER(adset_name), '.*(^|[_-])(DE|DEU)([_-]|$).*') THEN 'DE'
END AS adset_country,

    CASE
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(ROW|GLOBAL|ALL)([_-]|$).*') THEN
            CASE
                WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(JP|JPN)([_-]|$).*')  THEN 'ROW-JP'
                WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(DE|DEU)([_-]|$).*')  THEN 'ROW-DE'
                WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(NL|NLD)([_-]|$).*')  THEN 'ROW-NL'
                WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(ES|ESP)([_-]|$).*')  THEN 'ROW-ES'
                WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(FR|FRA)([_-]|$).*')  THEN 'ROW-FR'
            END
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(UK|GBR)([_-]|$).*') THEN 'UK'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(AU|AUS)([_-]|$).*') THEN 'AU'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(US|USA)([_-]|$).*') THEN 'US'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(CA|CAN)([_-]|$).*') THEN 'CA'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(FR|FRA)([_-]|$).*') THEN 'FR'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(ES|ESP)([_-]|$).*') THEN 'ES'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(IT|ITA)([_-]|$).*') THEN 'IT'
        WHEN REGEXP_LIKE(UPPER(campaign_name_gsheet), '.*(^|[_-])(DE|DEU)([_-]|$).*') THEN 'DE'
    END AS campaign_country,

        COALESCE(adset_country, campaign_country, 'ROW-EN') AS country
    FROM named
)
,temp as (
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
    aa.subcategory as keepsake_kids_subcategory,


    LOWER(SPLIT_PART(COALESCE(cd.ad_name_gsheet, cd.ad_name), '_', 2)) as first_acronym,
    feed_product_id as feed_product_id2,

FROM country_derived cd
LEFT JOIN product_categories pc_by_product ON LOWER(cd.feed_product_id) = LOWER(pc_by_product.id)
LEFT JOIN acronym_adjustment aa ON LOWER(SPLIT_PART(COALESCE(cd.ad_name_gsheet, cd.ad_name), '_', 2)) = LOWER(aa.acronym)
LEFT JOIN product_categories pc_by_name ON LOWER(aa.final_acronym) = LOWER(pc_by_name.acronym)
)

select ad_id, amount_spent, feed_product_id2, first_acronym
from temp
where day like '2025%'
and market = 'AU'
and keepsake_kids is null
--group by 2;