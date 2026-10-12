

WITH base AS (SELECT * FROM bi.google_sheets.ops_unit_forecast)
    , budget_phasing AS (SELECT * FROM bi.google_sheets.country_budget_phasing)
    , order_items AS (SELECT * FROM bi.dbt_production_models.fct_order_items)
    , addons AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_addons)
    , country_mapping AS (SELECT * FROM bi.google_sheets.ops_fc_country_mapping)

SELECT
    base.country,
    base.month,
    base.cover,
    base.format,
    base.format_cover,
    base.gw_format,
    base.gb_format,
    base.gb_deluxe_format,
    coalesce(base.units * (index/100), base.units) AS units,
    coalesce(base.gw_units * (index/100), base.gw_units) AS gw_units,
    coalesce(base.gb_units * (index/100), base.gb_units) AS gb_units,
    coalesce(base.gb_deluxe_units * (index/100), base.gb_deluxe_units) AS gb_deluxe_units,
    base.main_market,
    base.psp,
    coalesce(to_date(bp.date,'DD/MM/YYYY'), base.month) AS phasing_date,
    cm.main_market AS market_group,
    count(distinct o.order_item_id) AS units_actual,
    count(distinct gw.order_item_id) AS gift_wrap_actual,
    count(distinct gb.order_item_id) AS gift_box_actual,
    count(distinct gd.order_item_id) AS gift_box_deluxe_actual
FROM
    base
        LEFT JOIN budget_phasing bp
            ON CASE 
                    WHEN base.country = 'United Kingdom' THEN 'UK'
                    WHEN base.country = 'United States' THEN 'USA'
                    WHEN base.country NOT IN ('United Kingdom', 'United States') AND base.country NOT IN (SELECT market_phasing FROM budget_phasing) THEN 'RoW'
                    ELSE base.country
                END = bp.market_phasing
            AND base.month = date_trunc('MONTH',to_date(bp.date,'DD/MM/YYYY'))
            LEFT JOIN order_items o
                ON  base.country =  CASE
                                        WHEN o.ship_country IN ('Japan', 'New Zealand', 'Mexico', 'United States',
                                                                'United Kingdom','Australia','Canada','France','Germany','Italy','Netherlands',
                                                                'Ireland','Belgium','Switzerland','Austria','Spain','Denmark','Sweden','Portugal') 
                                            THEN o.ship_country
                                        WHEN o.ship_country IN ('Argentina','Chile','Puerto Rico','Brazil','Colombia','Peru') 
                                            THEN 'South America'
                                        WHEN o.ship_country IN (
                                                                'Bulgaria', 'Croatia', 'Cyprus', 'Czech Republic', 'Estonia', 'Finland', 'Greece', 
                                                                'Hungary', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 'Poland', 'Romania', 'Slovakia', 'Slovenia') 
                                            THEN 'EU'
                                        ELSE 'RoW'
                                    END
                AND base.cover = o.cover
                AND base.format = o.format
                AND to_date(bp.date,'DD/MM/YYYY') = o.ordered_at::date
                AND o.is_paid = 'Yes'
                AND lower(base.psp) = lower(o.printhouse_name)               
            LEFT JOIN addons gw
                ON o.order_item_id = gw.order_item_id
                AND lower(base.gw_format) = lower(gw.generic_sku)
                AND lower(gw.generic_sku) LIKE '%gw%'
            LEFT JOIN addons gb
                ON o.order_item_id = gb.order_item_id
                AND lower(base.gb_format) = lower(gb.generic_sku)
                AND lower(gb.generic_sku) LIKE '%gb%'
                AND lower(gb.generic_sku) NOT LIKE '%deluxe%'
            LEFT JOIN addons gd
                ON o.order_item_id = gd.order_item_id
                AND lower(base.gb_deluxe_format) = lower(gd.generic_sku)
                AND lower(gd.generic_sku) LIKE '%gb%'
                AND lower(gd.generic_sku) LIKE '%deluxe%'
            LEFT JOIN country_mapping cm
                ON base.country = cm.country
                    AND lower(cm.brand) = 'wbly'
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16