select *
from bi.dbt_production_ga4.page_registry
where page_path LIKE '%good-night%';
--and page_type = 'product'
--and page_type2 = 'variant'
--and page_step = 'creation';



update bi.dbt_production_ga4.page_registry
set page_type = 'product',
    page_type2 = 'variant',
    page_step = 'creation'
where page_path in
(
 '/uk/landing-pages/personalized-products/product/good-night-everyone-book-op808',
'/my/personalized-products/when-you-were-born-book-op808',
'/kr/personalized-products/when-you-were-born-book-op808'
)
--and page_type = 'product'
--and page_type2 = 'variant'
--and page_step = 'creation';
and product_name is null;


update bi.dbt_production_ga4.page_registry
set product_name = 'When You Were Born',
    funnel_type = 'product',
    funnel_step = 'creation'
where page_path in
(
-- '/uk/landing-pages/personalized-products/product/good-night-everyone-book-op808',
'/my/personalized-products/when-you-were-born-book-op808',
'/kr/personalized-products/when-you-were-born-book-op808'
);

update bi.dbt_production_ga4.page_registry
set product_name = 'Goodnight Name, Goodnight Everyone'
where page_path in
(
'/uk/landing-pages/personalized-products/product/good-night-everyone-book-op808'
);


update bi.dbt_production_ga4.clean_session_funnel_events
set product = 'When You Were Born',
    funnel_type = 'product',
    funnel_step = 'creation'
where product_page_path in
(
-- '/uk/landing-pages/personalized-products/product/good-night-everyone-book-op808',
'/my/personalized-products/when-you-were-born-book-op808',
'/kr/personalized-products/when-you-were-born-book-op808'
);


update bi.dbt_production_ga4.clean_session_funnel_events
set product = 'Goodnight Name, Goodnight Everyone',
    funnel_type = 'product',
    funnel_step = 'creation'
where product_page_path in
(
'/uk/landing-pages/personalized-products/product/good-night-everyone-book-op808'
)
and product is null
and funnel_type is null
and funnel_step is null;

create or replace table bi.mark_dev.dedupe_event_params_07092026 as
select *
from bi.DBT_PRODUCTION_GA4.dedupe_event_params
where event_date >= '2026-09-03'
--and event_params_value = 'optimizely_token=63eea089a6442b324030c82f0dc8a561ceb089d6490f65b39f5319b0d7e5cc5e&optimizely_snippet=s3-228798099&optimizely_preview_layer_ids=6027809133428736&optimizely_embed_editor=false&optimizely_x=4750107902476288'
--and event_name = 'page_view'
--and (event_params_key = 'page_path' or event_params_key = 'query_params')
and user_pseudo_id in
(
    '1201752322.1787731539',
    '297763564.1788445332',
    '747876870.1788447600'
)
limit 1000;




select *
from bi.google_sheets.ga_pages_detailed
order by idx;


--%landing-pages/personali_ed-products/product/%newspaper-birthday-book%

--'%landing-pages/personalized-products/product/newspaper-birthday-book%'

update bi.google_sheets.ga_pages_detailed
set page_path = '%landing-pages/personalized-products/product/{PRODUCT}-op%'
where page_path = '%landing-pages/personalized-products/product/{PRODUCT}%';



select *
from bi.google_sheets.ga_pages_detailed
where page_type_2 = 'variant';



select 
first_product_page_path_seen,
first_product_seen,
REGEXP_SUBSTR(first_product_page_path_seen, '[^/]+', 1, 3),
REGEXP_SUBSTR(first_product_page_path_seen, '[^/]+', 1, 2),
LOWER(REPLACE(REPLACE(REPLACE(first_product_seen, ' -', ''), ',', ''), ' ', '-')),


REGEXP_REPLACE(SPLIT_PART(SPLIT_PART(first_product_page_path_seen, 'product/', 2), '?', 1), '-op[0-9]+$', '')



From bi.dbt_production_ga4.preprocess_session_funnel_events
where session_id = '1983660557.17886216931788621691';



select a.slug, max(a.retail_category) as retail_category, max(a.pdc) as pdc, max(b.theme) as retail_sub_category,
    max(to_date(a.brand_launch_date, 'DD/MM/YYYY')) as brand_launch_date, max(b.evergreen_occasion) as trading_category,
    max(b.evergreen_occasion_sub_cat) as evergreen_occasion_sub_cat,
    max(b.keepsake_kids_sub_cat) as keepsake_kids_sub_cat,
    max(b.keepsake_kids) as keepsake_kids

    from bi.google_sheets.skus_mapping a
    left join bi.google_sheets.product_categories b on a.brand = b.brand
    group by slug
    order by slug;






select session_id, first_product_seen, keepsake_kids, retail_category, retail_sub_category, trading_category, evergreen_occasion_sub_cat, keepsake_kids_sub_cat
from bi.dbt_production_ga4.preprocess_sessions
where session_id in
(
'1983660557.17886216931788621691',
'1583333899.17886207751788620774',
'1915777006.17886752921788675291',
'323987531.17884915081788491507',
'574999700.17882003031788499738',
'1544884803.17886085831788608583',
'539129321.17885734241788573423',
'365455512.17886237751788623775',
'658869922.17885648831788564882',
'1079040263.17886445071788644506',
'1930918651.17885398561788539855',
'1453463090.17884014771788660680',
'613241405.17886142351788614235',
'1788734541.17887177311788717730',
'1831668727.17885667021788566701',
'1407854105.17886605771788660576'
);


select session_id, first_product_seen, keepsake_kids, retail_category, retail_sub_category, trading_category, evergreen_occasion_sub_cat, keepsake_kids_sub_cat
from bi.mark_dev.preprocess_sessions
where session_id in
(
'1983660557.17886216931788621691',
'1583333899.17886207751788620774',
'1915777006.17886752921788675291',
'323987531.17884915081788491507',
'574999700.17882003031788499738',
'1544884803.17886085831788608583',
'539129321.17885734241788573423',
'365455512.17886237751788623775',
'658869922.17885648831788564882',
'1079040263.17886445071788644506',
'1930918651.17885398561788539855',
'1453463090.17884014771788660680',
'613241405.17886142351788614235',
'1788734541.17887177311788717730',
'1831668727.17885667021788566701',
'1407854105.17886605771788660576'
);




select *
from bi.dbt_production_ga4.clean_session_funnel_events
where session_id in
(
'747876870.17884476001788447597',
'297763564.17884453321788445331'
);


update bi.dbt_production_ga4.clean_session_funnel_events
set product = 'Goodnight Name, Goodnight Everyone',
    funnel_type = 'product',
    funnel_step = 'creation'
where event_interaction_key in
(
'1788445331726587#page_view#297763564.1788445332#1#page view',
'1788447601090735#page_view#747876870.1788447600#1#page view'
);




select reached_creation, first_product_page_path_seen, first_product_seen
from bi.dbt_production_ga4.preprocess_session_funnel_events
where session_id in
(
'747876870.17884476001788447597',
'297763564.17884453321788445331' 
);


update bi.dbt_production_ga4.preprocess_session_funnel_events
set reached_creation = 1,
    first_product_page_path_seen = '/uk/landing-pages/personalized-products/product/good-night-everyone-book-op808',
    first_product_seen = 'Goodnight Name, Goodnight Everyone'
where session_id in
(
'747876870.17884476001788447597',
'297763564.17884453321788445331' 
);





update bi.dbt_production_ga4.preprocess_session_funnel_events
set reached_creation = 1,
    first_product_page_path_seen = '/kr/personalized-products/when-you-were-born-book-op808',
    first_product_seen = 'When You Were Born'
where session_id = '1078108494.17885817021788581700';



update bi.dbt_production_ga4.preprocess_session_funnel_events
set reached_creation = 1,
    first_product_page_path_seen = '/my/personalized-products/when-you-were-born-book-op808',
    first_product_seen = 'When You Were Born'
where session_id = '1466551148.17885816991788581697';