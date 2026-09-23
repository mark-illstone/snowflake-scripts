
select 
    sessions.session_id,
    
    -- COALESCE(orig_events.visitor_id, sessions.visitor_id) AS visitor_id,
    -- COALESCE(orig_events.cookie_id, sessions.cookie_id) AS cookie_id,
    -- COALESCE(orig_events.user_id, sessions.user_id) AS user_id,
    -- COALESCE(orig_events.session_start, sessions.session_start) AS visit_starttime,
    -- COALESCE(orig_events.session_date, sessions.session_date) AS session_date,
    -- COALESCE(orig_events.locale, sessions.locale) AS locale,

    -- sessions.exit_page,
    -- sessions.exit_page_type,
    -- sessions.exit_page_step,

    -- -- likely 0/1
    -- sessions.bounced_sessions,
    -- (orig_events.first_session = TRUE OR sessions.first_session = TRUE) AS first_session, 
    -- (orig_events.returning_session = TRUE OR sessions.returning_session = TRUE) AS returning_session,
    -- (orig_events.is_customer = TRUE OR sessions.is_customer = TRUE) AS is_customer,
    -- GREATEST(COALESCE(orig_events.is_engaged, 0), COALESCE(sessions.is_engaged, 0)) AS is_engaged,
    -- GREATEST(COALESCE(orig_events.seen_offers_page, 0), COALESCE(sessions.seen_offers_page, 0)) AS seen_offers_page,

    -- -- NOT boolean
    -- COALESCE(orig_events.num_of_page_view, sessions.num_of_page_view) AS number_pages_seen,
    -- COALESCE(orig_events.user_agent, sessions.user_agent) AS user_agent,
    -- COALESCE(orig_events.time_on_site, sessions.time_on_site) AS time_on_site,

    -- -- funnel flags (0/1)
    -- GREATEST(COALESCE(orig_events.funnel_cart, 0), COALESCE(sessions.funnel_cart, 0)) AS funnel_cart,
    -- GREATEST(COALESCE(orig_events.funnel_checkout_details, 0), COALESCE(sessions.funnel_checkout_details, 0)) AS funnel_checkout_details,
    -- GREATEST(COALESCE(orig_events.funnel_checkout_address, 0), COALESCE(sessions.funnel_checkout_address, 0)) AS funnel_checkout_address,
    -- GREATEST(COALESCE(orig_events.funnel_checkout_delivery, 0), COALESCE(sessions.funnel_checkout_delivery, 0)) AS funnel_checkout_delivery,
    -- GREATEST(COALESCE(orig_events.funnel_checkout_payment, 0), COALESCE(sessions.funnel_checkout_payment, 0)) AS funnel_checkout_payment,
    -- GREATEST(COALESCE(orig_events.funnel_checkout_success, 0), COALESCE(sessions.funnel_checkout_success, 0)) AS funnel_checkout_success,

    -- -- dimensions
    -- COALESCE(orig_events.landing_page, sessions.landing_page) AS landing_page,
    -- COALESCE(orig_events.landing_page_type, sessions.landing_page_type) AS landing_page_type,
    -- COALESCE(orig_events.landing_page_type2, sessions.landing_page_type2) AS landing_page_type2,
    -- COALESCE(orig_events.landing_page_type3, sessions.landing_page_type3) AS landing_page_type3,
    -- COALESCE(orig_events.landing_page_step, sessions.landing_page_step) AS landing_page_step,
    -- COALESCE(orig_events.campaign, sessions.campaign) AS campaign,
    -- COALESCE(orig_events.medium, sessions.medium) AS medium,
    -- COALESCE(orig_events.source, sessions.source) AS source,
    -- COALESCE(orig_events.term, sessions.term) AS term,
    -- COALESCE(orig_events.content, sessions.content) AS content,
    -- COALESCE(orig_events.ad_group_id, sessions.ad_group_id) AS ad_group_id,
    -- COALESCE(orig_events.criteria_id, sessions.criteria_id) AS criteria_id,
    -- COALESCE(orig_events.gclick_id, sessions.gclick_id) AS gclick_id,
    -- COALESCE(orig_events.fbclick_id, sessions.fbclick_id) AS fbclick_id,

    -- -- auth / consent interactions (very likely boolean)
    -- GREATEST(COALESCE(orig_events.login_form_submitted, 0), COALESCE(sessions.login_form_submitted, 0)) AS login_form_submitted,
    -- GREATEST(COALESCE(orig_events.create_account_form_submitted, 0), COALESCE(sessions.create_account_form_submitted, 0)) AS create_account_form_submitted,
    -- GREATEST(COALESCE(orig_events.reset_email_sent, 0), COALESCE(sessions.reset_email_sent, 0)) AS reset_email_sent,
    -- GREATEST(COALESCE(orig_events.clicked_create_account, 0), COALESCE(sessions.clicked_create_account, 0)) AS clicked_create_account,
    -- GREATEST(COALESCE(orig_events.clicked_forgot_password, 0), COALESCE(sessions.clicked_forgot_password, 0)) AS clicked_forgot_password,
    -- GREATEST(COALESCE(orig_events.clicked_login, 0), COALESCE(sessions.clicked_login, 0)) AS clicked_login,
    -- GREATEST(COALESCE(orig_events.clicked_logout, 0), COALESCE(sessions.clicked_logout, 0)) AS clicked_logout,
    -- GREATEST(COALESCE(orig_events.seen_forgot_pass_page, 0), COALESCE(sessions.seen_forgot_pass_page, 0)) AS seen_forgot_pass_page,
    -- GREATEST(COALESCE(orig_events.seen_registration_page, 0), COALESCE(sessions.seen_registration_page, 0)) AS seen_registration_page,
    -- GREATEST(COALESCE(orig_events.seen_login_page, 0), COALESCE(sessions.seen_login_page, 0)) AS seen_login_page,
    -- GREATEST(COALESCE(orig_events.seen_reset_password_page, 0), COALESCE(sessions.seen_reset_password_page, 0)) AS seen_reset_password_page,
    -- GREATEST(COALESCE(orig_events.seen_reset_email_page, 0), COALESCE(sessions.seen_reset_email_page, 0)) AS seen_reset_email_page,
    -- GREATEST(COALESCE(orig_events.create_account_success, 0), COALESCE(sessions.create_account_success, 0)) AS create_account_success,
    -- GREATEST(COALESCE(orig_events.login_success, 0), COALESCE(sessions.login_success, 0)) AS login_success,

    -- -- consent flags
    -- GREATEST(COALESCE(orig_events.consent_settings_click, 0), COALESCE(sessions.consent_settings_click, 0)) AS consent_settings_click,
    -- GREATEST(COALESCE(orig_events.consent_accept, 0), COALESCE(sessions.consent_accept, 0)) AS consent_accept,
    -- GREATEST(COALESCE(orig_events.consent_reject, 0), COALESCE(sessions.consent_reject, 0)) AS consent_reject,
    -- GREATEST(COALESCE(orig_events.consent_custom_accept, 0), COALESCE(sessions.consent_custom_accept, 0)) AS consent_custom_accept,

    -- -- search interactions (likely boolean)
    -- GREATEST(COALESCE(orig_events.search_clicked_dropdown, 0), COALESCE(sessions.search_clicked_dropdown, 0)) AS search_clicked_dropdown,
    -- GREATEST(COALESCE(orig_events.search_clicked_resultspage, 0), COALESCE(sessions.search_clicked_resultspage, 0)) AS search_clicked_resultspage,
    -- GREATEST(COALESCE(orig_events.search_opened_pdp_dropdown, 0), COALESCE(sessions.search_opened_pdp_dropdown, 0)) AS search_opened_pdp_dropdown,
    -- GREATEST(COALESCE(orig_events.search_opened_pdp_resultspage, 0), COALESCE(sessions.search_opened_pdp_resultspage, 0)) AS search_opened_pdp_resultspage,
    -- GREATEST(COALESCE(orig_events.search_viewed_resultspage, 0), COALESCE(sessions.search_viewed_resultspage, 0)) AS search_viewed_resultspage,
    -- GREATEST(COALESCE(orig_events.search_clicked_search_bar, 0), COALESCE(sessions.search_clicked_search_bar, 0)) AS search_clicked_search_bar,

    -- -- product funnel
     COALESCE(orig_events.first_product_seen, sessions.first_product_seen) AS first_product_seen,
    -- COALESCE(orig_events.retail_category, sessions.retail_category) AS retail_category,
    -- COALESCE(orig_events.pdc, sessions.pdc) AS pdc,
    -- COALESCE(orig_events.retail_sub_category, sessions.retail_sub_category) AS retail_sub_category,
    -- COALESCE(orig_events.brand_launch_date, sessions.brand_launch_date) AS brand_launch_date,
    -- COALESCE(orig_events.trading_category, sessions.trading_category) AS trading_category,
    -- coalesce(orig_events.evergreen_occasion_sub_cat, sessions.evergreen_occasion_sub_cat) as evergreen_occasion_sub_cat,
    -- coalesce(orig_events.keepsake_kids_sub_cat, sessions.keepsake_kids_sub_cat) as keepsake_kids_sub_cat,
    -- coalesce(orig_events.keepsake_kids, sessions.keepsake_kids) as keepsake_kids,

    -- -- NOT boolean (counts)
    -- COALESCE(orig_events.number_of_products_seen, sessions.number_of_products_seen) AS number_of_products_seen,
    -- COALESCE(orig_events.number_of_products_previewed, sessions.number_of_products_previewed) AS number_of_products_previewed,

    -- -- funnel progression (0/1)
    -- GREATEST(COALESCE(orig_events.reached_creation, 0), COALESCE(sessions.reached_creation, 0)) AS reached_creation,
    -- GREATEST(COALESCE(orig_events.reached_preview, 0), COALESCE(sessions.reached_preview, 0)) AS reached_preview,
    -- GREATEST(COALESCE(orig_events.reached_formats, 0), COALESCE(sessions.reached_formats, 0)) AS reached_formats,
    -- GREATEST(COALESCE(orig_events.reached_options, 0), COALESCE(sessions.reached_options, 0)) AS reached_options,
    -- GREATEST(COALESCE(orig_events.reached_personalisation, 0), COALESCE(sessions.reached_personalisation, 0)) AS reached_personalisation,

    -- -- engagement flag (likely boolean)
    -- GREATEST(COALESCE(orig_events.is_click_engaged, 0), COALESCE(sessions.is_click_engaged, 0)) AS is_click_engaged,

    -- geo.country,
    -- geo.city,
    -- geo.device,
    -- geo.browser,
    -- geo.operating_system,
    -- geo.mobile_device_model,
    -- geo.device_language,
    -- geo.country_fk,

    -- -- final funnel flags
    -- GREATEST(COALESCE(orig_events.funnel_formats_and_gifting, 0), COALESCE(sessions.funnel_formats_and_gifting, 0)) AS funnel_formats_and_gifting,
    -- GREATEST(COALESCE(orig_events.funnel_continue_shopping, 0), COALESCE(sessions.funnel_continue_shopping, 0)) AS funnel_continue_shopping,
    -- GREATEST(COALESCE(orig_events.funnel_checkoutv3, 0), COALESCE(sessions.funnel_checkoutv3, 0)) AS funnel_checkoutv3

    orig_events.first_product_seen, 
    sessions.first_product_seen
    
FROM bi.DBT_PRODUCTION_GA4.preprocess_sessions sessions
LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_geo_and_device geo USING(session_id)

LEFT JOIN bi.dbt_production_intermediate.int_stiched_facebook_sessions s1
  ON sessions.session_id = s1.affected_session_id
LEFT JOIN bi.DBT_PRODUCTION_GA4.preprocess_sessions orig_events
  ON s1.original_session_id = orig_events.session_id

-- Exclude rows where events.session_id is the original_session_id
WHERE sessions.session_id NOT IN (
    SELECT original_session_id
    FROM bi.dbt_production_intermediate.int_stiched_facebook_sessions)

and sessions.session_id = '1488089077.17557338571755733856';