WITH facebook_ads AS (SELECT * FROM bi.historical_newspapers.int_facebook_ads)
   , facebook_accounts AS (SELECT * FROM bi.historical_newspapers.int_facebook_accounts)
   , ad_insights AS (SELECt * FROM bi.historical_newspapers.int_facebook_ad_insights)

, temp_facebook_ads as (
    SELECT DISTINCT 
    LOWER(CONCAT(COALESCE('facebook', '(none)'), '@',
                 COALESCE(a.id::varchar(10000), '(none)'), '@',
                 COALESCE(a.country::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
         , 'facebook' as partner
         , 'Social Paid' as channel
         , a.account_id
         , b.account_name
         , a.country
         , a.campaign_id
         , a.campaign_name
         , a.adset_id as ad_group_id
         , a.adset_name as ad_group_name
         , a.id as ad_id
         , a.name as ad_name
         , NULL  as keyword_id
         , NULL as keyword_name
      FROM facebook_ads a
      LEFT JOIN facebook_accounts b 
        on a.account_id = b.account_id
)

-- Generate a list of unique ad_keys from ga_session data, but only for sessions that 
--      do not already have an ad_key in facebook_ads
-- We check if this is already present by building a second ad_key (fa_ad_key) that would match the 
--      ad_key in facebook_ads if it is present
-- When we build the sessions table later, this fa_ad_key takes priority if we find it in the structured_ads table

SELECT DISTINCT ad_key
     , partner
     , channel
     , account_id
     , account_name
     , country
     , campaign_id::VARCHAR AS campaign_id
     , campaign_name::VARCHAR AS campaign_name
     , ad_group_id::VARCHAR AS ad_group_id
     , ad_group_name::VARCHAR AS ad_group_name
     , ad_id::VARCHAR AS ad_id
     , ad_name::VARCHAR AS ad_name
     , keyword_id
     , keyword_name
  FROM temp_facebook_ads

UNION ALL

SELECT 
    LOWER(CONCAT(COALESCE('facebook', '(none)'), '@',
                 COALESCE(ad_id::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'), '@',
                 COALESCE(NULL::varchar(10000), '(none)'))
         )::varchar(10000)
 as ad_key
     , 'facebook' as partner
     , 'Social Paid' as channel
     , NULL as account_id
     , NULL as account_name
     , NULL as country
     , NULL::VARCHAR as campaign_id
     , NULL::VARCHAR as ad_group_id
     , NULL::VARCHAR as ad_group_name
     , ad_id::VARCHAR as ad_id
     , NULL as ad_name
     , NULL as keyword_id
     , NULL as keyword_name
     , max(campaign_name)::VARCHAR as campaign_name
  FROM ad_insights e
 WHERE NOT EXISTS (SELECT 1 FROM temp_facebook_ads f WHERE e.ad_id = f.ad_id)
 group by 1,2,3,4,5,7,8,9,10,11,12