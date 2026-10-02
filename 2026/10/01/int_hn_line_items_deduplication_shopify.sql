

WITH order_items AS (SELECT * FROM bi.fivetran_shopify_test_19.order_line)
    ,product AS (SELECT * FROM bi.fivetran_shopify_test_19.product)
    ,product_variant AS (SELECT * FROM bi.fivetran_shopify_test_19.product_variant)
    ,metafield AS (SELECT * FROM bi.fivetran_shopify_test_19.metafield)

    ,refund AS (SELECT * FROM bi.fivetran_shopify_test_19.order_line_refund)
    ,fulfillment as (select * from bi.fivetran_shopify_test_19.fulfillment_order_line)

    ,metaobject as (select * from bi.google_sheets.hn_shopify_metaobjects)

    ,licenced_upsell as (select * from bi.historical_newspapers_shopify.int_incremental_licenced_upsell)

         ,extracted_properties AS (
    SELECT 
        id,
        order_id,
        MAX(CASE WHEN value:"name"::STRING = 'Media Code' THEN value:"value"::STRING ELSE NULL END) AS media_code,
        MAX(CASE WHEN value:"name"::STRING = 'Newspaper Date' THEN value:"value"::STRING ELSE NULL END) AS newspaper_date,
        MAX(CASE WHEN value:"name"::STRING = 'Newspaper Title' THEN value:"value"::STRING ELSE NULL END) AS newspaper_title,
        MAX(CASE WHEN value:"name"::STRING = 'customisation.locale' THEN value:"value"::STRING ELSE NULL END) AS customisation_locale,
        MAX(CASE WHEN value:"name"::STRING = '_addon_id' THEN value:"value"::STRING ELSE NULL END) AS addon_id,
        MAX(CASE WHEN value:"name"::STRING = 'customisation.cover_colour' THEN value:"value"::STRING ELSE NULL END) AS cover_colour,
        MAX(CASE WHEN value:"name"::STRING = 'customisation.cover_design' THEN value:"value"::STRING ELSE NULL END) AS cover_design,
        MAX(CASE WHEN value:"name"::STRING = 'Newspaper Origin' THEN value:"value"::STRING ELSE NULL END) AS newspaper_origin
    FROM order_items,
    LATERAL FLATTEN(input => properties) AS js
    GROUP BY id, order_id
)

    ,extracted_currency as (
SELECT id,
       order_id,
       PARSE_JSON(price_set):presentment_money.currency_code::STRING AS local_currency,
       PARSE_JSON(price_set):presentment_money.amount::DOUBLE AS local_price
FROM order_items
)

    ,categories as (
    select b.value as category_value
      ,b.category_name
      ,b.id
      ,owner_id
      ,a.key
    from metafield a
    inner join metaobject b on to_varchar(REVERSE(SPLIT_PART(REVERSE(a.value), '/', 1))) = to_varchar(b.id)
)

SELECT 
        ol.order_id::integer as order_id,
        ol.id::varchar as line_item_id,
        ol.product_id::integer as product_id,
        ol.variant_id::integer as variant_id,
        ol.name::varchar as name,
        ol.title::varchar as title,
        ol.vendor::varchar as vendor,
        ec.local_currency as local_currency,
        ol.price::double as price,
        ec.local_price::double as local_price,
        ol.grams::integer as grams,
        coalesce(v.sku::varchar, ol.sku::varchar) as sku,
        ol.gift_card::varchar as gift_card,
        ol.requires_shipping::varchar as requires_shipping,
        ol.taxable::varchar as taxable,
        ol.variant_title::varchar as cover_type,
        ol.product_exists::varchar as product_exists,
        ol.fulfillment_status::varchar as fulfillment_status,
        ol.tax_code::varchar as tax_code,
        ol.quantity::integer as quantity,
        ep.media_code, 
        ep.newspaper_date,
        ep.newspaper_title,
        case 
            when ep.newspaper_date is not null
                and (ep.newspaper_origin is null or lower(ep.newspaper_origin) = 'undefined')
            then ep.customisation_locale   
            else ep.newspaper_origin
        end as newspaper_origin,
        ep.addon_id,
        p.template_suffix::varchar as category, 
        m.value::varchar as royaltor,
        m2.value::varchar as page_count,
        case when ol.title::varchar = 'Original Newspapers' then 'Original Newspapers'
             when coalesce(v.sku::varchar, ol.sku::varchar) like '%alcohol%' then 'Alcohol'
             else c.category_value
        end as primary_category,
        c2.category_value as sports_category,
        c3.category_value as theme_category,
        case when primary_category is null then null 
            when primary_category = 'Sports' then sports_category 
            when primary_category = 'Theme' then theme_category 
            else 'Date' 
        end as secondary_category,
        c4.category_value as sports_team,
        c5.category_value as newspaper_brand,
        p.product_type::varchar as product_type, 
        m3.value::varchar as product_launch_date,
        initcap(ep.cover_colour::varchar) as cover_colour,
        initcap(ep.cover_design::varchar) as cover_design,
        case when coalesce(v.sku, ol.sku) like 'hn%' 
            then initcap(substr(ol.sku, length(ol.sku) - charindex( ':', reverse(ol.sku))+2, charindex( ':', reverse(ol.sku))))
        end as product_format,
        refund.order_line_id as refund_order_line_id,
        fulfillment.order_line_id as fulfillment_order_line_id,
        v.price as rrp,
        lu.addon_deluxe_licencee as product_additional_licenced_content,
        lu.cover_licencee as product_variant_additional_licenced_content,
        ol.index
FROM order_items ol
left join product p on ol.product_id = p.id
left join product_variant v on ol.variant_id = v.id
LEFT JOIN extracted_properties ep ON ol.id = ep.id AND ol.order_id = ep.order_id
LEFT JOIN extracted_currency ec ON ol.id = ec.id and ol.order_id = ec.order_id
left join metafield m on m.owner_id = p.id and m.key = 'royaltor'
left join metafield m2 on m2.owner_id = p.id and m2.key = 'page_count'
left join metafield m3 on m3.owner_id = p.id and m3.key = 'product_launch_date'
--left join metafield m4 on m4.owner_id = p.id and m4.key = 'additional_licensed_content' and m4.owner_resource = 'PRODUCT'
--left join metafield m5 on m5.owner_id = v.id and m5.key = 'additional_licensed_content' and m5.owner_resource = 'PRODUCTVARIANT'
LEFT JOIN refund on refund.order_line_id = ol.id
LEFT JOIN fulfillment on fulfillment.order_line_id = ol.id
left join categories c on p.id = c.owner_id and c.key = 'primary_category'
left join categories c2 on p.id = c2.owner_id and c2.key = 'sports_category'
left join categories c3 on p.id = c3.owner_id and c3.key = 'theme_category'
left join categories c4 on p.id = c4.owner_id and c4.key = 'sports_team'
left join categories c5 on p.id = c5.owner_id and c5.key = 'newspaper_brand'
left join licenced_upsell lu on ol.id = lu.line_item_id
where ol.name not in ('No Presentation Box', 'No Alcohol')
--and not (refund.order_line_id is not null and fulfillment.order_line_id is null)