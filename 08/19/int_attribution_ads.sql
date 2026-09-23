create or replace table bi.mark_dev.int_attribution_ads as

WITH facebook_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_facebook_structured_ads)
   , google_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_google_structured_ads)
   , bing_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_bing_structured_ads)
   , affiliate_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_affiliate_structured_ads)
   , tiktok_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_tiktok_structured_ads)
   , pinterest_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_pinterest_structured_ads)
   , raf_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_raf_structured_ads)
   , inpack_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_inpack_structured_ads)
   , manual_spend_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_manual_spend_structured_ads)
   , reseller_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_reseller_structured_ads)
   , email_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_email_structured_ads)
   , organic_social_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_organic_social_structured_ads)
   , organic_video_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_organic_video_structured_ads)
   , payment_provider_tracking_issues_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_payment_provider_tracking_issues_structured_ads)
   , referral_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_referral_structured_ads)
   , organic_search_structured_Ads AS (SELECT * FROM bi.dbt_production_intermediate.int_organic_search_structured_ads)
   , direct_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_direct_structured_ads)
   , other_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_other_structured_ads)
   , unknown_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_unknown_structured_ads)
   , manual_affiliates_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_manual_affiliates_structured_ads)
   , ai_assistant_structured_ads AS (SELECT * FROM bi.mark_dev.int_ai_assistant_structured_ads)
   , sms_structured_ads AS (SELECT * FROM bi.dbt_production_intermediate.int_sms_structured_ads)

, complete_structured_ads AS (

    SELECT CASE 
            WHEN (lower(campaign_name) like '%crm%' OR lower(campaign_name) like '%retention%') THEN 'Meta Retention'
            ELSE 'Meta Prospecting'
            END as CHANNEL

         , 10 AS channel_rank
         , * 
    FROM FACEBOOK_STRUCTURED_ADS

    UNION ALL

    SELECT CASE 
             when (lower(campaign_name) like '%brand%' and lower(campaign_name) like '%sea%') then 'Paid Search Brand'
             when (lower(campaign_name) like '%brand%' and lower(campaign_name) like '%sho%') then 'Shopping Brand'
             when (lower(campaign_name) like '%sho%' or lower(campaign_name) like '%pmax%')  then 'Shopping Non-Brand' 
             when lower(campaign_name) like '%-yt-%' then 'YouTube'
             when lower(campaign_name) like '%-dc-%' or lower(campaign_name) like '%dis_%' or lower(campaign_name) like '%-dg%' then 'Display'
             else 'Paid Search Non-Brand' END as CHANNEL
            
         , 20 AS channel_rank
         , *
    FROM GOOGLE_STRUCTURED_ADS

    UNION ALL

    SELECT CASE 
				when (lower(campaign_name) like '%brand%' and lower(campaign_name) like '%sea%') then 'Paid Search Brand'
	            when (lower(campaign_name) like '%brand%' and lower(campaign_name) like '%sho%') then 'Shopping Brand'
	            when (lower(campaign_name) like '%sho%' or lower(campaign_name) like '%pmax%')   then 'Shopping Non-Brand' 
                else 'Paid Search Brand' END as CHANNEL
         , 30 AS channel_rank
         , *
    FROM BING_STRUCTURED_ADS

    UNION ALL

        SELECT CASE 
			when (lower(campaign_name) like '%flow_%' or lower(campaign_name) like '%auto%' 
                or lower(campaign_name) like '%abandoned_%' or lower(campaign_name) like '%welcome%' 
                or lower(campaign_name) like '%anniversary%' 
                or (lower(campaign_name) like '%credit_style%' and lower(campaign_name) like '%automated%') 
                or lower(campaign_name) like '%transactional%') 
				then 'Email Flows'
                
            when lower(campaign_name) like '%credit%' AND lower(campaign_name) NOT LIKE '%credit_style%' AND lower(campaign_name) NOT LIKE '%lapsed%'
               AND lower(campaign_name) NOT LIKE '%_oi%' AND lower(campaign_name) NOT LIKE '%credit_launch_xmas_generic%'
               AND lower(campaign_name) NOT LIKE '%credit_reminder_xmas_generic%'
			then 'Email Opted-out Credits'
              else 'Email Campaigns' 
              END as CHANNEL
         , 30 AS channel_rank
         , *
      FROM email_structured_ads

    UNION ALL SELECT 'Affiliates' as CHANNEL, 40 AS channel_rank, * FROM AFFILIATE_STRUCTURED_ADS
    UNION ALL SELECT 'Affiliates' as CHANNEL, 40 AS channel_rank, * FROM manual_affiliates_structured_ads WHERE lower(partner) = 'affiliates'

    UNION ALL SELECT 'Ambassadors' as CHANNEL, 45 AS channel_rank, * FROM manual_affiliates_structured_ads WHERE lower(partner) = 'ambassadors'
   --  --UNION ALL SELECT 'Display' as CHANNEL, 50 AS channel_rank, * FROM BI.ATTRIBUTION.DISPLAY_STRUCTURED_ADS
     UNION ALL SELECT 'TikTok' as CHANNEL, 55 AS channel_rank, * FROM TIKTOK_STRUCTURED_ADS
     UNION ALL SELECT 'Other' as CHANNEL, 60 AS channel_rank, * FROM PINTEREST_STRUCTURED_ADS
     UNION ALL SELECT 'Customer Referrals' as CHANNEL, 70 AS channel_rank, * FROM RAF_STRUCTURED_ADS
     UNION ALL SELECT 'In-pack Marketing' as CHANNEL, 75 as channel_rank, * FROM INPACK_STRUCTURED_ADS ----------HERE
     
     UNION ALL 
     
    SELECT CASE when lower(partner) <> '' then partner  else 'Offline' end as CHANNEL, 80 AS channel_rank, * FROM MANUAL_SPEND_STRUCTURED_ADS

     UNION ALL SELECT 'Reseller' as CHANNEL, 90 AS channel_rank, * FROM RESELLER_STRUCTURED_ADS
     UNION ALL SELECT 'Email' as CHANNEL, 100 AS channel_rank, * FROM EMAIL_STRUCTURED_ADS
     UNION ALL SELECT 'Organic Social' as CHANNEL, 110 AS channel_rank, * FROM ORGANIC_SOCIAL_STRUCTURED_ADS
     UNION ALL SELECT 'Organic Social' as CHANNEL, 120 AS channel_rank, * FROM ORGANIC_VIDEO_STRUCTURED_ADS
     UNION ALL SELECT 'Other' as CHANNEL, 130 AS channel_rank, * FROM payment_provider_tracking_issues_structured_ads
     UNION ALL SELECT 'Publisher Referrals' as CHANNEL, 140 AS channel_rank, * FROM REFERRAL_STRUCTURED_ADS
     UNION ALL SELECT 'AI Assistant' as CHANNEL, 145 AS channel_rank, * FROM AI_ASSISTANT_STRUCTURED_ADS
     UNION ALL SELECT 'Organic Search' as CHANNEL, 150 AS channel_rank, * FROM ORGANIC_SEARCH_STRUCTURED_ADS
     UNION ALL SELECT 'Direct' as CHANNEL, 160 AS channel_rank, * FROM DIRECT_STRUCTURED_ADS
     UNION ALL SELECT 'Other' as CHANNEL, 170 AS channel_rank, * FROM OTHER_STRUCTURED_ADS
     UNION ALL SELECT 'Unknown' as CHANNEL, 180 AS channel_rank, * FROM UNKNOWN_STRUCTURED_ADS
     UNION ALL SELECT 'SMS' as CHANNEL, 190 AS channel_rank, * FROM SMS_STRUCTURED_ADS
)

SELECT ad_key
     , channel
     , CASE WHEN channel in ('Meta Retention', 'Meta Prospecting') THEN 'Meta'
            WHEN channel in ('TikTok') THEN 'TikTok'
            WHEN channel in ('Paid Search Brand', 'Shopping Brand') THEN 'PPC Brand'
            WHEN channel in ('Shopping Non-Brand', 'Paid Search Non-Brand') THEN 'PPC Non-brand'
            WHEN channel in ('Display') THEN 'Display'
            WHEN channel in ('Organic Social', 'Organic Search') THEN 'Organic'
            WHEN channel in ('Email Flows', 'Email Campaigns','Email Opted-out Credits') THEN 'Email'
            WHEN channel in ('Affiliates') THEN 'Affiliates'
            WHEN channel in ('Customer referrals', 'Publisher Referrals') THEN 'Referrals'
            WHEN channel in ('YouTube') THEN 'YouTube'
            WHEN channel in ('Direct') THEN 'Direct'
            WHEN channel in ('TV', 'Tube') THEN 'ATL'
            WHEN channel in ('Direct Mail') THEN 'Direct Mail'
            WHEN channel in ('Ambassadors') THEN 'Ambassadors'
            WHEN channel in ('AI Assistant') THEN 'AI Assistant'
            WHEN channel in ('SMS') THEN 'SMS'
            ELSE 'Other'
       END as channel_groups

     , CASE WHEN channel in ('Meta Retention', 'Meta Prospecting', 'TikTok') THEN 'Paid Social'
            WHEN channel in ('Paid Search Brand', 'Shopping Brand', 'Shopping Non-Brand', 'Paid Search Non-Brand') THEN 'PPC'
            WHEN channel in ('Display', 'YouTube') THEN 'Display & Video'
            WHEN channel in ('Organic Social', 'Organic Search') THEN 'Organic'
            WHEN channel in ('Email Flows', 'Email Campaigns','Email Opted-out Credits') THEN 'Email'
            WHEN channel in ('Direct Mail') THEN 'Direct Mail'
            WHEN channel in ('Direct') THEN 'Direct'
            WHEN channel in ('TV', 'Tube') THEN 'ATL'
            WHEN channel in ('SMS') THEN 'SMS'
            ELSE 'Other'
       END as top_level_channel_groups

       ,CASE WHEN channel IN (
			'Customer Referrals',
			'Organic Search',
			'Affiliates',
			'Meta Prospecting',
            'TikTok',
            'Shopping Non-Brand',
            'Organic Social',
            'Display',
            'Reseller',
            'YouTube',
            'Other',
            'Publisher Referrals',
            'Paid Search Non-Brand',
            'Ambassadors',
            'AI Assistant',
            'SMS'
            ) THEN 'Acquisition'
            WHEN channel IN (
            'Direct',
            'Direct Mail',
            'Paid Search Brand',
            'Shopping Brand',
            'Meta Retention',
            'Email Campaigns',
            'Email Flows',
            'Email Opted-out Credits',
            'In-pack Marketing'  
            ) THEN 'Retention'
            WHEN channel IN (
            'TV',
            'Tube',
            'Offline') THEN 'ATL'
        
       ELSE 'Unassigned'
       END as channel_type

     ,(CASE WHEN channel IN (
			'Meta Prospecting',
			'Meta Retention',
            'TikTok',
            'Offline',
            'Shopping Brand',
            'Shopping Non-Brand',
            'Display',
            'Reseller',
            'YouTube',
            'Paid Search Brand',
            'Paid Search Non-Brand',
            'Affiliates',
            'TV',
            'Direct Mail',
            'Tube',
            'Ambassadors'
            ) THEN 'Paid'

            WHEN channel IN (
            'Direct',
            'Email Campaigns',
            'Email Flows',
            'Email Opted-out Credits',
            'Organic Search',
            'Other',
            'Customer Referrals',
            'Publisher Referrals',
            'Organic Social',
            'In-pack Marketing',
            'AI Assistant',
            'SMS'
            ) THEN 'Unpaid'
            WHEN channel = 'Unknown' THEN 'Unknown'
            ELSE 'Unassigned'
       END)::VARCHAR AS channel_paid_or_unpaid

     , partner
     , account_id
     , account_name
     , campaign_id
     , campaign_name
     , CASE
      /* 1) Transactional always wins if present */
      WHEN LOWER(COALESCE(campaign_name, '')) LIKE '%transactional%'
        THEN 'Transactional'

      /* 2) Credit opted out: has 'credit' but NOT 'credit_style' and NOT 'lapsed' */
      WHEN LOWER(COALESCE(campaign_name, '')) LIKE '%credit%'
           AND LOWER(COALESCE(campaign_name, '')) NOT LIKE '%credit_style%'
           AND LOWER(COALESCE(campaign_name, '')) NOT LIKE '%lapsed%'
           AND LOWER(COALESCE(campaign_name, '')) NOT LIKE '%_oi_%'
           AND LOWER(COALESCE(campaign_name, '')) NOT LIKE '%xmas_generic%'
        THEN 'Credit opted out'

      /* 3) Any other 'credit' falls into opted-in */
      WHEN LOWER(COALESCE(campaign_name, '')) LIKE '%credit%'
        THEN 'Credit opted in'

      /* 4) Everything else */
      ELSE 'Other'
    END as email_type
     , ad_group_id
     , ad_group_name
     , ad_id
     , ad_name
     , keyword_id
     , keyword_name
     , (case when lower(split_part(campaign_name, '_', 1)) = 'childrens'  then 'Core' 
            when lower(split_part(campaign_name, '_', 1)) in ('friendship', 'milestone', 'experimental') then 'Experimental' 
            else 'Core'
       end)::VARCHAR campaign_book_category
     , (case when lower(split_part(campaign_name, '_', 2)) = 'chl'  then 'chl'
            when lower(split_part(campaign_name, '_', 2)) = 'fam' then 'fam'
            when lower(split_part(campaign_name, '_', 2)) = 'gen'  then 'gen'
            when lower(split_part(campaign_name, '_', 2)) = 'poe'  then 'poe'
            when lower(split_part(campaign_name, '_', 2)) = 'fai'  then 'fai'
            when lower(split_part(campaign_name, '_', 2)) = 'tboe'  then 'tboe'
            else 'gen'
       end)::VARCHAR campaign_book_sub_category
     , COUNT(*) OVER (PARTITION BY ad_key) AS number_of_duplicate_ad_keys

     , CASE WHEN LOWER(partner) = 'facebook' AND lower(campaign_name) LIKE '%seasonal%'
            THEN 'Occasion'
            WHEN LOWER(partner) = 'facebook' 
            THEN 'Evergreen'
            WHEN LOWER(partner) = 'google' AND (lower(campaign_name) LIKE '%mum%' OR lower(campaign_name) LIKE '%mother%' OR lower(campaign_name) LIKE '%dad%' OR lower(campaign_name) LIKE '%father%') 
            THEN 'Occasion'
            WHEN LOWER(partner) = 'google'
            THEN 'Evergreen'
        END AS trading_category

  FROM complete_structured_ads

-- Dedupe
QUALIFY ROW_NUMBER() OVER (PARTITION BY ad_key ORDER BY channel_rank, ad_id ASC) = 1