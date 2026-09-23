--create or replace table bi.mark_dev.fct_pnl_by_country_category as

WITH fct_order_items AS (SELECT * FROM bi.dbt_production_models.fct_order_items)

, order_brand AS (
    SELECT DISTINCT
        order_number,
        ordered_date::DATE AS day,
        sub_category,
        brand,
        CASE
            WHEN bill_country = 'United States' THEN 'US'
            WHEN bill_country = 'United Kingdom' THEN 'UK'
            WHEN bill_country = 'Canada' THEN 'CA'
            WHEN bill_country = 'Germany' THEN 'DE'
            WHEN bill_country = 'Australia' THEN 'AU'
            WHEN bill_country = 'France' THEN 'FR'
            WHEN bill_country = 'Spain' THEN 'ES'
            WHEN bill_country = 'Italy' THEN 'IT'
            WHEN bill_country = 'Netherlands' THEN 'ROW-NL'
            ELSE 'ROW'
        END AS trade_country_group,
        CASE WHEN is_repeat = TRUE THEN 1 END AS new_count,
    FROM fct_order_items
    WHERE is_completed = 'true'
),

order_brand_weighted AS (
    SELECT
        order_number,
        day,
        sub_category,
        brand,
        trade_country_group,
        new_count,
        1.0 / COUNT(DISTINCT brand) OVER (PARTITION BY order_number) AS order_weight
    FROM order_brand
),

-- orders: aggregate straight from the deduplicated order-brand grain,
-- no fan-out risk here since it's already one row per order_number x brand
orders_agg AS (
    SELECT
        day,
        sub_category,
        brand,
        trade_country_group,
        SUM(new_count) AS new_count,
        SUM(order_weight) AS orders
    FROM order_brand_weighted
    GROUP BY day, sub_category, brand, trade_country_group
),

-- units/revenue: aggregate straight from the full line-item table,
-- independently - never joined to the weighted table directly
items_agg AS (
    SELECT
        ordered_date::DATE AS day,
        sub_category,
        brand,
        CASE
            WHEN bill_country = 'United States' THEN 'US'
            WHEN bill_country = 'United Kingdom' THEN 'UK'
            WHEN bill_country = 'Canada' THEN 'CA'
            WHEN bill_country = 'Germany' THEN 'DE'
            WHEN bill_country = 'Australia' THEN 'AU'
            WHEN bill_country = 'France' THEN 'FR'
            WHEN bill_country = 'Spain' THEN 'ES'
            WHEN bill_country = 'Italy' THEN 'IT'
            WHEN bill_country = 'Netherlands' THEN 'ROW-NL'
            ELSE 'ROW'
        END AS trade_country_group,
        SUM(CASE WHEN is_repeat THEN 1 END) AS new_count,
        COUNT(DISTINCT order_item_id) AS units,
        SUM(net_revenue) AS net_revenue,
        SUM(gross_profit) AS gross_profit
    FROM fct_order_items
    WHERE is_completed = 'true'
    GROUP BY 1, 2, 3, 4
)
,temp as
(
SELECT
    i.day,
    i.sub_category,
    i.brand,
    i.trade_country_group,
    i.new_count,
    i.units,
    o.orders,--
    i.net_revenue,
    i.gross_profit,
    i.gross_profit * (i.new_count / i.units) AS new_customer_gross_profit,
    i.new_count / i.units
FROM items_agg i
JOIN orders_agg o
    ON  i.day = o.day
    AND i.sub_category = o.sub_category
    AND i.brand = o.brand
    AND i.trade_country_group = o.trade_country_group
)
select *
from temp
where day = '2026-08-17'
and brand like '%newspaper%'