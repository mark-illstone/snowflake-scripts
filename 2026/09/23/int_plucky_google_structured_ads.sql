with campaigns as (select * from bi.historical_newspapers.int_google_campaigns_daily)

select 
    ad_key
    , partner
    , case
        when advertising_channel_type = 'DISPLAY' then 'Display'
        when advertising_channel_type = 'PERFORMANCE_MAX' then 'Performance Max'
        when advertising_channel_type = 'SHOPPING' then 'Shopping'
        when advertising_channel_type = 'VIDEO' then 'Video Paid'
        when advertising_channel_type = 'SEARCH' then 'PPC'
        else 'Other'
        end as channel
    -- Wonderbly channel logic 
    -- , case 
    --     when (lower(campaign_name) like '%smart%' and lower(campaign_name) not like '%pmax%') then 'Shopping'
    --     when lower(campaign_name) rlike '.*_sho.*' then 'Shopping'
    --     when lower(campaign_name) like '%-yt-%' then 'Video paid'
    --     when lower(campaign_name) like '%-dc-%' or lower(campaign_name) like '%dis_%' then 'Display'
    --     when (lower(campaign_name) like '%pmax%') THEN 'Performance Max'
    --     when lower(campaign_name) like '%brand%' then 'PPC Brand'
    --     else 'PPC Nonbrand'
    --     end as channel
    , customer_id as account_id
    , customer_name as account_name
    , CASE WHEN country like '%us%' THEN 'USA'
           WHEN country like '%uk%' THEN 'UK'
           WHEN country like '%au%' THEN 'AU'
           WHEN country like '%ca%' THEN 'CA'
           WHEN country like '%irl%' THEN 'IRL'
           ELSE ''
           END as country
    , campaign_id::varchar as campaign_id
    , campaign_name
    , null::varchar as ad_group_id
    , null::varchar as ad_group_name
    , null::varchar as ad_id
    , null::varchar as ad_name
    , null::varchar as keyword_id
    , null::varchar as keyword_name
from campaigns
--qualify row_number() over (partition by campaign_id order by day desc) = 1
qualify ROW_NUMBER() OVER (PARTITION BY ad_key order by ad_key, day desc) = 1