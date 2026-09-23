/*
This table contains the page_type(s) and page_step for each link that has ever appeared as page_location in the page_view events
*/



-- bi shop sheets mapping table: contains the regex for page_path and query_params and the corresponding page_type(s) and page_step
WITH page_link_to_type AS (
    SELECT
        pages.idx,
        CASE
        WHEN products.slug IS NOT NULL THEN REPLACE(pages.page_path, '{PRODUCT}', products.slug)
        ELSE pages.page_path
        END AS page_path,
        pages.page_type,
        pages.page_type_2 AS page_type2,
        pages.page_type_3 AS page_type3,
        pages.page_step,
        pages.query_params,
        products.name AS product_name,
        pages.engagement,
        CASE WHEN pages.query_params = '\%\%' THEN 'empty' ELSE 'not_null' END AS query_params_empty
    FROM bi.google_sheets.ga_pages_detailed pages
    LEFT JOIN bi.google_sheets.ga_products products
           ON pages.page_path ILIKE '%{PRODUCT}%'
    WHERE COALESCE(pages.page_path, '') != ''
),

-- page information from ga4: contains the unique links and the page_paths and query_params
-- filter dedupe_event_params ONCE, used on both sides of the join
recent_event_params AS (
    SELECT
        event_key,
        event_name,
        event_params_key,
        event_params_value,
        event_timestamp
    FROM bi.DBT_PRODUCTION_GA4.dedupe_event_params
    
    
    WHERE event_date >= DATEADD(day, -3, CURRENT_DATE())
    
),

--pre-isolate just the rows each side needs before joining
recent_page_details AS (
    SELECT event_key, event_params_value, event_timestamp
    FROM recent_event_params
    WHERE event_name = 'page_view'
    AND event_params_key = 'page_path'
),

recent_query_params AS (
    SELECT event_key, event_params_value
    FROM recent_event_params
    WHERE event_params_key = 'query_params'
),


new_page_views AS (
    SELECT
        pd.event_key,
        pd.event_params_value AS page_path,
        qp.event_params_value AS query_params,
        pd.event_params_value || '?' || COALESCE(qp.event_params_value, '-') AS page_location_id,
        pd.event_timestamp
    FROM recent_page_details pd
    LEFT JOIN recent_query_params qp
        ON pd.event_key = qp.event_key

    
   WHERE pd.event_params_value || '?' || COALESCE(qp.event_params_value, '-')
          NOT IN (SELECT page_location_id FROM bi.DBT_PRODUCTION_GA4.page_registry)
    
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pd.event_params_value, qp.event_params_value 
                               ORDER BY pd.event_timestamp ASC) = 1
),

pages_with_params AS (
    SELECT * FROM new_page_views WHERE query_params IS NOT NULL
),
pages_without_params AS (
    SELECT * FROM new_page_views WHERE query_params IS NULL
),

classified AS (
    SELECT
        p.page_path || '?' || COALESCE(p.query_params, '-') AS page_location_id,
        p.page_path,
        p.query_params,
        TO_TIMESTAMP(p.event_timestamp) AS first_timestamp,
        t.page_type, t.page_type2, t.page_type3,
        t.page_step, t.idx AS priority, t.engagement, t.product_name
    FROM pages_with_params p
    LEFT JOIN page_link_to_type t
        ON p.page_path ILIKE t.page_path
        AND p.query_params ILIKE t.query_params

    UNION ALL

    SELECT
        p.page_path || '?' || '-' AS page_location_id,
        p.page_path,
        p.query_params,
        TO_TIMESTAMP(p.event_timestamp) AS first_timestamp,
        t.page_type, t.page_type2, t.page_type3,
        t.page_step, t.idx AS priority, t.engagement, t.product_name
    FROM pages_without_params p
    LEFT JOIN page_link_to_type t
        ON p.page_path ILIKE t.page_path
        AND t.query_params_empty = 'empty'
)

SELECT * FROM classified
QUALIFY ROW_NUMBER() OVER (PARTITION BY page_location_id ORDER BY priority ASC) = 1