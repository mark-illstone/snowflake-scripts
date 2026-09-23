--fct_conversion_funnel_refactored_11082026

create or replace table bi.mark_dev.fct_conversion_funnel_refactored as

WITH conversion_funnel_refactored_historical  AS (SELECT * FROM BI.posttruth.conversion_funnel_refactored_historical)
   , conversion_funnel AS (SELECT * FROM bi.mark_dev.int_conversion_funnel)


SELECT session_id
     , visitor_id
     , timestamp
     , date
     , bounced_sessions  
     , order_number
     , basket_size
     , net_revenue
     , seen_offers_page
     --, NULL AS seen_blog_pages
     --, NULL AS seen_helpcentre_page
     , first_session
     --, NULL AS new_session
     , returning_session
     , is_customer
     --, NULL AS is_valid_session 
     , ad_channel
     , ad_channel_groups
     , ad_channel_paid_or_unpaid
     , ad_account_name
     , ad_campaign_name
     , ad_group_name
     , ad_name
     , null as ad_partner
     , opening_ad_channel
     , opening_campaign_name
     , country
     , device
     , locale
     , landing_page
     --, NULL AS landing_page_with_locale
     , landing_page_type
     , landing_page_step
     , landing_page_type2
     , landing_page_type3
     , exit_page
     , exit_page_type
     , exit_page_step
     , browser
     --, NULL AS browser_size
     --, NULL AS browser_version
     , operating_system
     --, NULL AS operating_system_version
     --, NULL AS mobile_device_info
     , mobile_device_model
     --, NULL AS mobile_input_sector
     --, NULL AS mobile_device_marketing_name
     --, NULL AS  mobile_device_branding
     --, NULL AS hostname
     , time_on_site
     --, NULL AS region
     --, NULL AS metro
     , city
     --, NULL AS language
     --, NULL AS screen_resolution
     , cookie_id
     --, NULL AS network_domain
     --, NULL AS network_location
     --, NULL AS referral_path
     , sessions
     , first_product_seen
     , reached_creation
     , reached_preview
     , null as reached_formats
     , null as reached_options
     , reached_personalisation
     --, NULL AS selected_number_of_adults_1
     --, NULL AS selected_number_of_adults_2
     --, NULL AS selected_number_of_adults_3
     --, NULL AS selected_number_of_children_1
     --, NULL AS selected_number_of_children_2
     --, NULL AS selected_number_of_children_3
     , funnel_cart
     , funnel_checkout_details
     , funnel_checkout_address
     , funnel_checkout_delivery
     , funnel_checkout_payment
     , funnel_checkout_success
     --, NULL AS engaged_status
     , is_engaged
     , is_click_engaged
     , number_products_seen as number_of_products_seen
     , number_products_previewed as number_of_products_previewed
     , chain_key
     --, NULL AS opening_interaction_type
     , chain_index
     , start_of_chain_timestamp
     , end_of_chain_timestamp
     , position_in_chain
     , customer_type
     , minutes_since_start_of_chain
     , chain_duration_mins
     , chain_duration_hours
     , chain_duration_days
     , is_chain_converting
     , is_converting_immediately
     , number_pages_seen
     --, seen_offers
     --, seen_blog
     --, seen_helpcentre 

    ,NULL AS login_form_submitted
    ,NULL AS create_account_form_submitted
    ,NULL AS reset_email_sent
    ,NULL AS clicked_create_account
    ,NULL AS clicked_forgot_password
    ,NULL AS clicked_login
    ,NULL AS clicked_logout
    ,NULL AS seen_forgot_pass_page
    ,NULL AS seen_registration_page
    ,NULL AS seen_login_page
    ,NULL AS seen_reset_password_page
    ,NULL AS seen_reset_email_page
    ,NULL AS create_account_success
    ,NULL AS login_success
    ,NULL AS consent_settings_click
    ,NULL AS consent_accept
    ,NULL AS consent_reject
    ,NULL AS consent_custom_accept 
    ,NULL AS search_clicked_dropdown
    ,NULL AS search_clicked_resultspage
    ,NULL AS search_opened_pdp_dropdown
    ,NULL AS search_opened_pdp_resultspage
    ,NULL AS search_viewed_resultspage
    ,NULL AS search_clicked_search_bar
    ,NULL AS retail_category 
    ,NULL AS pdc
    ,NULL AS retail_sub_category
    ,NULL AS trading_category
    ,NULL AS brand_launch_date
    ,NULL AS gross_profit

    ,NULL AS funnel_formats_and_gifting
    ,NULL AS funnel_continue_shopping
    ,NULL AS funnel_checkoutv3
    ,NULL AS email_type
    ,NULL AS content
    ,NULL as evergreen_occasion_sub_cat
    ,NULL as keepsake_kids_sub_cat
    ,NULL as keepsake_kids
    ,NULL as no_of_units
  FROM conversion_funnel_refactored_historical 
  WHERE date::DATE < '2023-04-02' 

UNION ALL

SELECT session_id
     , visitor_id
     , visit_starttime AS timestamp
     , session_date AS date
     , bounced_sessions  
     , order_number
     , basket_size
     , net_revenue
     , seen_offers_page
     --, NULL AS seen_blog_pages
     --, NULL AS seen_helpcentre_page
     , first_session
     --, NULL AS new_session
     , returning_session
     , is_customer
     --, NULL AS is_valid_session, 
     , ad_channel
     , ad_channel_groups
     , ad_channel_paid_or_unpaid
     , ad_account_name
     , ad_campaign_name
     , ad_group_name
     , ad_name
     , ad_partner
     , opening_ad_channel
     , opening_campaign_name
     , country
     , device
     , locale
     , landing_page
     --, NULL AS landing_page_with_locale
     , landing_page_type
     , landing_page_step
     , landing_page_type2
     , landing_page_type3
     , exit_page
     , exit_page_type
     , exit_page_step
     , browser
     --, NULL AS browser_size
     --, NULL AS browser_version
     , operating_system
     --, NULL AS operating_system_version
     --, NULL AS mobile_device_info
     , mobile_device_model
     --, NULL AS mobile_input_sector
     --, NULL AS mobile_device_marketing_name
     --, NULL AS  mobile_device_branding
     --, NULL AS hostname
     , time_on_site
     --, NULL AS region
     --, NULL AS metro
     , city
     --, NULL AS language
     --, NULL AS screen_resolution
     , cookie_id
     --, NULL AS network_domain
     --, NULL AS network_location
     --, NULL AS referral_path
     , sessions
     , first_product_seen
     , reached_creation
     , reached_preview
     , reached_formats
     , reached_options
     , reached_personalisation
     --, NULL AS selected_number_of_adults_1
     --, NULL AS selected_number_of_adults_2
     --, NULL AS selected_number_of_adults_3
     --, NULL AS selected_number_of_children_1
     --, NULL AS selected_number_of_children_2
     --, NULL AS selected_number_of_children_3
     , funnel_cart
     , funnel_checkout_details
     , funnel_checkout_address
     , funnel_checkout_delivery
     , funnel_checkout_payment
     , funnel_checkout_success
     --, NULL AS engaged_status
     , is_engaged
     , is_click_engaged
     , number_of_products_seen
     , number_of_products_previewed
     , chain_key
     --, NULL AS opening_interaction_type
     , chain_index
     , start_of_chain_timestamp
     , end_of_chain_timestamp
     , position_in_chain
     , customer_type
     , minutes_since_start_of_chain
     , chain_duration_mins
     , chain_duration_hours
     , chain_duration_days
     , is_chain_converting
     , is_converting_immediately
     , number_pages_seen
     --, NULL AS seen_offers
     --, NULL AS seen_blog
     --, NULL AS seen_helpcentre 

    ,login_form_submitted
    ,create_account_form_submitted
    ,reset_email_sent
    ,clicked_create_account
    ,clicked_forgot_password
    ,clicked_login
    ,clicked_logout
    ,seen_forgot_pass_page
    ,seen_registration_page
    ,seen_login_page
    ,seen_reset_password_page
    ,seen_reset_email_page
    ,create_account_success
    ,login_success
    ,consent_settings_click
    ,consent_accept
    ,consent_reject
    ,consent_custom_accept

    ,search_clicked_dropdown
    ,search_clicked_resultspage
    ,search_opened_pdp_dropdown
    ,search_opened_pdp_resultspage
    ,search_viewed_resultspage
    ,search_clicked_search_bar
    ,retail_category
    ,pdc
    ,retail_sub_category
    ,trading_category
    ,brand_launch_date
    ,gross_profit

    ,funnel_formats_and_gifting
    ,funnel_continue_shopping
    ,funnel_checkoutv3
    ,email_type
    ,content
    ,evergreen_occasion_sub_cat
    ,keepsake_kids_sub_cat
    ,keepsake_kids
    ,no_of_units
  FROM conversion_funnel 
 WHERE session_date >= '2023-04-02'