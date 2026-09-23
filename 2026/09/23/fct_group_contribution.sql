WITH group_contribution AS (SELECT * FROM bi.google_sheets.group_contribution)
    , wonderbly_budget_tracker AS (SELECT * FROM bi.dbt_production_models.fct_country_budget_tracker)
    , hn_budget_tracker AS (SELECT * FROM bi.historical_newspapers_shopify.fct_budget_tracker)
    , wonderbly_royalties AS (SELECT * FROM bi.dbt_production_models.fct_order_items)
    , interco AS (SELECT * FROM bi.google_sheets.hn_interco_budget_gp)
    , hn_marketing_spend AS (SELECT * FROM bi.historical_newspapers.fct_marketing_performance)
    , wonderbly_marketing_spend AS (SELECT * FROM bi.dbt_production_models.fct_marketing_attribution)
    , wonderbly_early_marketing_spend AS (SELECT * FROM bi.dbt_production_intermediate.int_early_marketing_cost)
    , group_contribution_media_budget AS (SELECT * FROM bi.google_sheets.group_contribution_media_budget)
  




/* ---------------------------------------------------------
   1. Group contribution exploded by country
---------------------------------------------------------- */

, countries AS (
    SELECT 'UK'  AS country UNION ALL
    SELECT 'USA' AS country UNION ALL
    SELECT 'RoW' AS country
)

, group_contribution_expanded AS (
    SELECT
        TO_DATE(gc.month, 'DD/MM/YYYY')                       AS date,
        gc.channel                     AS sales_channel,
        gc.brand,
        c.country,

    gc.non_media_spend_actual::FLOAT / 100 as non_media_spend_actual_pct,
    gc.non_media_spend_budget::FLOAT / 100 as non_media_spend_budget_pct,
    gc.gp_budget::FLOAT / 100 as gp_budget_pct,
   -- gc.media_spend_budget::FLOAT / 100 as media_spend_budget_pct

    FROM group_contribution gc
    CROSS JOIN countries c

)

, group_contribution_media_budget_expanded AS (
    SELECT
        TO_DATE(gmb.date, 'DD/MM/YYYY') AS date,
        gmb.channel AS sales_channel,
        gmb.brand,
        c.country,
        gmb.media_spend_budget_pct::FLOAT / 100 AS media_spend_budget_pct
    FROM group_contribution_media_budget gmb
    CROSS JOIN countries c
)

/* ---------------------------------------------------------
   2. Country budget tracker (Wonderbly)
---------------------------------------------------------- */

, wonderbly_budget AS (
    SELECT
        budget_phasing_dt                      AS date,
        CASE
        WHEN market in ('USA', 'UK') THEN market
        ELSE 'RoW'
        END AS country,
        'Retail'                       AS sales_channel,
        'Wonderbly'                    AS brand,

        sum(units_target) as units_target,
        sum(units_actual) as units_actual,
        sum(units_actual_ly) as units_actual_ly,
        sum(net_revenue_target) as net_revenue_target,
        sum(net_revenue_actual) as net_revenue_actual,
        sum(net_revenue_actual_ly) as net_revenue_actual_ly,
        sum(gross_profit_actual) as gross_profit_actual,
        sum(gross_profit_actual_ly) as gross_profit_actual_ly,
        sum(orders_actual) as orders_actual,
        sum(orders_target) as orders_target,
        sum(orders_actual_ly) as orders_actual_ly,
        sum(cogs_total_actual) as cogs_total_actual,
        sum(cogs_total_actual_ly) as cogs_total_actual_ly,
        sum(new_orders_actual) as new_orders_actual,
        sum(new_orders_ly) as new_orders_ly,
        sum(repeat_orders_actual) as repeat_orders_actual,
        sum( repeat_orders_ly) as repeat_orders_ly,
        NULL as gross_profit_interco_target

    FROM wonderbly_budget_tracker
    group by all


)

/* ---------------------------------------------------------
   3. HN budget tracker
---------------------------------------------------------- */

, hn_budget AS (
    SELECT
        budget_date                    AS date,
        CASE
            WHEN lower(country) = 'united states'  THEN 'USA'
            WHEN lower(country) = 'united kingdom' THEN 'UK'
            ELSE 'RoW'
        END                             AS country,
        trade_group                     AS sales_channel,
        'HN'                            AS brand,

        sum(units_target) as units_target,
        sum(units_actual) as units_actual,
        sum(units_actual_ly) as units_actual_ly,
        sum(net_revenue_target) as net_revenue_target,
        sum(net_revenue_actual) as net_revenue_actual,
        sum(net_revenue_actual_ly) as net_revenue_actual_ly,
        sum(gross_profit_actual) as gross_profit_actual,
        sum(gross_profit_actual_ly) as gross_profit_actual_ly,
        sum(orders_actual) as orders_actual,
        sum(orders_target) as orders_target,
        sum(orders_actual_ly) as orders_actual_ly,
        sum(cogs_total_actual) as cogs_total_actual,
        sum(cogs_total_actual_ly) as cogs_total_actual_ly,
        sum(new_orders_actual) as new_orders_actual,
        sum(new_orders_ly) as new_orders_ly,
        sum(repeat_orders_actual) as repeat_orders_actual,
        sum( repeat_orders_ly) as repeat_orders_ly,
        NULL as gross_profit_interco_target

    FROM hn_budget_tracker
    group by all
)


/* ---------------------------------------------------------
   4. HN on Wonderbly royalties
---------------------------------------------------------- */

, royalties_daily AS (
    SELECT
        ordered_date AS date,

        CASE
            WHEN LOWER(ship_country) = 'united states'  THEN 'USA'
            WHEN LOWER(ship_country) = 'united kingdom' THEN 'UK'
            ELSE 'RoW'
        END AS country,

        'Interco' AS sales_channel,
        'HN' AS brand,

        NULL AS units_target,
        NULL AS units_actual,
        NULL AS units_actual_ly,
        NULL AS net_revenue_target,
        NULL AS net_revenue_actual,
        NULL AS net_revenue_actual_ly,

        SUM(royalty_fees * 0.7) AS gross_profit_actual,
        NULL as gross_profit_actual_ly,

        NULL AS orders_actual,
        NULL AS orders_target,
        NULL AS orders_actual_ly,
        NULL AS cogs_total_actual,
        NULL AS cogs_total_actual_ly,
        NULL AS new_orders_actual,
        NULL AS new_orders_ly,
        NULL AS repeat_orders_actual,
        NULL AS repeat_orders_ly,
        NULL AS gross_profit_interco_target
        
    FROM wonderbly_royalties
    GROUP BY all
)


, royalties_daily_ly as (
    SELECT
        date + 364 AS date,
        country,
        sales_channel,
        brand,

        NULL AS units_target,
        NULL AS units_actual,
        NULL AS units_actual_ly,
        NULL AS net_revenue_target,
        NULL AS net_revenue_actual,
        NULL AS net_revenue_actual_ly,

        NULL AS gross_profit_actual,
        SUM(gross_profit_actual) AS gross_profit_actual_ly,

        NULL AS orders_actual,
        NULL AS orders_target,
        NULL AS orders_actual_ly,
        NULL AS cogs_total_actual,
        NULL AS cogs_total_actual_ly,
        NULL AS new_orders_actual,
        NULL AS new_orders_ly,
        NULL AS repeat_orders_actual,
        NULL AS repeat_orders_ly,
        NULL AS gross_profit_interco_target

    FROM royalties_daily
    GROUP BY 1,2,3,4
)


/* ---------------------------------------------------------
   5. HN Interco GP targets
---------------------------------------------------------- */

, interco_gp_targets as (
SELECT
        to_date(date,'DD/MM/YYYY') as date,
        CASE
            WHEN LOWER(country) = 'united states'  THEN 'USA'
            WHEN LOWER(country) = 'united kingdom' THEN 'UK'
            ELSE 'RoW'
        END AS country,

        'Interco' AS sales_channel,
        'HN' AS brand,

        NULL AS units_target,
        NULL AS units_actual,
        NULL AS units_actual_ly,
        NULL AS net_revenue_target,
        NULL AS net_revenue_actual,
        NULL AS net_revenue_actual_ly,

        NULL as gross_profit_actual,
        NULL as gross_profit_actual_ly,

        NULL AS orders_actual,
        NULL AS orders_target,
        NULL AS orders_actual_ly,
        NULL AS cogs_total_actual,
        NULL AS cogs_total_actual_ly,
        NULL as new_orders_actual,
        NULL as new_orders_ly,
        NULL as repeat_orders_actual,
        NULL as repeat_orders_ly,
        COALESCE(REPLACE(gp_budget, ',','')::FLOAT, 0) as gross_profit_interco_target
        
from interco

)


/* ---------------------------------------------------------
   6. Union both budget sources
---------------------------------------------------------- */

, all_budgets AS (
    SELECT * FROM wonderbly_budget
    UNION ALL
    SELECT * FROM hn_budget
    UNION ALL
    SELECT * FROM royalties_daily
    UNION ALL
    SELECT * FROM royalties_daily_ly
    UNION ALL 
    SELECT * FROM interco_gp_targets
    
)


/* ---------------------------------------------------------
   7. HN Media Spend
---------------------------------------------------------- */

, media_newspapers AS (
    SELECT
        day AS date,
        CASE
            WHEN LOWER(country) = 'united states'  THEN 'USA'
            WHEN LOWER(country) = 'united kingdom' THEN 'UK'
            ELSE 'RoW'
        END AS country,
        trade_group AS sales_channel,
        'HN' as brand,
        SUM(cost) AS media_spend
    FROM hn_marketing_spend
    GROUP BY 1, 2, 3
)

, media_newspapers_ly as (

    SELECT
        date + 364        AS date,
        country,
        sales_channel,
        brand,
        SUM(media_spend) AS media_spend_ly
    FROM media_newspapers
    GROUP BY 1,2,3,4
)


/* ---------------------------------------------------------
   8. Wonderbly Media Spend
---------------------------------------------------------- */


, attribution_dates AS (
    SELECT DISTINCT date
    FROM wonderbly_marketing_spend
)

, revenue_weights AS (
    SELECT
        date,
        country,
        sales_channel,
        brand,
        net_revenue_actual
            / NULLIF(
                SUM(net_revenue_actual) OVER (
                    PARTITION BY date, sales_channel, brand
                ), 0
              ) AS revenue_weight
    FROM all_budgets
    WHERE brand = 'Wonderbly'
)

, media_wonderbly_attribution AS (
    SELECT
        date,
        CASE
            WHEN LOWER(country) = 'united states'  THEN 'USA'
            WHEN LOWER(country) = 'united kingdom' THEN 'UK'
            ELSE 'RoW'
        END AS country,
        'Retail' AS sales_channel,
        'Wonderbly' as brand,
        SUM(cost) AS media_spend
    FROM wonderbly_marketing_spend
    GROUP BY 1, 2, 3
)

, media_wonderbly_early AS (
    SELECT
        e.date,
        w.country,
        w.sales_channel,
        'Wonderbly' AS brand,
        SUM(e.cost * w.revenue_weight) AS media_spend
    FROM wonderbly_early_marketing_spend e
    JOIN revenue_weights w
        ON e.date = w.date
    WHERE NOT EXISTS (
        SELECT 1
        FROM attribution_dates a
        WHERE a.date = e.date
    )
    GROUP BY 1, 2, 3, 4
)

, media_wonderbly AS (
    SELECT * FROM media_wonderbly_attribution
    UNION ALL
    SELECT * FROM media_wonderbly_early
)

, media_wonderbly_ly as (
    SELECT
        date + 364        AS date,
        country,
        sales_channel,
        brand,
        SUM(media_spend) AS media_spend_ly
    FROM media_wonderbly
    GROUP BY 1,2,3,4
)


/* ---------------------------------------------------------
   9. Media Spend Union
---------------------------------------------------------- */

, media_spend AS (
    SELECT * FROM media_newspapers
    UNION ALL
    SELECT * FROM media_wonderbly
)

, media_spend_ly AS (
    SELECT * FROM media_newspapers_ly
    UNION ALL
    SELECT * FROM media_wonderbly_ly
)

/* ---------------------------------------------------------
   10. Final Select
---------------------------------------------------------- */

    SELECT
        b.date,
        b.country,
        b.sales_channel,
        b.brand,
        sum(coalesce(b.units_target, 0)) as units_target,
        sum(coalesce(b.units_actual, 0)) as units_actual,
        sum(coalesce(b.units_actual_ly, 0)) as units_actual_ly,
        sum(coalesce(b.net_revenue_actual, 0)) as net_revenue_actual,
        sum(coalesce(b.net_revenue_target, 0)) as net_revenue_target,
        sum(coalesce(b.net_revenue_actual_ly, 0)) as net_revenue_actual_ly,
        sum(coalesce(b.gross_profit_actual, 0)) as gross_profit_actual,
        sum(coalesce(b.gross_profit_actual_ly, 0)) as gross_profit_actual_ly,
        sum(coalesce(b.orders_actual, 0)) as orders_actual,
        sum(coalesce(b.orders_target, 0)) as orders_target,
        sum(coalesce(b.orders_actual_ly, 0)) as orders_actual_ly,
        sum(coalesce(b.cogs_total_actual, 0)) as cogs_total_actual,
        sum(coalesce(b.cogs_total_actual_ly, 0)) as cogs_total_actual_ly,
        sum(coalesce(b.new_orders_actual, 0)) as new_orders_actual,
        sum(coalesce(b.new_orders_ly, 0)) as new_orders_ly,
        sum(coalesce(b.repeat_orders_actual, 0)) as repeat_orders_actual,
        sum(coalesce(b.repeat_orders_ly, 0)) as repeat_orders_ly,

        sum(coalesce(c.media_spend, 0)) as media_spend,
        sum(coalesce(cl.media_spend_ly, 0)) as media_spend_ly,
        
    
        /* Applied metrics */
        sum(case when b.sales_channel = 'Interco' then COALESCE(b.gross_profit_interco_target,0)
        else coalesce(gc_actual.gp_budget_pct,0) * coalesce(b.net_revenue_target,0) end) AS gp_budget,
        
       -- sum(coalesce(gc_actual.media_spend_budget_pct,0) * coalesce(b.net_revenue_target,0)) AS media_spend_budget,
        sum(coalesce(gmb.media_spend_budget_pct,0) * coalesce(b.net_revenue_target,0)) AS media_spend_budget,
        sum(coalesce(gc_actual.non_media_spend_actual_pct,0) * coalesce(b.net_revenue_target,0)) AS non_media_spend_actual,
        sum(coalesce(gc_actual.non_media_spend_budget_pct,0) * coalesce(b.net_revenue_target,0)) AS non_media_spend_budget,
        
        sum(coalesce(gc_ly.non_media_spend_actual_pct,0) * coalesce(b.net_revenue_target,0)) AS non_media_spend_actual_ly,

        sum(coalesce(gc_actual.non_media_spend_actual_pct, 0)) as non_media_spend_actual_pct,
        sum(coalesce(gc_actual.non_media_spend_budget_pct, 0)) as non_media_spend_budget_pct,
        sum(coalesce(gc_actual.gp_budget_pct, 0)) as gp_budget_pct,
        --sum(coalesce(gc_actual.media_spend_budget_pct, 0)) as media_spend_budget_pct
        sum(coalesce(gmb.media_spend_budget_pct, 0)) as media_spend_budget_pct

    FROM all_budgets b
    
LEFT JOIN group_contribution_expanded gc_actual
    ON DATE_TRUNC('month', b.date) = gc_actual.date
    AND b.country = gc_actual.country
    AND b.sales_channel = gc_actual.sales_channel
    AND b.brand = gc_actual.brand

LEFT JOIN group_contribution_expanded gc_ly
    ON DATE_TRUNC('month', b.date - 364) = gc_ly.date
    AND b.country = gc_ly.country
    AND b.sales_channel = gc_ly.sales_channel
    AND b.brand = gc_ly.brand
        
    LEFT JOIN media_spend c
        ON  b.date          = c.date
        AND b.country       = c.country
        AND b.sales_channel = c.sales_channel
         AND b.brand         = c.brand

    LEFT JOIN media_spend_ly cl
    ON  b.date          = cl.date
    AND b.country       = cl.country
    AND b.sales_channel = cl.sales_channel
    AND b.brand         = cl.brand

    LEFT JOIN group_contribution_media_budget_expanded gmb
    ON  b.date          = gmb.date
    AND b.country       = gmb.country
    AND b.sales_channel = gmb.sales_channel
    AND b.brand         = gmb.brand


    GROUP BY
    b.date,
    b.country,
    b.sales_channel,
    b.brand