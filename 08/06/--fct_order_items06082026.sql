--fct_order_items06082026

create or replace table bi.mark_dev.fct_order_items06082026 as



WITH order_items AS (SELECT * FROM bi.dbt_production_intermediate.int_order_items_deduplication)
   , adjustments AS (SELECT * FROM bi.dbt_production_intermediate.int_adjustments)
   , promotion_codes AS (SELECT * FROM bi.dbt_production_intermediate.int_promotion_codes)
   , temp_promotions AS (SELECT * FROM bi.dbt_production_intermediate.int_promotions)
   , promotion_categories AS (SELECT * FROM bi.dbt_production_intermediate.int_promotion_categories)
   , shipments AS (SELECT * FROM bi.dbt_production_intermediate.int_shipments)
   , temp_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders)
   , orders AS (SELECT * FROM bi.dbt_production_intermediate.int_orders_deduplication  where completed_at::date >= '2026-01-01')
   , users AS (SELECT * FROM bi.dbt_production_intermediate.int_users_deduplicated)
   , reorder_details AS (SELECT * FROM bi.dbt_production_intermediate.int_reorder_details)
   , unit_profit_and_loss AS (SELECT * FROM bi.dbt_production_intermediate.int_finance_unit_profit_and_loss)
   , int_dedications AS (SELECT * FROM bi.dbt_production_intermediate.int_dedications)
   , int_payment AS (SELECT * FROM bi.dbt_production_models.fct_finance_payment)
   , temp_users AS (SELECT * FROM bi.dbt_production_intermediate.int_users)
   , days AS (SELECT * FROM bi.dbt_production_models.dim_days)
   , shipping_address AS (SELECT * FROM bi.dbt_production_models.dim_shipping_address)
   , billing_address AS (SELECT * FROM bi.dbt_production_intermediate.int_billing_address)
   , print_house AS (SELECT * FROM bi.dbt_production_intermediate.int_printhouses)
   , resellers AS (SELECT * FROM bi.dbt_production_intermediate.int_resellers)
   , product_data AS (SELECT * FROM bi.dbt_production_intermediate.int_product_data)
   , eagle_transform_order_items AS (SELECT * FROM bi.mark_dev.int_eagle_transform_order_items_06082026)
   , excluded_orders AS (SELECT * FROM bi.etl.excluded_orders)
   , ww_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_ww_orders)
   , sg_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_sg_orders_base)
   , fp_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_fp_orders)
   , hn_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_hn_orders_solidus)
   , plucky_orders AS (SELECT * FROM bi.dbt_production_intermediate.int_plucky_orders_solidus)
   , fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)

, temp_adjustments AS (
  SELECT order_id
       , adjustable_id
       , MIN(promotion_code_id) AS promotion_code_id
       , MIN(label) AS label
      --,ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY adjustable_id, adjusted_at desc) AS rn 
    FROM adjustments
   WHERE promotion_code_id is not null
   GROUP by order_id, adjustable_id, label, adjusted_at
      --Dedupe
 QUALIFY rank() OVER (PARTITION BY order_id order by ADJUSTED_at desc) = 1
)

, promotions AS (
  SELECT DISTINCT a.order_id AS order_id
       , a.id --order_item_id
       , UPPER(c.code) AS promotion_code
       , b.label
       , e.name AS promotion_category
    FROM order_items a
    LEFT JOIN temp_adjustments b
      ON a.id = b.adjustable_id
     AND a.order_id=b.order_id
    LEFT JOIN promotion_codes c
      ON b.promotion_code_id = c.id
-- 05/07/2021 AS: added promo category
    LEFT JOIN temp_promotions d 
      ON d.id = c.promotion_id
    LEFT JOIN promotion_categories e 
      ON e.id = d.promotion_category_id

--04/05/2021 AS: deduping
   WHERE promotion_code IS NOT NULL 
--   rn = 1
)

, shipping_promo AS (
  SELECT DISTINCT order_id
       , MIN(p.code) AS code
    FROM adjustments a
    LEFT JOIN promotion_codes p 
      ON a.PROMOTION_CODE_ID = p.id
   WHERE a.order_id in (SELECT DISTINCT order_id FROM shipments)
   GROUP BY 1
  --where p.code is not null
  -- where a.order_id = 7502143
)
  
, order_position AS (
  SELECT id AS id
       , user_fk
       , ROW_NUMBER() OVER (PARTITION BY user_fk ORDER BY completed_at) AS position
    FROM temp_orders
)

, product_analytics AS (
  SELECT id
        , position
        , user_fk
        , MAX(position) OVER (PARTITION BY user_fk) max_order_rank
        , CASE WHEN position = MAX(position) OVER (PARTITION BY user_fk) - 1 THEN 1 ELSE 0 END AS order_before_last
     FROM order_position 
)

, order_referrals AS (
  SELECT c.id AS order_id
       , CASE WHEN c.position = 1 THEN a.id END AS referrer_fk
    FROM users a
    LEFT JOIN orders b 
      ON a.id = b.user_id 
    LEFT JOIN order_position c 
      ON b.id = c.id
)

, reorders AS (  
  SELECT DISTINCT a.id AS orderid
       , b.category
       , b.reason AS reorder_reason
       , b.reordered_order_id
       , b.order_id--
        --b.created_at AS reorder_date--,
       -- c.id AS reseller_fk,
       -- c.name AS reseller_name 
    FROM orders a
    -- multiple reorder id for an order, unsure how to filter AS these fields are not in truth.fact_orders table/truth schema
    LEFT JOIN reorder_details b
      ON a.id = b.order_id
)
    
, order_units AS (
  SELECT DISTINCT a.id AS order_id 
       , COUNT(DISTINCT b.id) AS no_of_units
    FROM orders a
    LEFT JOIN order_items b
      ON a.id = b.order_id
   GROUP BY a.id
)
  
, order_status AS (
  SELECT a.id AS id 
       , CASE
            WHEN a.state != 'canceled' 
                AND a.payment_state = 'paid' 
                AND a.completed_at IS NOT NULL 
                AND NOT (max(b.order_id)) IS NOT NULL
            THEN true
            ELSE false
         END AS is_completed
       , CASE WHEN a.state = 'canceled' THEN true ELSE false END AS is_canceled
       , CASE WHEN max(b.order_id) IS NOT NULL THEN true ELSE false END AS is_reorder
       , CASE WHEN a.payment_state = 'paid' THEN true ELSE false END AS is_paid
       , CASE WHEN COALESCE(d.position, 1) = 1 THEN true ELSE false END AS is_first
       , CASE WHEN d.position = 2 THEN true ELSE false END AS is_second
       , CASE WHEN d.position > 1 THEN true ELSE false END AS is_repeat
       , CASE WHEN d.position > 1 THEN true ELSE false END AS is_addon
       , CASE WHEN min(c.shipped_at) IS NOT NULL THEN true ELSE false END AS is_shipped
       , c.tracking
       , d.position AS order_rank
       , e.max_order_rank
       , e.order_before_last
    FROM orders a
    LEFT JOIN reorder_details b
      ON a.id = b.order_id
    LEFT JOIN shipments c
      ON a.id = c.order_id
    LEFT JOIN order_position d
      ON a.id = d.id
    LEFT JOIN product_analytics e
      ON a.id = e.id
    GROUP BY 
        a.id, 
        a.state,
        a.payment_state,
        a.completed_at,
        c.tracking,
        d.position,
        e.max_order_rank,
        e.order_before_last
)
 
, finance AS (
  SELECT order_number
       , order_item_id
       , COALESCE(SUM(a.gross_revenue), 0) AS gross_revenue_item
       , COALESCE(SUM(a.discount), 0) AS discount
       , COALESCE(SUM(a.adjustment), 0) AS adjustment
       , COALESCE(SUM(a.revenue_post_discount), 0) AS revenue_post_discount
       , COALESCE(SUM(a.revenue_post_adjustments), 0) AS revenue_post_adjustments
       , (SUM(a.gross_revenue) - SUM(a.discount) - SUM(a.reorders) + SUM(a.adjustment) + SUM(a.tax)) AS tax_on_revenue
       , COALESCE(SUM(a.net_revenue), 0) AS net_revenue
       , COALESCE(SUM(a.refunds), 0) AS refunds
       , (SUM(a.refunds) - SUM(a.tax)) AS tax_on_refunds
       , (SUM(a.net_revenue) - SUM(a.refunds) - SUM(a.reorders)) AS net_revenue_post_refunds
        --cost_per_unit_cogs, unsure how this is calculated
       , COALESCE(SUM(a.net_revenue_shipping), 0) AS net_revenue_shipping
       , COALESCE(SUM(a.local_net_revenue_shipping), 0) AS local_net_revenue_shipping
       , COALESCE(SUM(a.payment_fees), 0) AS payment_fees

        , COALESCE(SUM(a.gross_profit_old), 0) AS gross_profit_old
       , COALESCE(SUM(a.gross_profit_new), 0) AS gross_profit_new
       , COALESCE(SUM(a.bracketed_shipments_cost), 0) AS bracketed_shipments_cost
       , COALESCE(SUM(a.local_bracketed_shipments_cost), 0) AS local_bracketed_shipments_cost
       ,max(weight_in_grams) as weight_in_grams
       ,max(weight_ratio) as weight_ratio
       ,max(uses_new_braketed_rates) as uses_new_braketed_rates
       , COALESCE(SUM(cogs_inbound_logistics_costs), 0) as cogs_inbound_logistics_costs
       , COALESCE(SUM(cogs_storage_costs), 0) as cogs_storage_costs

       , COALESCE(SUM(a.tax), 0) AS tax
       , COALESCE(SUM(a.shipments_cost), 0) AS shipments_cost
       , COALESCE(SUM(a.unit_cogs), 0) AS unit_cogs
       , COALESCE(SUM(a.order_cogs), 0) AS order_cogs
       , COALESCE(SUM(a.store_credit), 0) AS store_credit
        --  ( (SUM(a.local_income) - SUM(a.local_cost))  /  NULLIF((SUM(a.income) - SUM(a.cost)), 0) ) AS average_fx_rate    
       , COALESCE(SUM(local_income), 0) AS local_income
       , COALESCE(SUM(local_cost), 0) AS local_cost
       , COALESCE(SUM(income), 0) AS income
       , COALESCE(SUM(cost), 0) AS cost
       , COALESCE(SUM(a.royalty_fees), 0) AS royalty_fees

       , COALESCE(SUM(case when unit_type = 'product' then a.net_revenue_product else 0 end), 0) as net_revenue_product
       , COALESCE(SUM(case when unit_type = 'giftwrap' then a.net_revenue_giftwrap else 0 end), 0) as net_revenue_giftwrap
       , COALESCE(SUM(case when unit_type = 'dedication_photo_upload' then a.net_revenue_photo else 0 end), 0) as net_revenue_photo
       , COALESCE(SUM(case when unit_type = 'cover_style' then a.net_revenue_cover else 0 end), 0) as net_revenue_cover
       , COALESCE(SUM(case when unit_type = 'edition' then a.net_revenue_edition else 0 end), 0) as net_revenue_edition

       , COALESCE(SUM(case when unit_type = 'product' then a.gross_revenue_product else 0 end), 0) as gross_revenue_product
       , COALESCE(SUM(case when unit_type = 'giftwrap' then a.gross_revenue_giftwrap else 0 end), 0) as gross_revenue_giftwrap
       , COALESCE(SUM(case when unit_type = 'dedication_photo_upload' then a.gross_revenue_photo else 0 end), 0) as gross_revenue_photo
       , COALESCE(SUM(case when unit_type = 'cover_style' then a.gross_revenue_cover else 0 end), 0) as gross_revenue_cover
       , COALESCE(SUM(case when unit_type = 'edition' then a.gross_revenue_edition else 0 end), 0) as gross_revenue_edition

       , COALESCE(SUM(case when unit_type = 'product' then a.unit_cogs_product else 0 end), 0) as unit_cogs_product
       , COALESCE(SUM(case when unit_type = 'giftwrap' then a.unit_cogs_giftwrap else 0 end), 0) as unit_cogs_giftwrap
       , COALESCE(SUM(case when unit_type = 'dedication_photo_upload' then a.unit_cogs_photo else 0 end), 0) as unit_cogs_photo
       , COALESCE(SUM(case when unit_type = 'cover_style' then a.unit_cogs_cover else 0 end), 0) as unit_cogs_cover
       , COALESCE(SUM(case when unit_type = 'edition' then a.unit_cogs_edition else 0 end), 0) as unit_cogs_edition
       
    FROM unit_profit_and_loss a
   GROUP BY order_number, order_item_id
)

, temp_dedications AS (
  SELECT DISTINCT ORDER_ITEM_ID AS LINE_ITEM_ID
       , REGEXP_REPLACE(inscription, '[^\\w\\s]', '') AS remove_punctuation
       , REPLACE(remove_punctuation, '\n', ' ')       AS remove_newline
       , LOWER(remove_newline)                        AS lower_cased
       , REGEXP_REPLACE(lower_cased, '\\s+', ' ')     AS clean_inscription
       , ROW_NUMBER() OVER (PARTITION BY LINE_ITEM_ID order by inscription) AS rn 
    FROM int_dedications
)

, dedications AS (
  SELECT DISTINCT LINE_ITEM_ID
       , clean_inscription
    FROM temp_dedications
   WHERE rn = 1
)
  
, order_item_aggregates AS (
  SELECT o.id
       , COUNT(oi.id) AS item_count
    FROM orders o
    JOIN order_items oi 
      ON o.id = oi.order_id
   GROUP BY 1
)

, temp_payment AS (
  SELECT order_id
       , paid_at
       , payment_provider
       , payment_method
       , refund_date
       , row_number() OVER (PARTITION BY order_id ORDER BY paid_at ASC, refund_date ASC) AS rn
    FROM int_payment a
)

         -- 05/05/2020 AS: originally created by Minoro this CTE didn't pull through rates when joined to order table.
, payment AS (
  --04/05/2020 AS: improved code provided by Roni
 SELECT order_id
      , paid_at
      , payment_provider
      , payment_method
      , refund_date
   FROM temp_payment
  WHERE rn=1 
)


-- User 987e701e970f3b54c7efa375294df75e is a lady in Singapore that orders in bulk and doesn't pay through the website,
--so no revenue ever gets assigned to her orders.
, user_flag AS (
  SELECT o.user_fk
       , o.id AS order_id -- added order_id so that we can join straight to this
       , email
       , CASE WHEN email LIKE '%wonderbly%' OR o.user_fk = '987e701e970f3b54c7efa375294df75e' then true else false end AS is_employee
    FROM temp_orders o
    LEFT JOIN temp_users ts 
      ON o.user_fk = ts.user_id
)

SELECT DISTINCT s.id AS order_item_id
     , a.number AS order_number
     , a.id AS order_id 
      -- b.id AS user_id
     , b.user_fk AS user_id
     , a.user_id AS eagle_user_id
     , c.bill_country_id
     , c.bill_address_id 
     , c.bill_address_1 
     , c.bill_address_2
     , c.bill_address_city
     , c.bill_address_state
     , c.bill_country
     , c.bill_address_zipcode
     , d.ship_country_id
     , d.ship_address_id 
     , d.ship_address_1
     , d.ship_address_2
     , d.ship_address_city
     , d.ship_address_state
     , d.ship_country
     , d.ship_address_zipcode
     , d.shipping_type
     , d.shipping_code
     , d.shipping_id
      --d.order_weight   
     , e.printhouse_name
     , e.address1 AS printhouse_address_1
     , e.address2 AS printhouse_address_2
     , e.city AS printhouse_city
     , e.zipcode AS printhouse_zipcode
     , e.country AS printhouse_country
     , g.promotion_code
     , g.promotion_category
     , sp.code AS shipping_promo
     , g.label
     , u.referrer_fk
     , a.currency AS currency
     , m.rate
     , m.data_type AS fx_rate_flag
     , a.completed_at::DATE AS ordered_date
     , a.completed_at AS ordered_at
     , a.process_at AS uploaded_at 
     , d.shipped_date
     , d.shipped_at
     , d.expected_delivery_date
     , d.expected_shipping_date
     , d.expected_shipping_date_local
     , d.timezone_adjustment
     , d.shipped_at_local 
     , h.paid_at::date AS paid_date
     , h.paid_at
     , h.refund_date AS refund_date
     , k.is_completed AS is_completed
     , k.is_canceled AS is_canceled
     , k.is_reorder AS is_reorder
     , k.is_paid AS is_paid
     , k.is_first
     , k.is_second
     , k.is_repeat
     , k.is_shipped
     , k.tracking
     , CASE WHEN h.payment_provider = 'Reseller' THEN TRUE ELSE FALSE END AS is_imported
     , k.order_rank
     , k.max_order_rank
     , k.order_before_last
     , h.payment_provider
     , h.payment_method
     , er.id AS reseller_fk
     , er.name AS reseller_name
     , a.reseller_order_number
     , a.item_count AS basket_size
     , d.days_to_ship
     , t.product_type AS product_Type
     , q.no_of_units
     , k.is_addon
     , eto.gift_wrap
     , r.net_revenue_shipping
     , r.local_net_revenue_shipping
     , r.gross_revenue_item
     , r.discount AS discount
     , r.adjustment AS adjustment
     , r.store_credit AS store_credit
     , r.revenue_post_discount AS revenue_post_discount
     , r.revenue_post_adjustments AS revenue_post_adjustments
     , r.tax_on_revenue AS tax_on_revenue
     , r.net_revenue AS net_revenue
     , r.net_revenue_product
     , r.net_revenue_giftwrap
     , r.net_revenue_photo
     , r.net_revenue_cover
     , r.net_revenue_edition
     , r.gross_revenue_product
     , r.gross_revenue_giftwrap
     , r.gross_revenue_photo
     , r.gross_revenue_cover
     , r.gross_revenue_edition
     , r.refunds AS refunds
     , r.tax_on_refunds AS tax_on_refunds
     , r.net_revenue_post_refunds AS net_revenue_post_refunds
     , r.shipments_cost AS shipments_cost
     , r.unit_cogs
     , r.order_cogs
     , r.payment_fees AS payment_Fees
     , r.tax AS tax
     , r.local_income
     , r.local_cost
     , r.income
     , r.cost
     , t.sku AS SKU
     , t.product_name AS product_name
     , t.cover
     , t.language
     , t.format
     , t.weight
     , i.category AS re_order_type
     , i.reorder_reason
     , t.sku_launch_date
     , t.sku_launch_year
     , t.brand_launch_year
     , t.brand
     , t.series
     , t.grown_up
     , t.series_launch_year
     , t.series_launch_date
     , t.variant_launch_date
     , t.sub_product_type
     , t.sub_category
     , t.category
     , t.retail_category
     , t.retail_sub_category
     , t.evergreen_occasion_sub_cat
     , t.trading_category
     , t.title_grouping
     , first_value(case when t.product_type not in ('Book', 'personalised-book') then null else t.category end) ignore nulls over(partition by a.number order by position asc) AS order_generating_category
     , RANK () over (partition by a.number order by (case when t.product_type in ('Book', 'personalised-book') then position else null end) asc nulls last) = 1 AS order_generating_item
     , t.illustrator
     , t.author
     , t.variant
     , t.brand_launch_date
     , t.page_count
     , t.page_bucket
     , t.size
     , max(CASE WHEN t.size like '%jumbo:hardback%' or t.size like '%jumbo:layflat%' THEN 'Yes' ELSE 'No' END) OVER(PARTITION BY a.number) as format_flag
     , de.clean_inscription
     , uf.is_employee
     , uf.email
     , eto.position

     ,CASE WHEN MAX(CASE WHEN r.discount > 0 THEN 1 ELSE 0 END)
         OVER (PARTITION BY a.id) = 1
     THEN 'Yes'
     ELSE 'No'
     END AS has_discount

    ,r.weight_in_grams
    ,r.weight_ratio
    ,r.local_bracketed_shipments_cost
    ,r.bracketed_shipments_cost
    ,r.uses_new_braketed_rates
    ,r.cogs_storage_costs
    ,r.cogs_inbound_logistics_costs

    ,r.gross_profit_new as gross_profit
    ,r.gross_profit_old
    ,r.royalty_fees AS royalty_fees

    ,INITCAP(b.opt_in_status) AS opt_in_status

    , r.unit_cogs_product
    , r.unit_cogs_giftwrap
    , r.unit_cogs_photo
    , r.unit_cogs_cover
    , r.unit_cogs_edition

    , d.us_state_speed

    ,eto.giftbox_sku
  FROM orders a
  JOIN order_items s
    ON a.id = s.order_id   
  JOIN days
    ON DATE_TRUNC('day', a.completed_at) = DATE_TRUNC('day', days.date)  
  LEFT JOIN temp_orders b
    ON a.id = b.id

  LEFT JOIN user_flag uf -- duplicates
    ON a.id = uf.order_id
  LEFT JOIN billing_address c
-- 24/11/2020 AS: we replace missing billing address with shipping address
    ON COALESCE(a.bill_address_id, a.ship_address_id) = c.bill_address_id 
  LEFT JOIN shipping_address d -- duplicates
    ON a.id = d.ORDER_ID
  LEFT JOIN print_house e
    ON d.printhouse_id = e.id
  LEFT JOIN promotions g
-- 04/05/2021 AS: changed join to populate promo code for each order item
--on s.id = g.id
    ON a.id = g.order_id 

  LEFT JOIN shipping_promo sp
    ON a.id = sp.order_id

  LEFT JOIN payment h
-- 14/10/2020 AS: join on s.id is incorrect
--on s.id = h.order_id
    ON s.order_id = h.order_id
         -- 04/05/2020 AS: added direct join to payments table
         --left join bi.dw.payment h
        -- on a.id = h.order_id
  LEFT JOIN reorders i
    ON a.id = i.order_id
             --17/07/2020 AS: resellers were added in reorder cte that filtered out a lot of resellers
  LEFT JOIN resellers er
    ON a.reseller_id = er.id
  LEFT JOIN order_status k -- duplicates
    ON a.id = k.id 
  LEFT JOIN fx m
--on h.paid_at::DATE = m.date and a.currency = m.currency -- payment date join create duplicate fx rates for the same order date
    ON a.completed_at::DATE = m.date 
   AND a.currency = m.currency 
  LEFT JOIN order_units q
    ON a.id = q.order_id 
  LEFT JOIN finance r
    ON s.id = r.order_item_id
  LEFT JOIN product_data t
    ON s.id = t.id
  LEFT JOIN dedications de
    ON s.id = de.LINE_ITEM_ID
  LEFT JOIN order_referrals u 
    ON a.id = u.order_id
  LEFT JOIN order_item_aggregates v
    ON a.id = v.id 
  LEFT JOIN eagle_transform_order_items eto 
    ON s.order_id = eto.order_id
   AND s.id = eto.id -- duplication wAS introduced by this final step. order items table joined on order_id - added the order_item level join to ensure duplicates not geenrated. AT 2020-06-07
 WHERE a.number NOT IN (
        --bugged orders
        SELECT order_number FROM excluded_orders where order_number is not null
        UNION
        --ww
        SELECT number AS order_number FROM ww_orders where number is not null
        UNION
        --SG
        SELECT number AS order_number FROM sg_orders where number is not null
        UNION
        --FP
        SELECT number AS order_number FROM fp_orders where number is not null
        UNION
		--HN
		SELECT number as order_number FROM hn_orders WHERE number IS NOT NULL
        UNION
        --Plucky
        SELECT number as order_number FROM plucky_orders WHERE number IS NOT NULL
       )
   AND v.item_count > 0