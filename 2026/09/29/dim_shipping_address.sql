CREATE OR REPLACE TABLE bi.mark_dev.dim_shipping_address AS

WITH shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_shipments)
   , orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication)
   , addresses AS (SELECT * FROM bi.dbt_production_intermediate.int_addresses)
   , states AS (SELECT * FROM bi.dbt_production_intermediate.int_states)
   , countries AS (SELECT * FROM bi.dbt_production_intermediate.int_countries)
   , shipping_rates AS (SELECT * FROM bi.dbt_production_intermediate.int_shipping_rates)
   , shipping_methods AS (SELECT * FROM bi.dbt_production_intermediate.int_shipping_methods)
   , finance_shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_shipments)
   , psp_speed_mapping AS (SELECT * FROM bi.google_sheets.psp_speed_mapping)
   , printhouses AS (SELECT * FROM bi.dbt_production_intermediate.int_printhouses)
   , shipping_calendar AS (SELECT * FROM bi.mark_dev.int_shipping_calendar)
   , tth_markets AS (SELECT DISTINCT market_code FROM shipping_calendar)

SELECT a.order_id AS order_id
     , a.printhouse_id
     , d.id AS ship_country_id
     , b.id AS ship_address_id
     , b.address1 AS ship_address_1
     , b.address2 AS ship_address_2
     , b.city AS ship_address_city
     , c.name AS ship_address_state
     , d.name AS ship_country
     , b.zipcode AS ship_address_zipcode
     , f.shipping_type AS shipping_type
     , a.shipped_at::DATE AS shipped_date
     , a.shipped_at AS shipped_at    
     , a.expected_shipping_date
     , a.expected_delivery_date
     , a.expected_shipping_date_local
     , TIMESTAMPDIFF('hours', a.expected_shipping_date, a.expected_shipping_date_local) AS timezone_adjustment
     , DATEADD(hour, timezone_adjustment, a.shipped_at) as shipped_at_local
     , datediff(day,o.completed_at, a.shipped_at) AS days_to_ship
      -- 11/11/2020 AS: removed AS it creates dupes downstream and can be calculated from order item weight in Looker
      -- g.weight_in_grams AS order_weight,
     , h.shipment_id AS shipping_id   
     , f.code AS shipping_code
     , j.speed AS us_state_speed
     , del.working_day_seq - ship.working_day_seq AS tth_working_days
  FROM shipments a
  LEFT JOIN orders o 
    ON a.order_id = o.id
  LEFT JOIN addresses b
    ON o.ship_address_id = b.id
  LEFT JOIN states c
    ON b.state_id = c.id 
  LEFT JOIN countries d
    ON b.country_id = d.id 
  LEFT JOIN shipping_rates e
    ON a.id = e.shipment_id 
   AND e.selected = true

  LEFT JOIN shipping_methods f
    ON e.shipping_method_id = f.id 
  LEFT JOIN finance_shipments h 
    ON a.id = h.shipment_id

  LEFT JOIN printhouses i
    ON a.printhouse_id = i.id
  LEFT JOIN psp_speed_mapping j
    ON LOWER(c.name) = LOWER(j.state)
    AND LOWER(i.printhouse_name) = LOWER(j.psp)
    AND a.shipped_at::date BETWEEN TO_DATE(j.effective_from, 'DD/MM/YYYY') AND TO_DATE(j.effective_to, 'DD/MM/YYYY')
    AND LOWER(brand) = 'wonderbly'

  LEFT JOIN shipping_calendar ship
    ON LOWER(ship.market_code) = CASE WHEN LOWER(d.iso) NOT IN (SELECT LOWER(market_code) FROM tth_markets) THEN 'default' ELSE LOWER(COALESCE(d.iso, 'default')) END
    AND LOWER(ship.shipping_service) = LOWER(COALESCE(f.shipping_type, 'standard'))
    AND ship.cal_date = a.expected_shipping_date::DATE
  LEFT JOIN shipping_calendar del
    ON  LOWER(del.market_code)  = CASE WHEN LOWER(d.iso) NOT IN (SELECT LOWER(market_code) FROM tth_markets) THEN 'default' ELSE LOWER(COALESCE(d.iso, 'default')) END
    AND LOWER(del.shipping_service) = LOWER(COALESCE(f.shipping_type, 'standard'))
    AND del.cal_date = a.expected_delivery_date::DATE