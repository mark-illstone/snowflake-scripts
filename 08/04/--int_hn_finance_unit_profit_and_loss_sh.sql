--int_hn_finance_unit_profit_and_loss_shopify_04082026

create or replace table bi.mark_dev.int_finance_unit_profit_and_loss as


WITH finance_units AS (SELECT * FROM bi.historical_newspapers_shopify.int_finance_units)
     , cogs_by_format AS (SELECT * FROM bi.mark_dev.int_unit_cogs)
     , shipping_cogs AS (SELECT * FROM bi.historical_newspapers_shopify.int_unit_shipping_cogs)
     , payment_fees AS (SELECT * FROM bi.historical_newspapers_shopify.int_payment_fees)
     , royalty_fees AS (SELECT * FROM bi.historical_newspapers_shopify.int_finance_royalties)

, order_adjustment AS
(
SELECT 
    a.order_id,
   SUM(COALESCE(a.us_taxes, 0) 
            + COALESCE((((a.price + a.shipment_price) - a.discount) / ((100 + a.sales_taxes) / 100)) * (a.sales_taxes / 100), 0)) AS adjustment,
    SUM(COALESCE(a.vat_value, 0)) as vat_adjustment,
    SUM(COALESCE(a.us_taxes, 0)) as us_adjustment
FROM finance_units a
GROUP BY 1
)

, base_metrics AS (
    SELECT a.order_number
         , a.order_id
         , a.line_item_id
         , d.payment_provider
         , d.payment_credit_card_company
         , b.cogs_format
         , b.addon_cogs_format
         , a.discount
        -- , COALESCE(a.vat_value + a.us_taxes, 0) AS adjustment
         , COALESCE(a.vat_value, 0) as vat_value
         , COALESCE(a.us_taxes, 0) as us_taxes
         , COALESCE(a.discounted_shipment_price, 0) AS net_revenue_shipping
         , COALESCE(a.local_discounted_shipment_price, 0) AS local_net_revenue_shipping
         , a.local_price + COALESCE(a.local_shipment_price, 0) AS local_income
         , a.local_adjusted_price_without_addons
         , a.price + COALESCE(a.shipment_price, 0) AS income
         , a.rate
         , a.currency
         , COALESCE(b.unit_cost, 0) + COALESCE(b.order_cost, 0) + COALESCE(b.psp_box_cost, 0) + COALESCE(b.hn_box_cost, 0) + COALESCE(c.local_amount, 0) as production_cost
         , b.order_cost
         , b.unit_cost
         , b.psp_unit_cost 
         , b.hn_unit_cost
         , b.psp_fulfilment_cost 
         , b.psp_twistwrap_cost
         , b.hn_twistwrap_cost
         , b.psp_box_cost
         , b.hn_box_cost
         , b.hn_insert_cost

         , b.local_order_cost
         , b.local_unit_cost
         , b.local_psp_unit_cost 
         , b.local_hn_unit_cost
         , b.local_psp_fulfilment_cost 
         , b.local_psp_twistwrap_cost
         , b.local_hn_twistwrap_cost
         , b.local_psp_box_cost
         , b.local_hn_box_cost
         , b.local_hn_insert_cost
         , f.royalty_fees
         , f.local_royalty_fees
         , a.marketplace_fees
         , COALESCE(c.local_amount, 0) as shipping_cost
         ,(max(COALESCE(d.payment_fees, 0)) over (partition by a.order_number)
             * RATIO_TO_REPORT(nullif(a.ratio_to_order, 0)) OVER (PARTITION BY a.order_number)) as payment_fees
         , c.weight_in_grams
         , c.weight_ratio
         , c.shipping_type
         , c.carrier
         , d.paid_at
         , a.adjusted_price_without_addons
         , a.addon_price
         , a.local_addon_price
         , a.addon_deluxe_price
         , a.local_addon_deluxe_price

         , COALESCE(f.base_royalty_fees, 0)               as product_royalty_fees
         , COALESCE(f.cover_royalty_fees, 0)              as cover_royalty_fees
         , COALESCE(f.addon_deluxe_royalty_fees, 0)       as addon_deluxe_royalty_fees

         , COALESCE(f.local_base_royalty_fees, 0)         as local_product_royalty_fees
         , COALESCE(f.local_cover_royalty_fees, 0)        as local_cover_royalty_fees
         , COALESCE(f.local_addon_deluxe_royalty_fees, 0) as local_addon_deluxe_royalty_fees

         , COALESCE(f.cover_upsell, 0)                    as cover_upsell_price
         , COALESCE(f.local_cover_upsell, 0)              as local_cover_upsell_price

         , a.sales_taxes
         , (((a.price + COALESCE(a.shipment_price, 0)) - a.discount) / ((100 + a.sales_taxes) / 100)) * (a.sales_taxes / 100) AS sales_tax_amount
         , (((a.local_price + COALESCE(a.local_shipment_price, 0)) - a.local_discount) / ((100 + a.sales_taxes) / 100)) * (a.sales_taxes / 100) AS local_sales_tax_amount

         , a.rrp
         , a.local_rrp

         , a.usd_rate

         , a.local_discount
         , a.local_vat_value
         , a.local_us_taxes

         , (e.us_adjustment * product_ratio) + product_price                 - product_refund         as gross_revenue_product
         , (e.us_adjustment * giftbox_ratio) + giftbox_price                 - giftbox_refund         as gross_revenue_giftbox
         , (e.us_adjustment * deluxe_content_ratio) + deluxe_content_price   - deluxe_content_refund  as gross_revenue_deluxe_content
         , (e.us_adjustment * foil_cover_ratio) + foil_cover_price           - foil_cover_refund      as gross_revenue_foil_cover
         , (e.us_adjustment * pictorial_cover_ratio) + pictorial_cover_price - pictorial_cover_refund as gross_revenue_pictorial_cover
         
         , product_discount
         , giftbox_discount
         , deluxe_content_discount
         , foil_cover_discount
         , pictorial_cover_discount
         
        -- , (e.adjustment * product_ratio) + e.vat_adjustment  as product_adjustment
         , e.adjustment * product_ratio                       as product_adjustment
         , e.adjustment * giftbox_ratio                       as giftbox_adjustment
         , e.adjustment * deluxe_content_ratio                as deluxe_content_adjustment
         , e.adjustment * foil_cover_ratio                    as foil_cover_adjustment
         , e.adjustment * pictorial_cover_ratio               as pictorial_cover_adjustment

         , product_refund
         , giftbox_refund
         , deluxe_content_refund
         , foil_cover_refund
         , pictorial_cover_refund

         , a.shipment_price as gross_revenue_shipping

         , f.local_royalty_base_value
         , f.royalty_base_value
        
         
      FROM finance_units a
      join cogs_by_format b on a.line_item_id = b.line_item_id
      left join shipping_cogs c on a.order_id = c.order_id and a.line_item_id = c.line_item_id
      left join payment_fees d on a.order_number = d.order_number
      left join order_adjustment e on a.order_id = e.order_id
      left join royalty_fees f on a.line_item_id = f.line_item_id
      
)

, stacked_metrics AS (
    -- adjustments in this context are shipping or giftwrap other adjustments such as refunds have been filtered out.
    SELECT *
         , income - discount AS revenue_post_discount
         , income - discount - vat_value - us_taxes - sales_tax_amount AS net_revenue
         , local_income - local_discount - local_vat_value - local_us_taxes - local_sales_tax_amount AS local_net_revenue

         , gross_revenue_product         - product_discount         - product_adjustment - vat_value  AS net_revenue_product
         , gross_revenue_giftbox         - giftbox_discount         - giftbox_adjustment         AS net_revenue_giftbox
         , gross_revenue_deluxe_content  - deluxe_content_discount  - deluxe_content_adjustment  AS net_revenue_deluxe_content
         , gross_revenue_foil_cover      - foil_cover_discount      - foil_cover_adjustment      AS net_revenue_foil_cover
         , gross_revenue_pictorial_cover - pictorial_cover_discount - pictorial_cover_adjustment AS net_revenue_pictorial_cover
         
      FROM base_metrics
)

SELECT order_number
    , order_id
    , line_item_id
    , payment_provider
    , payment_credit_card_company
    , cogs_format
    , addon_cogs_format
    , income as gross_revenue
    , net_revenue - COALESCE(production_cost, 0) - COALESCE(payment_fees, 0) - COALESCE(royalty_fees, 0) - COALESCE(marketplace_fees, 0) AS gross_profit
    , discount
    , vat_value + us_taxes + sales_tax_amount as adjustment
    , revenue_post_discount
    , net_revenue
     , net_revenue_shipping
    , DIV0((net_revenue_shipping - shipping_cost), COALESCE(net_revenue_shipping, 0)) AS shipping_margin
    , shipping_cost
    , shipping_type
    , carrier
    , weight_in_grams
    , weight_ratio
    , local_net_revenue_shipping
    , local_income
    , local_adjusted_price_without_addons
    , income
    , rate
    , currency
    , unit_cost
    , order_cost
    , production_cost
    , payment_fees
    , psp_unit_cost 
    , hn_unit_cost
    , psp_fulfilment_cost 
    , psp_twistwrap_cost
    , hn_twistwrap_cost
    , psp_box_cost
    , hn_box_cost
    , hn_insert_cost

    , local_order_cost
    , local_unit_cost
    , local_psp_unit_cost 
    , local_hn_unit_cost
    , local_psp_fulfilment_cost 
    , local_psp_twistwrap_cost
    , local_hn_twistwrap_cost
    , local_psp_box_cost
    , local_hn_box_cost
    , local_hn_insert_cost
        
    , royalty_fees
    , local_royalty_fees
    , marketplace_fees
    , paid_at
    , adjusted_price_without_addons
    , addon_price
    , local_addon_price
    , addon_deluxe_price
    , local_addon_deluxe_price

    , product_royalty_fees
    , cover_royalty_fees
    , addon_deluxe_royalty_fees
    
    , local_product_royalty_fees
    , local_cover_royalty_fees
    , local_addon_deluxe_royalty_fees
   
    , cover_upsell_price
    , local_cover_upsell_price

    , rrp
    , local_rrp

    , usd_rate

    , local_net_revenue
    , local_discount
    , local_vat_value + local_us_taxes + local_sales_tax_amount as local_adjustment
    , local_sales_tax_amount

    , gross_revenue_product
    , gross_revenue_giftbox
    , gross_revenue_deluxe_content
    , gross_revenue_foil_cover
    , gross_revenue_pictorial_cover

    , net_revenue_product
    , net_revenue_giftbox
    , net_revenue_deluxe_content
    , net_revenue_foil_cover
    , net_revenue_pictorial_cover

    , gross_revenue_shipping

    , local_royalty_base_value
    , royalty_base_value
    
  FROM stacked_metrics