CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_google_campaigns_daily AS

with campaigns as (select * from bi.fivetran_google_plucky.campaigns_daily)
   ,   accounts as (select * from bi.fivetran_google_plucky.account_history)

, campaigns_temp as (
    select
        campaigns.*
        , case
            -- Currently there is no display, but we include the logic for compatibility
            -- with Wonderbly
            when campaigns.advertising_channel_type = 'DISPLAY' then 'display'
            else 'cpc'
            end as medium
        ,
            CASE
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(UK|GBR)([_-]|$).*') THEN 'UK'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(US|USA)([_-]|$).*') THEN 'US'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(AU|AUS)([_-]|$).*') THEN 'AU'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(CA|CAN)([_-]|$).*') THEN 'CA'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(IT|ITA)([_-]|$).*') THEN 'IT'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(DE|DEU)([_-]|$).*') THEN 'DE'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(ES|ESP)([_-]|$).*') THEN 'ES'
                WHEN REGEXP_LIKE(UPPER(campaigns.name), '.*(^|[_-])(FR|FRA)([_-]|$).*') THEN 'FR' 
            END AS country
    from campaigns
)

select
      ct.country
    , ct.date as day
    -- Adding the campaign id to the ad_key for uniqueness
    , 
    LOWER(CONCAT(COALESCE('google', '(none)'), '@',
                 COALESCE(ct.medium::varchar(10000), '(none)'), '@',
                 COALESCE(ct.name::varchar(10000), '(none)'), '@',
                 COALESCE(ct.id::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
    , 'google'  as partner
    , ct.customer_id
    , a.descriptive_name as customer_name
    , ct.id AS campaign_id
    , ct.name AS campaign_name
    , ct.medium
    , ct.advertising_channel_sub_type
    , ct.advertising_channel_type
    , ct.clicks
    , ct.interactions
    , ct.impressions
    , ct.cost_micros / 1000000 as cost
from campaigns_temp ct
left join accounts a
    on a.id = ct.customer_id
    and a._fivetran_active = true