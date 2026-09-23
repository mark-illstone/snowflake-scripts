create or replace table bi.mark_dev.int_interaction_chains as

WITH interactions_by_next_conversion_number AS (SELECT * FROM bi.mark_dev.int_interactions_by_next_conversion_number where interaction_timestamp::date >= '2026-06-01')
   , ga_transactions AS (SELECT * FROM bi.dbt_production_intermediate.int_ga_transactions where ordered_at::date >= '2026-06-01')

, temp_interactions_by_next_conversion_number AS (
    SELECT day
         , interaction_timestamp AS interaction_timestamp
         
         , interaction_id
         , order_number
         , next_conversion_number
         , next_conversion_timestamp
         
         , ad_key
         , visitor_id
         
         , country_fk
         , gclick_id
         , fbclick_id
         
         , COUNT(1) OVER (PARTITION BY visitor_id, next_conversion_number) AS chain_length
         
         , COUNT(1) OVER (PARTITION BY visitor_id, next_conversion_number ORDER BY interaction_timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS position_in_chain
         
         , interaction_type
         , user_agent
        --number_of_sessions

      FROM interactions_by_next_conversion_number
)

, interactions_by_next_conversion_number_with_chain_index AS (
  SELECT *
       , COUNT(CASE WHEN position_in_chain = 1 THEN 1 END) OVER (PARTITION BY visitor_id ORDER BY interaction_timestamp, next_conversion_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS chain_index

    FROM  temp_interactions_by_next_conversion_number
)

, session_first_order_interaction_chains as (
    SELECT visitor_id || '#' || chain_index AS chain_key
    
         , interaction_id
         , order_number
         , next_conversion_number
         , next_conversion_timestamp
         
         , ad_key
         , visitor_id
         -- different definition of repeat than orders
         , CASE WHEN chain_index > 1 THEN 'repeat' ELSE 'new' END AS customer_type
         
         , country_fk
         , gclick_id
         , fbclick_id
         
         , day
         , interaction_timestamp
         , MIN(interaction_timestamp) OVER(PARTITION BY visitor_id, chain_index) AS start_of_chain_timestamp
         , MAX(interaction_timestamp) OVER(PARTITION BY visitor_id, chain_index) AS end_of_chain_timestamp
         
         , next_conversion_number IS NOT NULL AS is_chain_converting
         , chain_index > 1 AS is_chain_repeat
         
         , chain_index
         , chain_length
         , position_in_chain
         
         , DATEDIFF(day, MIN(interaction_timestamp) OVER(PARTITION BY visitor_id, chain_index), MAX(interaction_timestamp) OVER(PARTITION BY visitor_id, chain_index)) AS number_of_days
         
         , interaction_type
         , user_agent
    --number_of_sessions

      FROM  interactions_by_next_conversion_number_with_chain_index
)

, base AS (
    SELECT order_number
         , ordered_at
         , FIRST_VALUE(order_number) OVER (PARTITION BY session_id ORDER BY ordered_at ASC) AS sessions_first_order 
      FROM ga_transactions T
            -- Jim 29/09/21 - Artificial RAF orders appear in interaction chains and duplicate session transactions. Remove any duplicates
            --WHERE not exists (SELECT 1 from session_first_order_interaction_chains C where C.order_number = T.ORDER_NUMBER) 
)

SELECT a.chain_key || '#' || COALESCE(b.order_number, a.next_conversion_number) as chain_key
     , a.interaction_id
     -- added by Clara
     , CASE WHEN a.order_number IS NOT NULL and b.order_number is not null THEN b.order_number 
            ELSE a.order_number 
       END as order_number
     , COALESCE(b.order_number, a.next_conversion_number) AS next_conversion_number
     , COALESCE(b.ordered_at, a.next_conversion_timestamp) AS next_conversion_timestamp
     , a.ad_key
     , a.visitor_id
     , CASE WHEN a.chain_index = 1 AND b.order_number <> b.sessions_first_order THEN 'repeat' 
            ELSE a.customer_type 
       END as customer_type
     , a.country_fk
     , a.gclick_id
     , a.fbclick_id
     , a.day
     , a.interaction_timestamp
     , a.start_of_chain_timestamp
     , a.end_of_chain_timestamp
     , a.is_chain_converting
     , a.is_chain_repeat
     , a.chain_index
     , a.chain_length
     , a.position_in_chain
     , a.number_of_days
     , DATEDIFF(day, interaction_timestamp, COALESCE(b.ordered_at, a.next_conversion_timestamp)) AS number_of_days_before_conversion
     , a.interaction_type
     , a.user_agent
        --a.number_of_sessions
  FROM session_first_order_interaction_chains a 

-- Duplicate the interaction_chain for every transaction in a session
--  All transactions from the same order will have the same interaction_chain
LEFT JOIN base b 
  ON b.sessions_first_order = a.next_conversion_number