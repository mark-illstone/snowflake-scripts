create or replace table bi.mark_dev.int_interactions_by_next_conversion_number as

WITH interactions AS (SELECT * FROM bi.mark_dev.int_interactions)

SELECT i.interaction_id
     , i.ad_key
     , i.visitor_id
     , i.order_number
     , i.day
     , i.interaction_timestamp

     , country_fk
     , gclick_id
     , fbclick_id
     
     , FIRST_VALUE(i.order_number IGNORE NULLS) OVER (PARTITION BY i.visitor_id ORDER BY i.interaction_timestamp ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS next_conversion_number
     
     , FIRST_VALUE(i.order_timestamp IGNORE NULLS) OVER (PARTITION BY i.visitor_id ORDER BY i.interaction_timestamp ASC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS next_conversion_timestamp
     
     , LAST_VALUE(i.order_number IGNORE NULLS) OVER (PARTITION BY i.visitor_id ORDER BY i.interaction_timestamp ASC ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_conversion_number
     
     , i.interaction_type
     , i.user_agent
  --i.number_of_sessions

  FROM INTERACTIONS  i