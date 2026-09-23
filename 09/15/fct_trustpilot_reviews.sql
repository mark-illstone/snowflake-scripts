create or replace table bi.mark_dev.fct_trustpilot_reviews as

with company_reviews as (select * from bi.fivetran_trustpilot_2.business_unit_all_review)
    ,product_reviews as (select * from bi.fivetran_trustpilot_2.private_product_review)
    ,products as (select * from bi.fivetran_trustpilot_2.private_business_unit_product)
    ,sku_mapping as (select * from bi.google_sheets.skus_mapping)
    ,product_categories as (select * from bi.google_sheets.product_categories)

    ,sku_mapping_temp as
    (
        select
             slug
            ,brand
            ,case when slug like '%grandad%' then 'grandad' else retail_sub_category end as retail_sub_category
            ,trading_category
        from sku_mapping
        where slug is not null
        group by all
    )

select 
     'company'           as review_type
    ,id                  as review_id
    ,consumer_id         as consumer_id
    ,stars               as stars
    ,null                as order_number
    ,review_language     as review_language
    ,created_at          as created_at
    ,null                as product_sku
    ,null                as product_title
    ,null                as product_slug
    ,null                as brand
    ,null                as retail_category
    ,null                as retail_sub_category
    ,null                as trading_category
    ,null                as evergreen_occasion
    ,null                as evergreen_occasion_sub_cat
    ,null                as keepsake_kids
    ,null                as keepsake_kids_sub_cat
    ,null                as theme
from company_reviews

union all

select 
     'product'                      as review_type
    ,a.id                           as review_id
    ,a.consumer_id                  as consumer_id
    ,a.stars                        as starts
    ,a.reference_id                 as order_number
    ,a.languages                    as review_language
    ,a.created_at                   as created_at
    ,d.sku                          as product_sku
    ,d.title                        as product_title
    ,case when split_part(split_part(d.link, '/', -1), '?', 1) = 'null' then null else split_part(split_part(d.link, '/', -1), '?', 1) end as product_slug
    ,e.brand                        as brand
    ,f.retail_category              as retail_category
    ,e.retail_sub_category          as retail_sub_category
    ,e.trading_category             as trading_category
    ,f.evergreen_occasion           as evergreen_occasion
    ,f.evergreen_occasion_sub_cat   as evergreen_occasion_sub_cat
    ,f.keepsake_kids                as keepsake_kids
    ,f.keepsake_kids_sub_cat        as keepsake_kids_sub_cat
    ,f.theme                        as theme
from product_reviews a
    left join products d
        on a.product_id = d.id
    left join sku_mapping_temp e
        on product_slug = e.slug
    left join product_categories f
        on e.brand = f.brand