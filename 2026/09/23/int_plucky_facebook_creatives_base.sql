CREATE OR REPLACE TABLE bi.mark_dev.int_plucky_facebook_creatives_base AS

WITH creative_history AS (SELECT * FROM bi.fivetran_facebook_plucky.creative_history)
   , ad_history AS (SELECT * FROM bi.fivetran_facebook_plucky.ad_history)

, creative_url_tags AS (
    SELECT id
         , MAX(CASE WHEN tags.value:key = 'utm_source' THEN tags.value:value end::varchar) AS source
         , MAX(CASE WHEN tags.value:key = 'utm_medium' THEN tags.value:value end::varchar) AS medium
         , MAX(CASE WHEN tags.value:key = 'utm_campaign' THEN tags.value:value end::varchar) AS campaign
         , MAX(CASE WHEN tags.value:key = 'utm_content' THEN tags.value:value end::varchar) AS content
         , MAX(CASE WHEN tags.value:key = 'utm_term' THEN tags.value:value end::varchar) AS term
      FROM creative_history
         , LATERAL FLATTEN(input => url_tags, outer => true) tags
     WHERE tags.value:type = 'AD'
     GROUP BY 1
)

SELECT DISTINCT ch.id::integer AS creative_id
     , ch.name::varchar AS creative_name
     , ah.id::integer AS ad_id
     -- Unused field removed because the data type is different
     --, ch.url_tags
     , null AS placement
     , u.source
     , u.medium
     , u.campaign
     , u.content
     , u.term
  FROM creative_history ch
  LEFT JOIN creative_url_tags u
    ON ch.id = u.id
  LEFT JOIN ad_history ah
    ON ch.id = ah.creative_id