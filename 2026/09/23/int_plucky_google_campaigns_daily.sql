with campaigns_uk as (select * from bi.fivetran_google_historical_newspapers_uk.campaigns_daily)
   , campaigns_us as (select * from bi.fivetran_google_historical_newspapers_us.campaigns_daily)
   , campaigns_ca as (select * from bi.fivetran_google_historical_newspapers_ca.campaigns_daily)
   , campaigns_au as (select * from bi.fivetran_google_historical_newspapers_au.campaigns_daily)
   , campaigns_irl as (select * from bi.fivetran_google_historical_newspapers_irl.campaigns_daily)
   , campaigns_row as (select * from bi.fivetran_google_historical_newspapers_row.campaigns_daily)

   , accounts_uk as (select * from bi.fivetran_google_historical_newspapers_uk.account_history)
   , accounts_us as (select * from bi.fivetran_google_historical_newspapers_us.account_history)
   , accounts_ca as (select * from bi.fivetran_google_historical_newspapers_ca.account_history)
   , accounts_au as (select * from bi.fivetran_google_historical_newspapers_au.account_history)
   , accounts_irl as (select * from bi.fivetran_google_historical_newspapers_irl.account_history)
   , accounts_row as (select * from bi.fivetran_google_historical_newspapers_row.account_history)

, accounts as (


select
    'uk' as country
    , id as customer_id
    , descriptive_name as customer_name
from accounts_uk
where _fivetran_active = true


union all




select
    'us' as country
    , id as customer_id
    , descriptive_name as customer_name
from accounts_us
where _fivetran_active = true


union all




select
    'ca' as country
    , id as customer_id
    , descriptive_name as customer_name
from accounts_ca
where _fivetran_active = true


union all




select
    'au' as country
    , id as customer_id
    , descriptive_name as customer_name
from accounts_au
where _fivetran_active = true


union all




select
    'irl' as country
    , id as customer_id
    , descriptive_name as customer_name
from accounts_irl
where _fivetran_active = true


union all




select
    'row' as country
    , id as customer_id
    , descriptive_name as customer_name
from accounts_row
where _fivetran_active = true




)

, campaigns as (


select
    'uk' as country
    , campaigns.customer_id
    , campaigns.date as day
    , campaigns.id as campaign_id
    , campaigns.name as campaign_name
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros
from campaigns_uk as campaigns


union all




select
    'us' as country
    , campaigns.customer_id
    , campaigns.date as day
    , campaigns.id as campaign_id
    , campaigns.name as campaign_name
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros
from campaigns_us as campaigns


union all




select
    'ca' as country
    , campaigns.customer_id
    , campaigns.date as day
    , campaigns.id as campaign_id
    , campaigns.name as campaign_name
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros
from campaigns_ca as campaigns


union all




select
    'au' as country
    , campaigns.customer_id
    , campaigns.date as day
    , campaigns.id as campaign_id
    , campaigns.name as campaign_name
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros
from campaigns_au as campaigns


union all




select
    'irl' as country
    , campaigns.customer_id
    , campaigns.date as day
    , campaigns.id as campaign_id
    , campaigns.name as campaign_name
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros
from campaigns_irl as campaigns


union all




select
    'row' as country
    , campaigns.customer_id
    , campaigns.date as day
    , campaigns.id as campaign_id
    , campaigns.name as campaign_name
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros
from campaigns_row as campaigns




)

, campaigns_with_medium as (
    select
        campaigns.*
        , case
            -- Currently there is no display, but we include the logic for compatibility
            -- with Wonderbly
            when campaigns.advertising_channel_type = 'DISPLAY' then 'display'
            else 'cpc'
            end as medium
    from campaigns
)

select
      campaigns.country
    , campaigns.day
    -- Adding the campaign id to the ad_key for uniqueness
    , 
    LOWER(CONCAT(COALESCE('google', '(none)'), '@',
                 COALESCE(campaigns.medium::varchar(10000), '(none)'), '@',
                 COALESCE(campaigns.campaign_name::varchar(10000), '(none)'), '@',
                 COALESCE(campaigns.campaign_id::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
    , 'google'  as partner
    , campaigns.customer_id
    , accounts.customer_name
    , campaigns.campaign_id
    , campaigns.campaign_name
    , campaigns.medium
    , campaigns.advertising_channel_sub_type
    , campaigns.advertising_channel_type
    , campaigns.clicks
    , campaigns.interactions
    , campaigns.impressions
    , campaigns.cost_micros / 1000000 as cost
from campaigns_with_medium as campaigns
left join accounts
    on accounts.customer_id = campaigns.customer_id