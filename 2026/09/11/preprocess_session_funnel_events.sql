 create or replace table bi.mark_dev.preprocess_session_funnel_events as
 
 --pre_hook is used to delete any orphaned session_id's before the body of the transform runs

WITH checkout_funnel AS  (
    -- recreates TRUTH.DIM_SESSION_FUNNEL but with only necessary columns
    SELECT
        session_id,
        (COUNT(CASE WHEN funnel_type = 'cart' THEN 1 END) > 0)::int AS funnel_cart,
        (COUNT(CASE WHEN funnel_type = 'checkout' AND funnel_step = 'details' THEN 1 END) > 0)::int AS funnel_checkout_details,
        (COUNT(CASE WHEN funnel_type = 'checkout' AND funnel_step = 'address' THEN 1 END) > 0)::int AS funnel_checkout_address,
        (COUNT(CASE WHEN funnel_type = 'checkout' AND funnel_step = 'delivery' THEN 1 END) > 0)::int AS funnel_checkout_delivery,
        (COUNT(CASE WHEN funnel_type = 'checkout' AND funnel_step = 'payment' THEN 1 END) > 0)::int AS funnel_checkout_payment,
        (COUNT(CASE WHEN funnel_type = 'order' AND funnel_step = 'success' THEN 1 END) > 0)::int AS funnel_checkout_success,

        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_form_submit_login' THEN 1 END) > 0)::int AS login_form_submitted,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_form_submit_register' THEN 1 END) > 0)::int AS create_account_form_submitted,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_form_submit_email_sent' THEN 1 END) > 0)::int AS reset_email_sent,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_link_click_create_account' THEN 1 END) > 0)::int AS clicked_create_account,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_link_click_forgot_password' THEN 1 END) > 0)::int AS clicked_forgot_password,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_link_click_go_to_login' THEN 1 END) > 0)::int AS clicked_login,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'user_logout_click' THEN 1 END) > 0)::int AS clicked_logout,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_page_view_forgot_password' THEN 1 END) > 0)::int AS seen_forgot_pass_page,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_page_view_create_account' THEN 1 END) > 0)::int AS seen_registration_page,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_page_view_login' THEN 1 END) > 0)::int AS seen_login_page,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_page_view_reset_password' THEN 1 END) > 0)::int AS seen_reset_password_page,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_page_view_email_sent' THEN 1 END) > 0)::int AS seen_reset_email_page,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_create_account_success' THEN 1 END) > 0)::int AS create_account_success,
        (COUNT(CASE WHEN funnel_type = 'auth' AND funnel_step = 'auth_login_success' THEN 1 END) > 0)::int AS login_success,

        (COUNT(CASE WHEN funnel_type = 'search' AND funnel_step = 'srch_rslt_click_dropdown' THEN 1 END) > 0)::int AS search_clicked_dropdown,
        (COUNT(CASE WHEN funnel_type = 'search' AND funnel_step = 'srch_rslt_click_page' THEN 1 END) > 0)::int AS search_clicked_resultspage,
        (COUNT(CASE WHEN funnel_type = 'search' AND funnel_step = 'srch_pdp_resultspage' THEN 1 END) > 0)::int AS search_opened_pdp_dropdown,
        (COUNT(CASE WHEN funnel_type = 'search' AND funnel_step = 'srch_pdp_dropdown' THEN 1 END) > 0)::int AS search_opened_pdp_resultspage,
        (COUNT(CASE WHEN funnel_type = 'search' AND funnel_step = 'srch_rslts_vwd_resultspage' THEN 1 END) > 0)::int AS search_viewed_resultspage,
        (COUNT(CASE WHEN funnel_type = 'search' AND funnel_step = 'srch_clicked_search_bar' THEN 1 END) > 0)::int AS search_clicked_search_bar,

        (COUNT(CASE WHEN funnel_type = 'consent' AND funnel_step = 'consent_settings_click' THEN 1 END) > 0)::int AS consent_settings_click,
        (COUNT(CASE WHEN funnel_type = 'consent' AND funnel_step = 'consent_accept' THEN 1 END) > 0)::int AS consent_accept,
        (COUNT(CASE WHEN funnel_type = 'consent' AND funnel_step = 'consent_reject' THEN 1 END) > 0)::int AS consent_reject,
        (COUNT(CASE WHEN funnel_type = 'consent' AND funnel_step = 'consent_custom_accept' THEN 1 END) > 0)::int AS consent_custom_accept,

        (COUNT(CASE WHEN engagement > 0 THEN 1 END) > 0)::int AS has_minimum_engagement,
        (COUNT(CASE WHEN orders.order_number IS NOT NULL THEN 1 END) > 0)::int AS has_a_purchase_event,

        (COUNT(CASE WHEN funnel_type = 'continue shopping' AND funnel_step = 'continue shopping' THEN 1 END) > 0)::int AS funnel_continue_shopping,
        (COUNT(CASE WHEN funnel_type = 'checkout' AND funnel_step = 'checkoutv3' THEN 1 END) > 0)::int AS funnel_checkoutv3,

        (COUNT(CASE WHEN funnel_type = 'add_to_cart' AND funnel_step = 'add_to_cart' THEN 1 END) > 0)::int AS funnel_add_to_cart

    FROM bi.mark_dev.clean_session_funnel_events
    LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_transactions orders USING(session_id)
    

    -- this filter will only be applied on an incremental run
    WHERE TO_DATE(TO_TIMESTAMP(funnel_timestamp)) >= DATEADD(day, -3, CURRENT_DATE())

    
    GROUP BY 1
),

product_funnel AS (

    WITH creation_events AS (
        SELECT
            session_id,
            product,
            product_page_path,
            ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY funnel_timestamp) AS rn
        FROM bi.DBT_PRODUCTION_GA4.clean_session_funnel_events
        WHERE funnel_type = 'product'
          AND funnel_step = 'creation'
    )

    SELECT
        s.session_id,

        /* First product & product page from creation step */
        ce.product AS first_product,
        ce.product_page_path AS first_product_page_path,

        /* Funnel step flags */
        MAX(CASE WHEN f.funnel_step = 'creation' THEN 1 ELSE 0 END)                AS reached_creation,
        MAX(CASE WHEN f.funnel_step = 'started_personalisation' THEN 1 ELSE 0 END) AS reached_personalisation,
        MAX(CASE WHEN f.funnel_step = 'preview' THEN 1 ELSE 0 END)                 AS reached_preview,
        MAX(CASE WHEN f.funnel_step = 'formats' THEN 1 ELSE 0 END)                 AS reached_formats,
        MAX(CASE WHEN f.funnel_step = 'options' THEN 1 ELSE 0 END)                 AS reached_options,
        MAX(CASE WHEN f.funnel_step = 'formats and gifting' THEN 1 ELSE 0 END)     AS funnel_formats_and_gifting

    FROM bi.DBT_PRODUCTION_GA4.clean_events_per_session s
    LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_session_funnel_events f
        ON s.session_id = f.session_id
    LEFT JOIN creation_events ce
        ON s.session_id = ce.session_id
       AND ce.rn = 1  -- pick only the first product per session

    

        -- this filter will only be applied on an incremental run
    AND TO_DATE(TO_TIMESTAMP(session_start)) >= DATEADD(day, -3, CURRENT_DATE())

    

    GROUP BY s.session_id, ce.product, ce.product_page_path
),

-- aggregates the data in product_funnel and uses logic as in FACT_SESSIONS to get number of products seen and previewed
aggregate_product_funnel AS (
    SELECT
        session_id,

        COUNT(DISTINCT CASE
            WHEN funnel_type = 'product'
             AND funnel_step = 'creation'
             AND interaction_type = 'page view'
            THEN product END) AS number_of_products_seen,

        COUNT(DISTINCT CASE
            WHEN funnel_type = 'product'
             AND funnel_step = 'preview'
             AND interaction_type = 'page view'
            THEN product END) AS number_of_products_previewed,

        SUM(CASE WHEN interaction_type != 'page view' THEN engagement ELSE 0 END) AS is_engaged

    FROM bi.DBT_PRODUCTION_GA4.clean_session_funnel_events



-- this filter will only be applied on an incremental run
WHERE TO_DATE(TO_TIMESTAMP(funnel_timestamp)) >= DATEADD(day, -3, CURRENT_DATE())



GROUP BY session_id

)

SELECT
    s.session_id,

    cf.funnel_cart,
cf.funnel_checkout_details,
cf.funnel_checkout_address,
cf.funnel_checkout_delivery,
cf.funnel_checkout_payment,
CASE
    WHEN cf.funnel_checkout_success + cf.has_a_purchase_event > 0 THEN 1
    ELSE 0
END AS funnel_checkout_success,
cf.login_form_submitted,
cf.create_account_form_submitted,
cf.reset_email_sent,
cf.clicked_create_account,
cf.clicked_forgot_password,
cf.clicked_login,
cf.clicked_logout,
cf.seen_forgot_pass_page,
cf.seen_registration_page,
cf.seen_login_page,
cf.seen_reset_password_page,
cf.seen_reset_email_page,
cf.create_account_success,
cf.login_success,
cf.search_clicked_dropdown,
cf.search_clicked_resultspage,
cf.search_opened_pdp_dropdown,
cf.search_opened_pdp_resultspage,
cf.search_viewed_resultspage,
cf.search_clicked_search_bar,
cf.consent_settings_click,
cf.consent_accept,
cf.consent_reject,
cf.consent_custom_accept,
cf.has_minimum_engagement,
cf.has_a_purchase_event,
cf.funnel_continue_shopping,
cf.funnel_checkoutv3,


    pf.first_product                AS first_product_seen,
    pf.first_product_page_path      AS first_product_page_path_seen,

    apf.number_of_products_seen,
    apf.number_of_products_previewed,

    pf.reached_creation,
    pf.reached_preview,
    pf.reached_formats,
    pf.reached_options,
    pf.reached_personalisation,
    apf.is_engaged,
    pf.funnel_formats_and_gifting,

    cf.funnel_add_to_cart

FROM bi.DBT_PRODUCTION_GA4.clean_events_per_session s
LEFT JOIN checkout_funnel cf USING (session_id)
LEFT JOIN product_funnel pf USING (session_id)
LEFT JOIN aggregate_product_funnel apf USING (session_id)




-- this filter will only be applied on an incremental run
WHERE TO_DATE(TO_TIMESTAMP(session_start)) >= DATEADD(day, -3, CURRENT_DATE())

