CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_creatives AS

WITH creatives AS (SELECT * FROM bi.mark_dev.int_plucky_facebook_creatives_base)

SELECT creative_id
     , creative_name
     , source
     , medium
     , campaign
     , content
     , placement
     , term 
  FROM creatives
QUALIFY ROW_NUMBER() OVER (PARTITION BY creative_id ORDER BY creative_id)= 1