--int_hn_order_tag_shopify_300726

--CREATE OR REPLACE TABLE bi.mark_dev.int_hn_order_tag_shopify AS

WITH order_tag AS (SELECT * FROM bi.fivetran_shopify_test_19.order_tag where order_id = 13037693632896)
    ,cs_reason_tags AS (SELECT * FROM bi.google_sheets.cs_reason_tags)

, order_tag_pivot as (
SELECT 
    ORDER_ID,
    LISTAGG(DISTINCT VALUE, ', ') WITHIN GROUP(ORDER BY VALUE) AS all_order_tags
    FROM order_tag 
GROUP BY ORDER_ID
)

,refund_category_reason AS
 (
SELECT 
    a.order_id,
    COALESCE(
        NULLIF(b.reason, ''),
        NULLIF(c.reason, ''),
        'Unknown Tag'
    ) AS reason,
    COALESCE(
        NULLIF(b.category_code, ''),
        NULLIF(c.category_code, ''),
        'Unknown Tag'
    ) AS category_code,
    COALESCE(
        NULLIF(b.category, ''),
        NULLIF(c.category, ''),
        'Unknown Tag'
    ) AS category
FROM 
    order_tag a
        LEFT JOIN cs_reason_tags b
            ON a.value = b.refund_agent_tag
        LEFT JOIN cs_reason_tags c
            ON a.value = c.refund_full_tag
WHERE 
    a.order_id IN
(
SELECT
    order_id
FROM 
    order_tag
WHERE 
    (lower(value) IN ('refund', 'partial refund', 'reordered', 'reorder', 'replacement')
    OR value LIKE ('%RFND%'))
)
AND len(a.value)>=5
)


,refund_category_reason_dedupe AS
(
SELECT *
FROM refund_category_reason
QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY category_code, category) = 1
)

SELECT DISTINCT
    all_tags.order_id::integer as order_id,
    country.value::varchar as order_tag,
    marketplace.value::varchar as marketplace_tag,
    CASE WHEN orig.value IS NOT NULL THEN 'Reordered' END AS orig_reordered_tag,
    COALESCE(reorder.value, orig_reordered_tag)::varchar as reorder_tag,
    order_tag_pivot.all_order_tags::varchar as all_order_tags,
    refund_category_reason_dedupe.category_code::varchar as cs_category_code,
    refund_category_reason_dedupe.category::varchar as cs_category,
    refund_category_reason_dedupe.reason::varchar as cs_reason
from order_tag all_tags
left join order_tag country on all_tags.order_id = country.order_id and length(country.value) = 2 and country.value != '[]'
left join order_tag marketplace on all_tags.order_id = marketplace.order_id and marketplace.value in 
    ('ETSY' , 'NOTHS', 'AMAZONUK', 'AMAZONUS', 'AMAZUS', 'AMAZUSP', 'HISAMAZ', 'HISAMAZP', 'HISEBAY', 'HISETSY', 'HISNOTHS',
    'HISTEL', 'HISMBI', 'UNCOM', 'LATS', 'NYDN', 'HISMIRROR', 'WASHPS')
left join order_tag reorder on all_tags.order_id = reorder.order_id and lower(reorder.value) = 'reordered'
left join order_tag orig on all_tags.order_id = orig.order_id and lower(orig.value) like 'orig_%'
left join order_tag_pivot on all_tags.order_id = order_tag_pivot.order_id
left join refund_category_reason_dedupe on all_tags.order_id = refund_category_reason_dedupe.order_id