create or replace table bi.mark_dev.int_attributed_interactions as

WITH interaction_chains AS (SELECT * FROM bi.mark_dev.int_interaction_chains)
   , ads AS (SELECT * FROM bi.dbt_production_intermediate.int_attribution_ads )
   , attributable_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_attributable_orders)
   , funnel_data as (select * from bi.DBT_PRODUCTION_GA4.preprocess_session_funnel_events)

, valid_interactions AS (
    SELECT chain_key
         , interaction_id
         , order_number
         , next_conversion_number
         , next_conversion_timestamp
         , ic.ad_key
         , visitor_id
         , customer_type
         , country_fk
         , gclick_id
         , fbclick_id
         , day
         , interaction_timestamp
         , start_of_chain_timestamp
         , end_of_chain_timestamp
         , is_chain_converting
         , is_chain_repeat
         , chain_index
         , position_in_chain
         , number_of_days
         , number_of_days_before_conversion
         , interaction_type
         , user_agent
         
         , COALESCE(ic.chain_length > 1
                AND (a.channel IN ('PPC Brand','Direct','Unknown') OR (a.channel = 'Other' AND partner = 'payment provider'))
                AND ic.chain_length = ic.position_in_chain
                , false)
                OR
                number_of_days_before_conversion > 28 as initial_ignore_interaction
                

    -- 1) IF THERE ARE NO VALID INTERACTIONS  2) CHANGE THE VERY LAST INTERACTION TO TRUE  3) OTHERWISE KEEP THE ORIGINAL FLAG

         , CASE WHEN COUNT(CASE WHEN NOT initial_ignore_interaction THEN 1 END) OVER (PARTITION BY chain_key) = 0 -- 1) IF THERE ARE NO VALID INTERACTIONS
                AND ic.position_in_chain = ic.chain_length = 1 THEN FALSE -- 2) CHANGE THE VERY LAST INTERACTION TO FALSE
                ELSE initial_ignore_interaction -- 3) OTHERWISE KEEP THE ORIGINAL FLAG

                END AS ignore_interaction


      FROM interaction_chains ic
      LEFT JOIN ads a 
       ON a.ad_key = ic.ad_key
)

, interaction_chain_rules_28d as (
    -- Recalculate chain lengths and positions
    SELECT chain_key
         , interaction_id
         , order_number
         , next_conversion_number
         , next_conversion_timestamp
         , ad_key
         , visitor_id
         , customer_type
         , country_fk
         , gclick_id
         , fbclick_id
         , day
         , interaction_timestamp
         , start_of_chain_timestamp
         , end_of_chain_timestamp
         , is_chain_converting
         , is_chain_repeat
         , chain_index
         , number_of_days, number_of_days_before_conversion, interaction_type, user_agent
         , COUNT(*) OVER (PARTITION BY chain_key) as chain_length
         , ROW_NUMBER() OVER (PARTITION BY chain_key ORDER BY interaction_timestamp ASC) as position_in_chain
    FROM valid_interactions
    WHERE NOT ignore_interaction
)

SELECT ic.ad_key
     , ic.interaction_id
     , ic.day AS interaction_day
     , ic.interaction_timestamp
     , ic.customer_type
     , ic.next_conversion_number
     , ic.country_fk
     , ic.visitor_id
     , ic.gclick_id
     , ic.fbclick_id
     , 'last_click_28d_interactions' AS attribution_model
     , CASE WHEN position_in_chain = chain_length THEN 1 ELSE 0 END AS weighting
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE 1 * weighting END AS conversions
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.net_revenue*weighting END AS net_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.core_revenue*weighting END AS core_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.experimental_revenue*weighting END AS experimental_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.gross_profit*weighting END AS gross_profit

     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.picture_book_revenue*weighting END AS picture_book_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.older_kids_revenue*weighting END AS older_kids_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.hybrid_family_revenue*weighting END AS hybrid_family_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.early_years_revenue*weighting END AS early_years_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.adult_gift_revenue*weighting END AS adult_gift_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.addon_gift_book_revenue*weighting END AS addon_gift_book_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.addon_gift_revenue*weighting END AS addon_gift_revenue

     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.baby_revenue*weighting END AS baby_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.kids_revenue*weighting END AS kids_revenue
     , CASE WHEN ic.next_conversion_number IS NULL THEN NULL ELSE o.adult_revenue*weighting END AS adult_revenue

     , ic.interaction_type
     , ic.user_agent
     , o.state
     , fe.reached_personalisation
    --COUNT(DISTINCT ic.interaction_id) as number_of_sessions

  FROM interaction_chain_rules_28d ic
  LEFT JOIN attributable_orders o 
    ON ic.next_conversion_number = o.order_number
  left join funnel_data fe on fe.session_id = ic.interaction_id
        --GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16