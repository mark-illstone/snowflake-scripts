
select 
    page_location_id,
    product_name, 
    name,
REGEXP_REPLACE(
    SPLIT_PART(SPLIT_PART(page_location_id, 'product/', 2), '?', 1),
    '-op[0-9]-v[0-9]+$',                                        
    ''
  ) AS product_slug,
from bi.dbt_production_ga4.page_registry
left join bi.google_sheets.ga_products
 on product_slug = slug
where page_location_id LIKE '%-op%'
and product_name is null
and page_type = 'product'
order by first_timestamp desc;


create or replace transient table bi.mark_dev.page_registry_07092026 clone bi.dbt_production_ga4.page_registry;

UPDATE bi.dbt_production_ga4.page_registry pr
SET pr.product_name = gp.name
FROM bi.google_sheets.ga_products gp
WHERE REGEXP_REPLACE(
        SPLIT_PART(SPLIT_PART(pr.page_location_id, 'product/', 2), '?', 1),
        '-op[0-9]+$',
        ''
      ) = gp.slug
  AND pr.page_location_id LIKE '%-op%'
  AND pr.product_name IS NULL
  AND pr.page_type = 'product';


create or replace transient table bi.mark_dev.clean_session_funnel_events_07092026 clone bi.dbt_production_ga4.clean_session_funnel_events;

  select *,
  REGEXP_REPLACE(
    SPLIT_PART(SPLIT_PART(product_page_path, 'product/', 2), '?', 1),
    '-op[0-9]+$',                                        
    ''
  ) AS product_slug,
  from bi.dbt_production_ga4.clean_session_funnel_events a
  --left join bi.dbt_production_ga4.page_registry b
  --on a.product_page_path = b.page_location_id
  where product is null
  --and funnel_type = 'product'
  and funnel_step = 'creation'
  and product_page_path like '%-op%';


  UPDATE bi.dbt_production_ga4.clean_session_funnel_events pr
SET pr.product = gp.name
FROM bi.google_sheets.ga_products gp
WHERE REGEXP_REPLACE(
        SPLIT_PART(SPLIT_PART(pr.product_page_path, 'product/', 2), '?', 1),
        '-op[0-9]+$',
        ''
      ) = gp.slug
  AND pr.product_page_path LIKE '%-op%'
  AND pr.product IS NULL
  AND pr.funnel_type = 'product'
  AND pr.funnel_step = 'creation';


create or replace transient table bi.mark_dev.preprocess_session_funnel_events_07092026 clone bi.dbt_production_ga4.preprocess_session_funnel_events;

  select *,
  REGEXP_REPLACE(
    SPLIT_PART(SPLIT_PART(FIRST_PRODUCT_PAGE_PATH_SEEN, 'product/', 2), '?', 1),
    '-op[0-9]+$',                                        
    ''
  ) AS product_slug,
  from bi.dbt_production_ga4.preprocess_session_funnel_events a
  --left join bi.dbt_production_ga4.page_registry b
  --on a.product_page_path = b.page_location_id
  where FIRST_PRODUCT_SEEN is null
  --and funnel_type = 'product'
  and FIRST_PRODUCT_PAGE_PATH_SEEN like '%-op%';


UPDATE bi.dbt_production_ga4.preprocess_session_funnel_events pr
SET pr.FIRST_PRODUCT_SEEN = gp.name
FROM bi.google_sheets.ga_products gp
WHERE REGEXP_REPLACE(
        SPLIT_PART(SPLIT_PART(pr.FIRST_PRODUCT_PAGE_PATH_SEEN, 'product/', 2), '?', 1),
        '-op[0-9]+$',
        ''
      ) = gp.slug
  AND pr.FIRST_PRODUCT_PAGE_PATH_SEEN LIKE '%-op%'
  AND pr.FIRST_PRODUCT_SEEN IS NULL;