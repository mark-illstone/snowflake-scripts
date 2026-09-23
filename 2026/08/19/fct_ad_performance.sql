create or replace table bi.mark_dev.fct_ad_performance as

WITH attributed_interactions AS (SELECT * FROM bi.mark_dev.int_attributed_interactions)
   , cost_per_interaction AS (SELECT * FROM bi.dbt_production_intermediate.int_cost_per_interaction)

, base AS (
    SELECT ai.interaction_day
         , ai.ad_key
         , ai.country_fk
         , ai.customer_type
         , ai.attribution_model
         , ai.state
         , COALESCE(SUM(ai.conversions),0) AS conversions
         , COALESCE(SUM(ai.net_revenue),0) AS net_revenue
         , COALESCE(SUM(ai.core_revenue), 0) AS core_revenue
         , COALESCE(SUM(ai.experimental_revenue), 0) AS experimental_revenue

            , COALESCE(SUM(ai.older_kids_revenue), 0) AS older_kids_revenue
            , COALESCE(SUM(ai.early_years_revenue), 0) AS early_years_revenue
            , COALESCE(SUM(ai.hybrid_family_revenue), 0) AS hybrid_family_revenue
            , COALESCE(SUM(ai.adult_gift_revenue), 0) AS adult_gift_revenue
            , COALESCE(SUM(ai.picture_book_revenue), 0) AS picture_book_revenue
            , COALESCE(SUM(ai.addon_gift_book_revenue), 0) AS addon_gift_book_revenue
            , COALESCE(SUM(ai.addon_gift_revenue), 0) AS addon_gift_revenue

            , COALESCE(SUM(ai.baby_revenue), 0) AS baby_revenue
            , COALESCE(SUM(ai.kids_revenue), 0) AS kids_revenue
            , COALESCE(SUM(ai.adult_revenue), 0) AS adult_revenue
            , COALESCE(SUM(CASE WHEN ai.reached_personalisation = 1 THEN 1 ELSE 0 END), 0) AS reached_personalisation

         , COALESCE(SUM(ai.gross_profit),0) AS gross_profit
         , COUNT(DISTINCT CASE WHEN ai.interaction_type = 'website session'  THEN ai.interaction_id ELSE null END) as number_of_sessions
        --COALESCE(COUNT(DISTINCT ai.interaction_id),0) as number_of_sessions
     FROM attributed_interactions ai
    group by 1,2,3,4,5,6
)

, costs AS (
    SELECT * 
      FROM cost_per_interaction
     CROSS JOIN (SELECT DISTINCT attribution_model as attribution_model 
                   FROM attributed_interactions)
)

SELECT COALESCE(i.interaction_day, c.day) AS interaction_day
     , COALESCE(i.ad_key, c.ad_key) AS ad_key
     , COALESCE(i.country_fk, c.country_fk) AS country_fk
     , COALESCE(i.customer_type, c.customer_type) AS customer_type
     , COALESCE(i.attribution_model, c.attribution_model) AS attribution_model
     , COALESCE(i.conversions, 0) AS conversions
     , COALESCE(i.net_revenue, 0) AS net_revenue
     , COALESCE(i.core_revenue, 0) AS core_revenue
     , COALESCE(i.experimental_revenue, 0) AS experimental_revenue
     , COALESCE(i.gross_profit, 0) AS gross_profit
     , COALESCE(c.cost, 0) AS cost
     , COALESCE(c.impressions, 0) AS impressions
     , COALESCE(c.clicks, 0) AS clicks
     , COALESCE(c.commissions, 0) AS commission
     , COALESCE(i.number_of_sessions, 0) AS number_of_sessions
     , COALESCE(i.gross_profit, 0) - COALESCE(c.cost, 0) AS contribution
     , COALESCE(i.state, '') AS state

            , COALESCE(i.older_kids_revenue, 0) AS older_kids_revenue
            , COALESCE(i.early_years_revenue, 0) AS early_years_revenue
            , COALESCE(i.hybrid_family_revenue, 0) AS hybrid_family_revenue
            , COALESCE(i.adult_gift_revenue, 0) AS adult_gift_revenue
            , COALESCE(i.picture_book_revenue, 0) AS picture_book_revenue
            , COALESCE(i.addon_gift_book_revenue, 0) AS addon_gift_book_revenue
            , COALESCE(i.addon_gift_revenue, 0) AS addon_gift_revenue

            , COALESCE(i.baby_revenue, 0) AS baby_revenue
            , COALESCE(i.kids_revenue, 0) AS kids_revenue
            , COALESCE(i.adult_revenue, 0) AS adult_revenue
            , COALESCE(i.reached_personalisation, 0) as reached_personalisation
            
  FROM base i
  FULL OUTER JOIN costs c
    ON c.day = i.interaction_day
   AND c.ad_key = i.ad_key
   AND c.country_fk = i.country_fk
   AND c.state = i.state
   AND c.customer_type = i.customer_type
   AND c.attribution_model = i.attribution_model