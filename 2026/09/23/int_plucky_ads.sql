CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_ads AS

with google as (select * from bi.mark_dev.int_plucky_google_structured_ads)
   , facebook as (select * from bi.mark_dev.int_plucky_facebook_structured_ads)

, ads_union as (
    
    select
        ad_key
        , partner
        , channel
        , account_id
        , account_name
        , country
        , campaign_id
        , campaign_name
        , ad_group_id
        , ad_id
        , ad_name
        , keyword_id
        , keyword_name
    from google

    
    union all
    
    
    select
        ad_key
        , partner
        , channel
        , account_id
        , account_name
        , country
        , campaign_id
        , campaign_name
        , ad_group_id
        , ad_id
        , ad_name
        , keyword_id
        , keyword_name
    from facebook    
    
)

select
    ad_key
    , channel
    -- Using the same logic as Wonderbly even though most of this are not present
    , case
        when channel in ('Organic Search', 'Direct', 'PPC Brand') then 'Brand (incl ATL)'
        when channel in ('Social Paid') then 'Social Paid'
        when channel in ('Affiliates') then 'Affiliate'
        when channel in ('PPC', 'PPC Nonbrand', 'Shopping', 'Smart shopping',
            'Performance Max', 'Shopping | PMax') then 'PPC NB'
        when channel in ('RAF') then 'RAF'
        when channel in ('Unknown') then 'Unknown'
        when channel in ('Email') then 'Email'
        when channel in ('Reseller') then 'Resellers'
        when channel in ('Display') then 'Display'
        when channel in ('Video paid') then 'Video'
        when channel in ('In-pack Marketing') then 'In-pack Marketing'
        else 'Other'
      end as channel_groups
    , case
        when channel in ('Social Paid', 'PPC Nonbrand', 'PPC', 'Offline',
           'Smart shopping', 'Shopping', 'Display', 'Reseller', 'Affiliates',
           'Video paid', 'Performance Max') then 'Paid'
        when channel in ('Direct', 'Email', 'Organic Search', 'Other',
           'RAF', 'Referral', 'Social Organic', 'Video Organic', 'PPC Brand',
           'In-pack Marketing'  ) then 'Unpaid'
        when channel = 'Unknown' then 'Unknown'
        when ad_key like 'mms-%' then 'Paid'
        else 'Unassigned'
      end as channel_paid_or_unpaid
    , partner
    , account_id
    , account_name
    , country
    , campaign_id
    , campaign_name
    , ad_group_id
    , ad_id
    , ad_name
    , keyword_id
    , keyword_name

from ads_union