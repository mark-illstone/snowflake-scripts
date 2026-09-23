

with pmax     as (select * from bi.dbt_production_models.fct_granular_google_pmax)
    ,shopping as (select * from bi.dbt_production_models.fct_granular_google_shopping)
    ,meta     as (select * from bi.dbt_production_models.fct_facebook_granular_data)

select
     day
    ,trading_category
    ,keepsake_kids
    ,keepsake_kids_subcategory
    ,'Google PMAX'                                        as channel
    ,cost                                                 as cost
    ,clicks                                               as clicks
    ,impressions                                          as impressions
    ,conversions                                          as conversions
    ,conversions_value                                    as revenue
from pmax

union all

select 
     day
    ,trading_category
    ,keepsake_kids
    ,keepsake_kids_subcategory
    ,'Google Shopping'                                    as channel
    ,cost                                                 as cost  
    ,clicks                                               as clicks  
    ,impressions                                          as impressions          
    ,conversions                                          as conversions          
    ,conversions_value                                    as revenue              
from shopping

union all

select
     day
    ,trading_category
    ,keepsake_kids
    ,keepsake_kids_subcategory
    ,'Meta'                                               as channel
    ,amount_spent                                         as cost                  
    ,action_link_click                                    as clicks                      
    ,impressions                                          as impressions                  
    ,conversions                                          as conversions                  
    ,revenue                                              as revenue              
from meta