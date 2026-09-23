--int_conversion_funnel_11082026

create or replace table bi.mark_dev.int_conversion_funnel as

WITH
-- CTE to determine what the interaction chain opens on
opening_chain_interaction AS (
         SELECT DISTINCT interactions.chain_key,
                         interactions.interaction_type,
                         interactions.ad_key
         FROM bi.dbt_production_models.fct_interactions_refactored interactions
         WHERE interactions.position_in_chain = 1
),

-- CTE to give context about the chain this session belongs to
chain_context AS (
         SELECT DISTINCT
                         opening.ad_key                                      AS opening_ad_key,
                         interaction_chains.chain_index,
                         interaction_chains.start_of_chain_timestamp,
                         interaction_chains.end_of_chain_timestamp,
                         fact_interactions.visitor_id,
                         fact_interactions.interaction_id,
                         fact_interactions.chain_key,
                         fact_interactions.position_in_chain,
                         fact_interactions.customer_type,
                         fact_interactions.interaction_type,
-- TODO what does this do?? Can't we do CURRENT_TIMESTAMP() instead of select max
                         DATEDIFF('minutes',
                                  interaction_chains.start_of_chain_timestamp,
                                  (SELECT MAX(fact_interactions.end_of_chain_timestamp)
                                   FROM bi.dbt_production_models.fct_interactions_refactored fact_interactions))   AS minutes_since_start_of_chain,

                         DATEDIFF('minutes',
                                  interaction_chains.start_of_chain_timestamp,
                                  interaction_chains.end_of_chain_timestamp) AS chain_duration_mins,
-- TODO if the following two are actually needed do them in table below, no need for the same datediff function applied each time
                         ROUND(DATEDIFF('minutes',
                                        interaction_chains.start_of_chain_timestamp,
                                        interaction_chains.end_of_chain_timestamp)::numeric / 60,
                               0)                                                      AS chain_duration_hours,
                         ROUND(DATEDIFF('minutes',
                                        interaction_chains.start_of_chain_timestamp,
                                        interaction_chains.end_of_chain_timestamp)::numeric / (60 * 24),
                               0)                                                      AS chain_duration_days,
-- TODO discrete value
                         fact_interactions.is_chain_converting :: INT            AS is_chain_converting,
                         CASE
                             WHEN fact_interactions.is_chain_converting :: INT = 1 AND
                                  interaction_chains.start_of_chain_timestamp :: DATE =
                                  interaction_chains.end_of_chain_timestamp :: DATE
                                 THEN 1
                             END :: INT                                                AS is_converting_immediately,
                        interaction_chains.ad_key

         FROM bi.dbt_production_models.fct_interactions_refactored fact_interactions
                  LEFT JOIN bi.dbt_production_intermediate.int_interaction_chains interaction_chains
                            ON fact_interactions.chain_key = interaction_chains.chain_key
                  LEFT JOIN opening_chain_interaction opening
                            ON fact_interactions.chain_key = opening.chain_key
         WHERE fact_interactions.interaction_id IS NOT NULL
           AND fact_interactions.visitor_id != '-1'
)

SELECT  session_id || '#' || COALESCE(ga_orders.order_number, '-') AS table_key,
        sessions.session_id,
        sessions.visitor_id,
        sessions.cookie_id,
        sessions.user_id,
        sessions.visit_starttime,
        sessions.session_date,
        sessions.landing_page,
        sessions.landing_page_type,
        sessions.landing_page_type2,
        sessions.landing_page_type3,
        sessions.landing_page_step,
        sessions.exit_page,
        sessions.exit_page_type,
        sessions.exit_page_step,
        sessions.bounced_sessions,
        sessions.first_session,
        sessions.returning_session,
        sessions.is_customer,
        sessions.is_engaged,
        sessions.locale,
        sessions.seen_offers_page,
        sessions.number_pages_seen,
        sessions.time_on_site,
        sessions.country,
        sessions.city,
        sessions.device,
        sessions.browser,
        sessions.operating_system,
        sessions.mobile_device_model,
        sessions.device_language,
        sessions.funnel_cart,
        sessions.funnel_checkout_details,
        sessions.funnel_checkout_address,
        sessions.funnel_checkout_delivery,
        sessions.funnel_checkout_payment,
        sessions.funnel_checkout_success,

        sessions.login_form_submitted
        ,sessions.create_account_form_submitted
        ,sessions.reset_email_sent
        ,sessions.clicked_create_account
        ,sessions.clicked_forgot_password
        ,sessions.clicked_login
        ,sessions.clicked_logout
        ,sessions.seen_forgot_pass_page
        ,sessions.seen_registration_page
        ,sessions.seen_login_page
        ,sessions.seen_reset_password_page
        ,sessions.seen_reset_email_page
        ,sessions.create_account_success
        ,sessions.login_success
        ,sessions.consent_settings_click
        ,sessions.consent_accept
        ,sessions.consent_reject
        ,sessions.consent_custom_accept,

        sessions.search_clicked_dropdown,
        sessions.search_clicked_resultspage,
        sessions.search_opened_pdp_dropdown,
        sessions.search_opened_pdp_resultspage,
        sessions.search_viewed_resultspage,
        sessions.search_clicked_search_bar,

        sessions.first_product_seen,
        sessions.retail_category,  
        sessions.pdc,
        sessions.retail_sub_category,
        sessions.trading_category,
        sessions.evergreen_occasion_sub_cat,
        sessions.keepsake_kids_sub_cat,
        sessions.keepsake_kids,
        sessions.brand_launch_date,
        sessions.number_of_products_seen,
        sessions.number_of_products_previewed,
        sessions.reached_creation,
        sessions.reached_preview,
        sessions.reached_formats,
        sessions.reached_options,
        sessions.reached_personalisation,
        sessions.is_click_engaged,


        CASE
            WHEN dw_orders.is_completed = TRUE THEN dw_orders.order_number
            ELSE NULL
        END                                     AS order_number,

        CASE
            WHEN dw_orders.is_completed = TRUE THEN dw_orders.basket_size
            ELSE NULL
        END                                     AS basket_size,

        CASE
            WHEN dw_orders.is_completed = TRUE THEN dw_orders.net_revenue
            ELSE NULL
        END                                     AS net_revenue,

        CASE
            WHEN dw_orders.is_completed = TRUE THEN dw_orders.no_of_units
            ELSE NULL
        END                                     AS no_of_units,

        chain_context.chain_key,
        chain_context.chain_index,
        chain_context.start_of_chain_timestamp,
        chain_context.end_of_chain_timestamp,
        chain_context.position_in_chain,
        chain_context.customer_type,
        chain_context.minutes_since_start_of_chain,
        chain_context.chain_duration_mins,
        chain_context.chain_duration_hours,
        chain_context.chain_duration_days,
        chain_context.is_chain_converting,
        chain_context.is_converting_immediately,

        ads.channel                             AS ad_channel,
        ads.channel_groups                      AS ad_channel_groups,
        ads.channel_paid_or_unpaid              AS ad_channel_paid_or_unpaid,
        ads.account_name                        AS ad_account_name,
        ads.campaign_name                       AS ad_campaign_name,
        ads.email_type,
        ads.ad_group_name,
        ads.ad_name,
        ads.partner as ad_partner,

        opening_ad.channel                      AS opening_ad_channel,
        opening_ad.campaign_name                AS opening_campaign_name,
        1 AS sessions,

        dw_orders.gross_profit                  AS gross_profit,

        sessions.funnel_formats_and_gifting,
        sessions.funnel_continue_shopping,
        sessions.funnel_checkoutv3,
        
        sessions.content


FROM bi.DBT_PRODUCTION_GA4.transform_session_details sessions
LEFT JOIN bi.DBT_PRODUCTION_GA4.preprocess_transactions ga_orders USING(session_id)
LEFT JOIN bi.dbt_production_models.fct_orders dw_orders
    ON dw_orders.order_number = ga_orders.order_number
LEFT JOIN chain_context
    ON sessions.session_id = chain_context.interaction_id
LEFT JOIN bi.dbt_production_intermediate.int_interactions interactions
    ON interactions.interaction_id = sessions.session_id
LEFT JOIN bi.dbt_production_intermediate.int_attribution_ads as ads
    ON interactions.ad_key = ads.ad_key
LEFT JOIN bi.dbt_production_intermediate.int_attribution_ads as opening_ad
    ON chain_context.opening_ad_key = opening_ad.ad_key
QUALIFY ROW_NUMBER() OVER (PARTITION BY table_key ORDER BY chain_context.customer_type ASC) = 1