CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_ads AS

WITH facebook_ads AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_ads_base)
   , adsets AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_adsets)
   , campaigns AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_campaigns)
   , accounts AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_accounts)
   , facebook_creatives AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_creatives)

SELECT ads.ad_id AS id
     , ads.ad_name AS name
     , ad_sets.adset_id
     , ad_sets.adset_name
     , ad_sets.country
     , campaigns.campaign_id
     , campaigns.campaign_name
     , accounts.account_id
     , accounts.account_id AS account_name
     , c.medium
     , c.source
     , CASE WHEN c.campaign = '{{campaign.name}}' THEN campaigns.campaign_name ELSE c.campaign END AS campaign
     , CASE WHEN c.content = '{{adset.name}}_{{ad.name}}' THEN ad_sets.adset_name||'_'||ads.ad_name
            WHEN c.content = '{{campaign.name}}_{{ad.name}}' THEN campaigns.campaign_name||'_'||ads.ad_name ELSE c.content END AS content
     , CASE WHEN c.term = '{{ad.id}}' THEN ads.ad_id::varchar ELSE c.term END AS term
     , to_timestamp_ntz(CAST('2026-09-23 06:55:09.943401+00:00' AS TIMESTAMP)) AS updated_at   
  FROM facebook_ads ads
  JOIN adsets ad_sets 
    ON ads.adset_id = ad_sets.adset_id
  JOIN campaigns
    ON ad_sets.campaign_id = campaigns.campaign_id
  JOIN accounts 
    ON campaigns.account_id = accounts.account_id
  JOIN facebook_creatives c 
    ON ads.creative_id = c.creative_id