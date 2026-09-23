create or replace table bi.mark_dev.preprocess_sessions as



-- TODO add conversion funnel events to the list for the count

--Dedupe SKUs mapping sheet values
with skus_mapping_dedup as (
    select a.slug, max(a.retail_category) as retail_category, max(a.pdc) as pdc, max(b.theme) as retail_sub_category,
    max(to_date(a.brand_launch_date, 'DD/MM/YYYY')) as brand_launch_date, max(b.evergreen_occasion) as trading_category,
    max(b.evergreen_occasion_sub_cat) as evergreen_occasion_sub_cat,
    max(b.keepsake_kids_sub_cat) as keepsake_kids_sub_cat,
    max(b.keepsake_kids) as keepsake_kids

    from bi.google_sheets.skus_mapping a
    left join bi.google_sheets.product_categories b on a.brand = b.brand
    group by slug
),

skus_mapping_dedup_fallback as
(
select distinct 
    case 
        when a.brand = 'name-o-saurus' then 'name-o-sauras'
        when a.brand = 'our-mom-the-superhero' then 'our-mum-the-superhero'
        when a.brand = 'wondrous-road' then 'the-wondrous-road'
        when a.brand = 'my-wonderland' then 'my-alice-in-wonderland'
        when a.brand like 'tboe%' then replace(a.brand, 'tboe', 'the-book-of-everyone')
    else a.brand end as brand,
    a.retail_category, 
    b.theme as retail_sub_category, 
    a.pdc, 
    to_date(a.brand_launch_date, 'DD/MM/YYYY') as brand_launch_date, 
    b.evergreen_occasion as trading_category, 
    b.evergreen_occasion_sub_cat, 
    b.keepsake_kids_sub_cat, 
    b.keepsake_kids
from bi.google_sheets.skus_mapping a
    left join bi.google_sheets.product_categories b on a.brand = b.brand
qualify row_number() over(partition by a.brand order by brand_launch_date, sku) = 1
),

-- get the ga_session_start and session order
sessions_order_and_number AS (
    SELECT  sessions.cookie_id,
            sessions.ga_session_number,
            TO_TIMESTAMP(events.session_start) AS session_start,
            ROW_NUMBER() OVER(PARTITION BY cookie_id ORDER BY session_start ASC ) AS session_order
    FROM bi.DBT_PRODUCTION_GA4.clean_sessions sessions
         LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_events_per_session events USING(session_id)

),
-- want this CTE to contain for each user the number of session we need to offset the session_order by in order to get a (more) accurate
-- session_number. For example if the first ga_session_number is NULL but the second one is 8, then the first one should have been 7 and it
-- should not be counted as a first visit
-- in less than 1% of cases there are multiple sessions with the same ga number leading to negative values, we overwrite them with 0

sessions_offset_table AS (
    SELECT cookie_id,
            CASE
                WHEN MIN(ga_session_number - session_order)>= 0 THEN MIN(ga_session_number - session_order)
                ELSE 0
            END AS session_number_offset
    FROM sessions_order_and_number
    WHERE ga_session_number IS NOT NULL
    GROUP BY cookie_id
),

sessions AS (
    SELECT  sessions.*,
            
            events.num_of_page_view,
            
            TO_TIMESTAMP(events.session_start) AS session_start,
            TO_DATE(events.session_start) AS session_date,
            TIMESTAMPDIFF(SECOND, events.session_start, events.session_end) AS time_on_site,


            -- count the number of sessions a user has in our data (in case of missing data as far as session_start events are concerned)
            -- offset the session_number by th value pre-calculated in sessions_offset_table (or 0)
            ROW_NUMBER() OVER(PARTITION BY cookie_id ORDER BY session_start ASC ) + COALESCE(session_number_offset, 0) AS session_number,

            -- only flag a session as first_session, if the session_number is 1 after the offset
            CASE
                WHEN session_number = 1 THEN true
                ELSE false
            END                                                             AS first_session,

            CASE
                WHEN session_number != 1 THEN true
                ELSE false
            END                                                             AS returning_session,

            -- flag sessions without any page_view events as invalid
            CASE
                WHEN COALESCE(events.num_of_page_view,0) = 0 THEN 0
                WHEN events.num_of_page_view > 0 THEN 1
            END                                                             AS session_validity,

            -- flag sessions with only one page_view event as bounced sessions
            -- we keep them because they still can contain campaign data about how the user found the website
            CASE
                WHEN events.num_of_page_view = 1 THEN sessions.session_id
                ELSE NULL
            END                                                             AS bounced_sessions,

            -- flag a user as a customer if they have placed an order before or during their current session
            CASE
                WHEN customers.first_order_date IS NULL THEN false
                WHEN customers.first_order_date <= TO_TIMESTAMP(events.session_end) THEN true
                ELSE false
            END                                                                 AS is_customer,

            CASE
                WHEN events.is_engaged = 1 THEN 1
                ELSE 0
            END                                                                 AS is_engaged,

            CASE
                WHEN events.seen_offers_page > 0 THEN 1
                ELSE 0
            END                                                                 AS seen_offers_page,

            channels.campaign,
            channels.source,
            channels.medium,
            channels.term,
            channels.content,
            channels.gclick_id,
            channels.ad_group_id,
            channels.criteria_id,

            funnel.funnel_cart,
            funnel.funnel_checkout_details,
            funnel.funnel_checkout_address,
            funnel.funnel_checkout_delivery,
            funnel.funnel_checkout_payment,
            funnel.funnel_checkout_success,

            funnel.login_form_submitted
            ,funnel.create_account_form_submitted
            ,funnel.reset_email_sent
            ,funnel.clicked_create_account
            ,funnel.clicked_forgot_password
            ,funnel.clicked_login
            ,funnel.clicked_logout
            ,funnel.seen_forgot_pass_page
            ,funnel.seen_registration_page
            ,funnel.seen_login_page
            ,funnel.seen_reset_password_page
            ,funnel.seen_reset_email_page
            ,funnel.create_account_success
            ,funnel.login_success
            ,funnel.consent_settings_click
            ,funnel.consent_accept
            ,funnel.consent_reject
            ,funnel.consent_custom_accept

            ,funnel.search_clicked_dropdown
            ,funnel.search_clicked_resultspage
            ,funnel.search_opened_pdp_dropdown
            ,funnel.search_opened_pdp_resultspage
            ,funnel.search_viewed_resultspage
            ,funnel.search_clicked_search_bar,

            funnel.first_product_seen,
            funnel.first_product_page_path_seen,
            funnel.number_of_products_seen,
            funnel.number_of_products_previewed,
            funnel.reached_creation,
            funnel.reached_preview,
            funnel.reached_formats,
            funnel.reached_options,
            funnel.reached_personalisation,
            CASE WHEN funnel.is_engaged  > 0 THEN 1 ELSE 0 END     AS is_click_engaged,

            funnel.funnel_formats_and_gifting,
            funnel.funnel_continue_shopping,
            funnel.funnel_checkoutv3,
            funnel.funnel_add_to_cart

    FROM bi.DBT_PRODUCTION_GA4.clean_events_per_session events
    LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_sessions sessions USING(session_id)
    LEFT JOIN bi.DBT_PRODUCTION_GA4.clean_users customers USING(visitor_id)
    LEFT JOIN sessions_offset_table USING(cookie_id)
    LEFT JOIN bi.DBT_PRODUCTION_GA4.preprocess_channels channels USING(session_id)
    LEFT JOIN bi.mark_dev.preprocess_session_funnel_events funnel USING(session_id)

    WHERE TO_DATE(events.session_start) > '2026-09-11'
)

SELECT  session_id,
        visitor_id,
        cookie_id,
        user_id,
        session_start,
        session_date,
        locale,
        landing_page,
        landing_page_type,
        landing_page_type2,
        landing_page_type3,
        landing_page_step,
        exit_page,
        exit_page_type,
        exit_page_step,
        bounced_sessions,
        first_session,
        returning_session,
        is_customer,
        is_engaged,
        seen_offers_page,
        num_of_page_view,
        

LAST_VALUE(sessions.campaign IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS campaign,
        

LAST_VALUE(sessions.source IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS source,
        

LAST_VALUE(sessions.medium IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS medium,
        

LAST_VALUE(sessions.term IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS term,
        

LAST_VALUE(sessions.content IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS content,
        

LAST_VALUE(sessions.ad_group_id IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS ad_group_id,
        

LAST_VALUE(sessions.criteria_id IGNORE NULLS) OVER (PARTITION BY cookie_id ORDER BY session_start ASC ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

 AS criteria_id,
        gclick_id,
        fbclick_id,
        user_agent,
        time_on_site,
        funnel_cart,
        funnel_checkout_details,
        funnel_checkout_address,
        funnel_checkout_delivery,
        funnel_checkout_payment,
        funnel_checkout_success,

        login_form_submitted
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
        ,consent_custom_accept,

        search_clicked_dropdown
        ,search_clicked_resultspage
        ,search_opened_pdp_dropdown
        ,search_opened_pdp_resultspage
        ,search_viewed_resultspage
        ,search_clicked_search_bar,
        
        first_product_seen,
    --    first_product_page_path_seen,
        number_of_products_seen,
        number_of_products_previewed,
        reached_creation,
        reached_preview,
        reached_formats,
        reached_options,
        reached_personalisation,
        is_click_engaged,

        coalesce(b.retail_category, c.retail_category, d.retail_category, e.retail_category) as retail_category, 
        coalesce(b.retail_sub_category, c.retail_sub_category, d.retail_sub_category, e.retail_sub_category) as retail_sub_category,  
        coalesce(b.pdc, c.pdc, d.pdc, e.pdc) as pdc,
        coalesce(b.brand_launch_date, c.brand_launch_date, d.brand_launch_date, e.brand_launch_date) as brand_launch_date,
        coalesce(b.trading_category, c.trading_category, d.trading_category, e.trading_category) as trading_category,

        coalesce(b.evergreen_occasion_sub_cat, c.evergreen_occasion_sub_cat, d.evergreen_occasion_sub_cat, e.evergreen_occasion_sub_cat) as evergreen_occasion_sub_cat,
        coalesce(b.keepsake_kids_sub_cat, c.keepsake_kids_sub_cat, d.keepsake_kids_sub_cat, e.keepsake_kids_sub_cat) as keepsake_kids_sub_cat,
        coalesce(b.keepsake_kids, c.keepsake_kids, d.keepsake_kids, e.keepsake_kids) as keepsake_kids,


        funnel_formats_and_gifting,
        funnel_continue_shopping,
        funnel_checkoutv3,
        funnel_add_to_cart


FROM sessions


left join skus_mapping_dedup b on b.slug = REGEXP_SUBSTR(sessions.first_product_page_path_seen, '[^/]+', 1, 3)
left join skus_mapping_dedup c on c.slug = REGEXP_SUBSTR(sessions.first_product_page_path_seen, '[^/]+', 1, 2)
left join skus_mapping_dedup d on d.slug = REGEXP_REPLACE(SPLIT_PART(SPLIT_PART(sessions.first_product_page_path_seen, 'product/', 2), '?', 1), '-op[0-9]+$', '') --explicitly for any optimizely test URLs
left join skus_mapping_dedup_fallback e on e.brand = LOWER(REPLACE(REPLACE(REPLACE(sessions.first_product_seen, ' -', ''), ',', ''), ' ', '-'))

WHERE session_validity = 1