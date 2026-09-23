create or replace table bi.mark_dev.fct_marketing_attribution as

WITH ad_performance_fact AS (SELECT * FROM bi.mark_dev.fct_ad_performance where attribution_model = 'last_click_28d_interactions')
   , ads AS (SELECT * FROM bi.dbt_production_intermediate.int_attribution_ads)
   , dim_countries AS (SELECT * FROM bi.dbt_production_models.dim_countries)

-- Base data
    ,base_data as (
    select 
         c.name as country
       , case 
            when (a.channel in ('Social Paid', 'TikTok') and a.campaign_name like 'CRM_%') 
                 or customer_type = 'repeat' then 'Repeat'
            when customer_type = 'new' then 'New'
            else customer_type
         end as customer_type_tableau
       , null as customer_type_ga
       , customer_type as customer_type_attribution
       , to_date(interaction_day::varchar,'YYYYMMDD') as date
       , attribution_model
       , null as attribution_type
       , fa.ad_key
       , channel
       , channel_groups
       , top_level_channel_groups
       , channel_type
       , channel_paid_or_unpaid
       , partner
       , account_id
       , account_name
       , campaign_name
       , email_type
       , ad_group_id
       , ad_group_name
       , ad_id
       , ad_name
       , impressions
       , number_of_sessions as interactions
       , cost
       , conversions
       , net_revenue as revenue
       , older_kids_revenue
       , early_years_revenue
       , hybrid_family_revenue
       , adult_gift_revenue
       , picture_book_revenue
       , addon_gift_book_revenue
       , addon_gift_revenue
       , baby_revenue
       , reached_personalisation
       , kids_revenue
       , adult_revenue
       , gross_profit
       , clicks
       , contribution
       , commission
       , keyword_name
       , case 
            when to_date(interaction_day::varchar,'YYYYMMDD') >= '2024-10-19' 
                 and (campaign_name like '%HTAMN%' or ad_name like '%HTMN%')
                 then 'Core' 
            when to_date(interaction_day::varchar,'YYYYMMDD') >= '2025-06-01' 
                 then 'Core' 
            else campaign_book_category 
         end as campaign_book_category
       , campaign_book_sub_category
       , fa.state
       , trading_category
    from ad_performance_fact fa
    join ads a on a.ad_key = fa.ad_key
    left join dim_countries c on c.key = fa.country_fk
)

-- Aggregate totals by date/country/model
,unknown_totals as (
    select date, attribution_model, country, sum(revenue) as total_revenue, sum(gross_profit)as total_gross_profit,
    sum(conversions) as total_conversions
    from base_data
    where channel = 'Unknown'
    group by 1,2,3
)

,known_totals as (
    select date, attribution_model, country, sum(revenue) as total_revenue, sum(gross_profit)as total_gross_profit,
    sum(conversions) as total_conversions
    from base_data
    where channel <> 'Unknown'
    group by 1,2,3
)

-- Final redistribution logic
,final as (
    select
        bd.country,
        bd.customer_type_tableau,
        bd.customer_type_ga,
        bd.customer_type_attribution,
        bd.date,
        bd.attribution_model,
        bd.attribution_type,
        bd.ad_key,
        bd.channel,
        bd.channel_groups,
        bd.top_level_channel_groups,
        bd.channel_type,
        bd.channel_paid_or_unpaid,
        bd.partner,
        bd.account_id,
        bd.account_name,
        bd.campaign_name,
        bd.email_type,
        bd.ad_group_id,
        bd.ad_group_name,
        bd.ad_id,
        bd.ad_name,
        bd.impressions,
        bd.interactions,
        bd.cost,
                        case 
            when bd.channel = 'Unknown' then 0
            else bd.conversions 
                 + coalesce(
                       ut.total_conversions * bd.conversions / nullif(kt.total_conversions,0),
                       0
                   )
        end as conversions,

        -- Revenue redistribution
        case 
            when bd.channel = 'Unknown' then 0
            else bd.revenue 
                 + coalesce(
                       ut.total_revenue * bd.revenue / nullif(kt.total_revenue,0),
                       0
                   )
        end as revenue,

        bd.older_kids_revenue,
        bd.early_years_revenue,
        bd.hybrid_family_revenue,
        bd.adult_gift_revenue,
        bd.picture_book_revenue,
        bd.addon_gift_book_revenue,
        bd.addon_gift_revenue,
        bd.baby_revenue,
        bd.reached_personalisation,
        bd.kids_revenue,
        bd.adult_revenue,
                
                case 
            when bd.channel = 'Unknown' then 0
            else bd.gross_profit 
                 + coalesce(
                       ut.total_gross_profit * bd.gross_profit / nullif(kt.total_gross_profit,0),
                       0
                   )
        end as gross_profit,
        bd.clicks,
        --bd.contribution,
        bd.commission,
        bd.keyword_name,
        bd.campaign_book_category,
        bd.campaign_book_sub_category,
        bd.state,
        bd.trading_category

    from base_data bd
    left join unknown_totals ut
      on bd.date = ut.date 
     and bd.attribution_model = ut.attribution_model
     and bd.country = ut.country
    left join known_totals kt
      on bd.date = kt.date 
     and bd.attribution_model = kt.attribution_model
     and bd.country = kt.country

)

select *, COALESCE(gross_profit, 0) - COALESCE(cost, 0) as contribution from final
where date < CURRENT_DATE()