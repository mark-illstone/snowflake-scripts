

WITH line_items AS (SELECT * FROM bi.historical_newspapers_shopify.int_product_data)
, orders AS (SELECT * FROM bi.historical_newspapers_shopify.int_temp_orders) 
, fx AS (SELECT * FROM bi.dbt_production_intermediate.int_fx)
, royalty_matrix as (SELECT * FROM bi.google_sheets.hn_royalty_matrix)
, upsell_prices as (SELECT * FROM bi.google_sheets.hn_component_prices)
, finance_units as (SELECT * FROM bi.historical_newspapers_shopify.int_finance_units)


, temp as
  ( 
SELECT
    li.order_id,
    o.order_number,
    li.line_item_id,
    li.name,
    o.created_at,
    o.marketplace_tag,
   CASE 
        WHEN o.marketplace_tag IN ('ETSY' , 'NOTHS', 'AMAZONUK', 'AMAZONUS', 'AMAZUSP', 'HISAMAZ', 'HISAMAZP', 'HISEBAY', 'HISETSY', 'HISNOTHS') 
        THEN 'Marketplace'
        WHEN o.marketplace_tag IN ('HISTEL', 'HISMBI', 'UNCOM', 'LATS', 'NYDN', 'HISMIRROR', 'WASHPS') 
        THEN 'Trade'
        WHEN o.marketplace_tag IN ('AMAZUS', 'HISAMAZ') --Force these resellers to use selling price instead of RRP like the rest of MP resellers.
        THEN 'Retail'
        ELSE 'Retail'
    END AS reseller_channel,
    li.local_currency,
    coalesce(fx.rate, 1) as fx_rate,
    rm1.licensee_name as base_licensee,
    rm2.licensee_name as addon_deluxe_licensee,
    rm3.licensee_name as cover_licensee,    
    CASE 
        WHEN rm4.channel_override IS NOT NULL AND rm7.reseller_override IS     NULL THEN rm4.rate --channel override
        WHEN rm4.channel_override IS     NULL AND rm7.reseller_override IS NOT NULL THEN rm7.rate --reseller override
        ELSE rm1.rate 
    END AS base_royalty_rate,
    CASE 
        WHEN rm5.channel_override IS NOT NULL AND rm8.reseller_override IS     NULL THEN rm5.rate --channel override
        WHEN rm5.channel_override IS     NULL AND rm8.reseller_override IS NOT NULL THEN rm8.rate --reseller override
        ELSE rm2.rate 
    END AS addon_deluxe_royalty_rate,
    CASE 
        WHEN rm6.channel_override IS NOT NULL AND rm9.reseller_override IS     NULL THEN rm6.rate --channel override
        WHEN rm6.channel_override IS     NULL AND rm9.reseller_override IS NOT NULL THEN rm9.rate --reseller override
        ELSE rm3.rate 
    END AS cover_royalty_rate,
    CASE WHEN LOWER(o.promo_code) LIKE '%test%' OR LOWER(o.promo_code) LIKE '%sample%' THEN 0 ELSE 
        CASE WHEN LOWER(li.name) LIKE '%with picture%' AND rm3.licensee_name IS NOT NULL THEN up.pictorial - coalesce(fu.pictorial_cover_discount, 0) END  
    END AS cover_upsell,
    CASE 
        WHEN cover_licensee IS NOT NULL 
            AND cover_upsell IS NULL 
        THEN (SELECT pictorial FROM upsell_prices WHERE currency = 'GBP' QUALIFY effective_date_to = MAX(effective_date_to) OVER ()) * fx.rate
    ELSE cover_upsell
    END AS local_cover_upsell,
    CASE WHEN LOWER(o.promo_code) LIKE '%test%' OR LOWER(o.promo_code) LIKE '%sample%' THEN 0 ELSE li.local_addon_deluxe_price END AS local_addon_deluxe_value,
    CASE 
        WHEN reseller_channel = 'Retail' THEN rm1.retail_value_field
        WHEN reseller_channel = 'Marketplace' THEN rm1.marketplace_value_field
        WHEN reseller_channel = 'Trade' THEN rm1.trade_value_field
    END AS value_field,
    rm1.price_override_gbp,
    CASE WHEN lower(li.cover_type) LIKE '%with picture%' THEN up.pictorial END AS pictorial_value,
    CASE WHEN lower(li.cover_type) LIKE '%foil%' THEN up.foil END AS foil_value,
    CASE WHEN lower(li.cover_type) LIKE '%milestone%' THEN up.milestone END AS milestone_value,
    CASE WHEN lower(li.addon_deluxe_sku) IS NOT NULL THEN up.deluxe END AS deluxe_value,
    CASE WHEN LOWER(o.promo_code) LIKE '%test%' OR LOWER(o.promo_code) LIKE '%sample%' THEN 0 ELSE 
        CASE 
            WHEN rm1.price_override_gbp IS NOT NULL THEN (rm1.price_override_gbp * fx_rate) + (IFNULL(pictorial_value, 0) + IFNULL(foil_value, 0) + IFNULL(milestone_value, 0) + IFNULL(deluxe_value, 0))
            WHEN o.marketplace_tag in ('HISETSY', 'HISNOTHS') AND o.order_tag != 'UK' AND o.created_at > '2026-06-11 11:00:00.000' THEN fu.local_rrp + 10
            WHEN value_field = 'Sales Price' THEN fu.local_adjusted_price_without_addons
            WHEN value_field = 'RRP' THEN fu.local_rrp
        END
    END AS local_value,  
    CASE
        WHEN local_cover_upsell IS NOT NULL THEN local_value - local_cover_upsell
        ELSE local_value
    END AS local_base_value,
    CASE WHEN reseller_channel = 'Trade' AND base_licensee != 'Telegraph' AND rm7.reseller_override IS NULL
        THEN (local_base_value * base_royalty_rate) * 2 ELSE local_base_value * base_royalty_rate 
    END AS local_base_royalty_fees,
    CASE WHEN reseller_channel = 'Trade' AND base_licensee != 'Telegraph' AND rm8.reseller_override IS NULL
        THEN (local_cover_upsell * cover_royalty_rate) * 2 ELSE local_cover_upsell * cover_royalty_rate 
    END AS local_cover_royalty_fees,
    CASE WHEN reseller_channel = 'Trade' AND base_licensee != 'Telegraph' AND rm9.reseller_override IS NULL
        THEN (local_addon_deluxe_value * addon_deluxe_royalty_rate) * 2 ELSE local_addon_deluxe_value * addon_deluxe_royalty_rate 
    END AS local_addon_deluxe_royalty_fees
FROM
    line_items li
        LEFT JOIN orders o 
            ON li.order_id = o.order_id
            
        LEFT JOIN royalty_matrix rm1
            ON LOWER(li.royaltor) = LOWER(rm1.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm1.date_from, 'DD/MM/YYYY') AND TO_DATE(rm1.date_to, 'DD/MM/YYYY') AND rm1.channel_override IS NULL AND rm1.reseller_override IS NULL
        LEFT JOIN royalty_matrix rm2
            ON LOWER(li.addon_deluxe_licencee) = LOWER( rm2.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm2.date_from, 'DD/MM/YYYY') AND TO_DATE(rm2.date_to, 'DD/MM/YYYY') AND rm2.channel_override IS NULL AND rm2.reseller_override IS NULL
        LEFT JOIN royalty_matrix rm3
            ON LOWER(li.cover_licencee) = LOWER(rm3.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm3.date_from, 'DD/MM/YYYY') AND TO_DATE(rm3.date_to, 'DD/MM/YYYY') AND rm3.channel_override IS NULL AND rm3.reseller_override IS NULL

        --Channel Override
        LEFT JOIN royalty_matrix rm4
            ON LOWER(li.royaltor) = LOWER(rm4.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm4.date_from, 'DD/MM/YYYY') AND TO_DATE(rm4.date_to, 'DD/MM/YYYY') AND rm4.channel_override = reseller_channel AND rm4.reseller_override IS NULL
        LEFT JOIN royalty_matrix rm5
            ON LOWER(li.addon_deluxe_licencee) = LOWER(rm5.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm5.date_from, 'DD/MM/YYYY') AND TO_DATE(rm5.date_to, 'DD/MM/YYYY') AND rm5.channel_override = reseller_channel AND rm5.reseller_override IS NULL
        LEFT JOIN royalty_matrix rm6
            ON LOWER(li.cover_licencee) = LOWER(rm6.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm6.date_from, 'DD/MM/YYYY') AND TO_DATE(rm6.date_to, 'DD/MM/YYYY') AND rm6.channel_override = reseller_channel AND rm6.reseller_override IS NULL

        --Reseller Override
        LEFT JOIN royalty_matrix rm7
            ON LOWER(li.royaltor) = LOWER(rm7.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm7.date_from, 'DD/MM/YYYY') AND TO_DATE(rm7.date_to, 'DD/MM/YYYY') AND rm7.channel_override IS NULL AND rm7.reseller_override = o.marketplace_tag
        LEFT JOIN royalty_matrix rm8
            ON LOWER(li.addon_deluxe_licencee) = LOWER(rm8.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm8.date_from, 'DD/MM/YYYY') AND TO_DATE(rm8.date_to, 'DD/MM/YYYY') AND rm8.channel_override IS NULL AND rm8.reseller_override = o.marketplace_tag
        LEFT JOIN royalty_matrix rm9
            ON LOWER(li.cover_licencee) = LOWER(rm9.licensee_name)
                AND o.created_at BETWEEN TO_DATE(rm9.date_from, 'DD/MM/YYYY') AND TO_DATE(rm9.date_to, 'DD/MM/YYYY') AND rm9.channel_override IS NULL AND rm9.reseller_override = o.marketplace_tag
                
        LEFT JOIN fx
            ON li.local_currency = fx.currency
                AND o.created_at::date = fx.date
        LEFT JOIN upsell_prices up
            ON  li.local_currency = up.currency
                AND o.created_at BETWEEN TO_DATE(up.effective_date_from, 'DD/MM/YYYY') AND TO_DATE(up.effective_date_to, 'DD/MM/YYYY')
        LEFT JOIN finance_units fu
            ON li.line_item_id = fu.line_item_id 
        
        )

    SELECT
    
        line_item_id,
        
        base_licensee,
        addon_deluxe_licensee,
        cover_licensee,
        
        COALESCE(local_base_royalty_fees, 0) as local_base_royalty_fees,
        COALESCE(local_cover_royalty_fees, 0) as local_cover_royalty_fees,
        COALESCE(local_addon_deluxe_royalty_fees, 0) as local_addon_deluxe_royalty_fees,

        COALESCE(local_base_royalty_fees, 0) / fx_rate as base_royalty_fees,
        COALESCE(local_cover_royalty_fees, 0) / fx_rate as cover_royalty_fees,
        COALESCE(local_addon_deluxe_royalty_fees, 0) / fx_rate as addon_deluxe_royalty_fees,

        COALESCE(local_base_royalty_fees, 0) + COALESCE(local_cover_royalty_fees, 0) + COALESCE(local_addon_deluxe_royalty_fees, 0) as local_royalty_fees,
        COALESCE(base_royalty_fees, 0) + COALESCE(cover_royalty_fees, 0) + COALESCE(addon_deluxe_royalty_fees, 0) as royalty_fees,

        cover_upsell,
        local_cover_upsell,

        local_base_value as local_royalty_base_value,
        COALESCE(local_base_value, 0) / fx_rate as royalty_base_value
            
    FROM temp

    qualify row_number() over(partition by line_item_id order by line_item_id) = 1