CREATE OR REPLACE TABLE bi.mark_dev.fct_hn_ops_unit_forecast_shopify AS

WITH base AS (SELECT * FROM bi.google_sheets.hn_ops_unit_forecast)
    , budget_phasing AS (SELECT * FROM bi.google_sheets.country_budget_phasing)
    , order_items AS (SELECT * FROM bi.historical_newspapers_shopify.fct_order_items)
    
,actuals_temp AS
(
SELECT
    CASE WHEN shipping_country_name IN ('United States', 'United Kingdom', 'Australia', 'Canada') 
         THEN shipping_country_name
         ELSE 'RoW'
    END                                                                                         AS ship_country,
    CASE WHEN lower(product_format) like '%hardback%' THEN 'Hardback' 
         WHEN lower(product_format) like '%softback%' THEN 'Softback' 
    END                                                                                         AS cover, 
    split_part(split_part(sku, ':', 3), '-', 1)                                                 AS format,
    to_varchar(paid_at::date)                                                                   AS ordered_at,
    CASE WHEN paid_at IS NOT NULL THEN 'Yes' ELSE 'No' END                                      AS is_paid,
    reseller_channel                                                                            AS channel,
    1                                                                                           AS units_actual,
    CASE WHEN LOWER(addon_giftbox_sku) = 'giftwrap:giftbox-tabloid:hn-white'  THEN 1 ELSE 0 END AS gb_keepsake_actual,
    CASE WHEN LOWER(addon_giftbox_sku) IN 
        (
            'giftwrap:giftbox-tabloid-hn:deluxe', 
            'giftwrap:giftbox-tabloid:hn-premium'
        )                                                                     THEN 1 ELSE 0 END AS gb_luxury_actual,
    CASE WHEN LOWER(sku) LIKE '%foil%' THEN 1 ELSE 0 END                                        AS units_foil_actual,
    CASE WHEN LOWER(sku) NOT LIKE '%foil%' THEN 1 ELSE 0 END                                    AS units_standard_actual
FROM order_items
WHERE created_at >= '2025-08-01'
AND primary_category IN ('Sports', 'Date', 'Theme')
)

,actuals_aggregated AS
(
SELECT
    ship_country,
    cover,
    format,
    ordered_at,
    is_paid,
    channel,
    sum(units_actual)                           AS units_actual,
    sum(gb_keepsake_actual + gb_luxury_actual)  AS gb_units_actual,
    sum(gb_keepsake_actual)                     AS gb_keepsake_actual,
    sum(gb_luxury_actual)                       AS gb_luxury_actual,
    sum(units_foil_actual)                      AS units_foil_actual,
    sum(units_standard_actual)                  AS units_standard_actual
FROM
    actuals_temp
GROUP BY
    1,2,3,4,5,6
)

SELECT
    base.country,
    base.month,
    base.cover,
    base.format,
    base.cover_format,
    base.country_format_sku,
    base.channel,
    coalesce(base.units          * (bp.index/100), base.units)          AS units,
    coalesce(base.units_foil     * (bp.index/100), base.units_foil)     AS units_foil,
    coalesce(base.units_standard * (bp.index/100), base.units_standard) AS units_standard,
    coalesce(base.gb_units       * (bp.index/100), base.gb_units)       AS gb_units,
    coalesce(base.gb_keepsake    * (bp.index/100), base.gb_keepsake)    AS gb_keepsake,
    coalesce(base.gb_luxury      * (bp.index/100), base.gb_luxury)      AS gb_luxury,
    coalesce(to_date(bp.date,'DD/MM/YYYY'), to_date(base.month, 'DD/MM/YYYY')) AS phasing_date,
    o.units_actual,
    o.gb_units_actual,
    o.gb_keepsake_actual,
    o.gb_luxury_actual,
    o.units_foil_actual,
    o.units_standard_actual,
    o.ordered_at
FROM
    base
        LEFT JOIN budget_phasing bp
            ON CASE 
                    WHEN base.country = 'United Kingdom' THEN 'UK'
                    WHEN base.country = 'United States' THEN 'USA'
                    WHEN base.country NOT IN ('United Kingdom', 'United States', 'Australia', 'Canada') THEN 'RoW'
                    ELSE base.country
                END = bp.market_phasing
            AND TO_DATE(base.month, 'DD/MM/YYYY') = date_trunc('MONTH',to_date(bp.date,'DD/MM/YYYY'))
            LEFT JOIN actuals_aggregated o
                ON  base.country = o.ship_country
                 AND base.cover = o.cover
                 AND base.format = o.format
                 AND base.channel = o.channel
                 AND to_date(bp.date,'DD/MM/YYYY') = o.ordered_at
                 AND o.is_paid = 'Yes'