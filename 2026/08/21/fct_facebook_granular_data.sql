CREATE OR REPLACE TABLE bi.mark_dev.fct_facebook_granular_data as

WITH ad_insights AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_ad_insights)
    , ad_insights_actions as (select * from bi.dbt_production_intermediate.int_facebook_ad_insights_actions)
    , video_actions as (select * from bi.dbt_production_intermediate.int_custom_video_actions)
    , product_categories as (select * from bi.google_sheets.marketing_product_categories)
    , acronym_adjustment as (select * from bi.google_sheets.marketing_acronym_adjustment)

    , base AS (
    SELECT
        day,
        campaign_name AS adcampaign_name,
        campaign_name_gsheet,
        campaign_id AS adcampaign_id,
        adset_name,
        adset_name_gsheet,
        adset_id,
        ad_name,
        ad_name_gsheet,
        ad_id,
        created_date,
        impressions,
        inline_link_clicks AS action_link_click,
        spend AS amount_spent
    FROM ad_insights
),

actions AS (
    SELECT
        ad_id,
        day,
        SUM(CASE WHEN action_type = 'offsite_conversion.fb_pixel_add_to_cart' THEN value END) AS offsite_conversions_fb_pixel_add_to_cart,
        SUM(CASE WHEN action_type = 'landing_page_view' THEN value END) AS landing_page_views,
        SUM(CASE WHEN action_type = 'purchase' THEN value END) AS conversions,
        SUM(CASE WHEN action_type = 'purchase_revenue' THEN value END) AS revenue,
        SUM(CASE WHEN action_type = 'video_view' THEN value END) AS video_3_second_plays
    FROM ad_insights_actions
    WHERE action_type IN (
        'offsite_conversion.fb_pixel_add_to_cart',
        'landing_page_view',
        'purchase',
        'purchase_revenue',
        'video_view'
    )
    GROUP BY 1,2
),

video_metrics AS (
    SELECT
        ad_id,
        day,
        SUM(CASE WHEN action_type = 'total_plays' THEN value END) AS action_video_view,
        SUM(CASE WHEN action_type = 'video_thruplay_watched_actions' THEN value END) AS video_thruplay_watched_actions,
        SUM(CASE WHEN action_type = '1_day_conversions' THEN value END) AS one_day_conversions,
        SUM(CASE WHEN action_type = '1_day_revenue' THEN value END) AS one_day_revenue,
    FROM video_actions
    WHERE action_type IN (
        'total_plays',
        'video_thruplay_watched_actions',
        '1_day_conversions',
        '1_day_revenue'
    )
    GROUP BY 1,2
)

-- dedupe_product_categories AS (
--     SELECT *
--     FROM product_categories
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY acronym ORDER BY _row DESC) = 1
-- )

SELECT
    b.day,
    b.adcampaign_name,
    b.adcampaign_id,
    b.adset_name,
    b.adset_id,
    b.ad_name,
    b.ad_id,
    b.created_date,

    -- =====================
    -- Campaign dimensions
    -- =====================
    SPLIT_PART(COALESCE(b.campaign_name_gsheet, b.adcampaign_name), '_', 1) AS campaign_strategy,
    SPLIT_PART(COALESCE(b.campaign_name_gsheet, b.adcampaign_name), '_', 2) AS campaign_type,
    TRY_TO_DATE(SPLIT_PART(COALESCE(b.campaign_name_gsheet, b.adcampaign_name), '_', 5), 'DDMMYY') AS campaign_launch_date,
    SPLIT_PART(COALESCE(b.campaign_name_gsheet, b.adcampaign_name), '_', 6) AS campaign_objective,
    SPLIT_PART(COALESCE(b.campaign_name_gsheet, b.adcampaign_name), '_', 7) AS campaign_name_extracted,

    CASE WHEN LOWER(COALESCE(b.campaign_name_gsheet, b.adcampaign_name)) LIKE '%seasonal%' THEN 'Occasion'
         ELSE 'Evergreen'
         END AS trading_category,

    -- =====================
    -- Ad set dimensions
    -- =====================
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 1) AS product_category,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 2) AS audience_type,
    TRY_TO_DATE(SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 3), 'DDMMYY') AS adset_launch_date,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 4) AS audience_description,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 5) AS market,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 6) AS age_from,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 7) AS age_to,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 8) AS gender,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 9) AS optimisation_goal,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 10) AS attribution_window,
    SPLIT_PART(COALESCE(b.adset_name_gsheet, b.adset_name), '_', 11) AS adset_misc_info,

    -- =====================
    -- Ad dimensions
    -- =====================
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 1)  AS ad_language,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 2)  AS ad_product_type,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 3)  AS ad_product_category,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 4)  AS ad_format,
    TRY_TO_DATE(SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 5), 'DDMMYY') AS ad_launch_date,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 6)  AS ad_concept_name,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 7)  AS ad_hook,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 8)  AS ad_style,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 9)  AS ad_motivator,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 10) AS ad_barriers,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 11) AS ad_source,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 12) AS ad_creator_name,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 13) AS ad_creator_demo,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 14) AS ad_voiceover_accent,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 15) AS ad_persona,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 16) AS ad_occasion,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 17) AS ad_version,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 18) AS ad_offer,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 19) AS ad_landing_page,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 20) AS ad_wave_number,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 21) AS ad_variant_description,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 22) AS ad_specific_concept,
    SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 23) AS ad_relationship,

    -- =====================
    -- Metrics
    -- =====================
    b.impressions,
    b.action_link_click,
    b.amount_spent,

    a.conversions,
    a.revenue,
    v.one_day_conversions,
    v.one_day_revenue,
    a.offsite_conversions_fb_pixel_add_to_cart,
    a.landing_page_views,
    a.video_3_second_plays,

    v.video_thruplay_watched_actions,
    v.action_video_view,

    aa.keepsake_kids,
    p.subcategory
FROM base b
LEFT JOIN actions a
    ON b.ad_id = a.ad_id
    AND b.day = a.day
LEFT JOIN video_metrics v
    ON b.ad_id = v.ad_id
    AND b.day = v.day
LEFT JOIN acronym_adjustment aa
    ON LOWER(SPLIT_PART(COALESCE(b.ad_name_gsheet, b.ad_name), '_', 2)) = LOWER(aa.acronym)
LEFT JOIN product_categories p
    ON LOWER(aa.final_acronym) = LOWER(p.acronym)