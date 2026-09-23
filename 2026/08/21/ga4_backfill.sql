CREATE OR REPLACE TRANSIENT TABLE bi.mark_dev.page_registry_210826 CLONE bi.dbt_production_ga4.page_registry;

UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Where Are You? Grown-up Edition' WHERE product_name = 'where-are-you-adult';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'How to Make a Name-tini' WHERE product_name = 'cocktail-recipe-boo';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'This Months Child' WHERE product_name = 'this-months-child-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'When You Were Born' WHERE product_name = 'when-you-were-born-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Name O Sauras' WHERE product_name = 'personalized-dinosaur-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'How to Make a Name-tini' WHERE product_name = 'how-to-make-a-nametini-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'This Months Child' WHERE product_name = 'months-child-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'I Spy You' WHERE product_name = 'i-spy-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'I Spy You' WHERE product_name = 'i-spy-you-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Where Are You' WHERE product_name = 'where-are-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Lost My Name' WHERE product_name = 'lost-my-name';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Birthday for You' WHERE product_name = 'birthday-for-you-boo';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Where Are You' WHERE product_name = 'where-are-you-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Name O Sauras' WHERE product_name = 'personalised-dinosaur-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'My Big Sibling' WHERE product_name = 'my-big-sibling-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Oh, What Parents You''ll Be' WHERE product_name = 'oh-what-parents-youll-be-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'How to Make a Name-tini' WHERE product_name = 'cocktail-recipe-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Best Cat Ever' WHERE product_name = 'best-cat-ever-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Birthday for You' WHERE product_name = 'birthday-for-you-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Bedtime for Name' WHERE product_name = 'bedtime-for-name-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'I Spy You' WHERE product_name = 'i-spy-you-search-and-find-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Birthday Thief' WHERE product_name = 'the-birthday-thief-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'How to Cook a Name Burger' WHERE product_name = 'burger-recipe-book';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'That''s MY Cake' WHERE product_name = 'thats-my-cake';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Valentine Edition' WHERE product_name = 'poetry-valentines-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Birthday Edition' WHERE product_name = 'poetry-birthday-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Graduation Edition' WHERE product_name = 'poetry-graduation-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Retirement Edition' WHERE product_name = 'poetry-retirement-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Anniversary Edition' WHERE product_name = 'poetry-anniversary-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Wedding Edition' WHERE product_name = 'poetry-wedding-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: Christmas Edition' WHERE product_name = 'poetry-christmas-edition';
UPDATE bi.dbt_production_ga4.page_registry SET product_name = 'Poems for You: New Parents Edition' WHERE product_name = 'poetry-new-parents-edition';



CREATE OR REPLACE TRANSIENT TABLE bi.mark_dev.clean_session_funnel_events_210826 CLONE bi.dbt_production_ga4.clean_session_funnel_events;

select count(*) from bi.mark_dev.clean_session_funnel_events_210826;

update bi.dbt_production_ga4.clean_session_funnel_events a
set a.product = b.product_name
from bi.dbt_production_ga4.page_registry b
where concat(a.product_page_path, '?-') = b.page_location_id
and a.funnel_type = 'product'
and a.funnel_step = 'creation'
and a.product RLIKE '[a-z-]+';

--ALTER TABLE bi.dbt_production_ga4.clean_session_funnel_events SWAP WITH bi.mark_dev.clean_session_funnel_events_210826;



CREATE OR REPLACE TRANSIENT TABLE bi.mark_dev.preprocess_session_funnel_events_210826 CLONE bi.dbt_production_ga4.preprocess_session_funnel_events;

select count(*) from bi.mark_dev.preprocess_session_funnel_events_210826;

update bi.dbt_production_ga4.preprocess_session_funnel_events a
set a.first_product_seen = b.product_name
from bi.dbt_production_ga4.page_registry b
where concat(a.first_product_page_path_seen, '?-') = b.page_location_id
and a.first_product_seen RLIKE '[a-z-]+';