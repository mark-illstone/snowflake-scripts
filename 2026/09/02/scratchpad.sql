select *
from bi.dbt_production_models.fct_marketing_attribution
where ad_key = 'google@cpc@uk_en_search_nb_evergreen@(none)@(none)';


SELECT * FROM bi.dbt_production_models.dim_countries;


SELECT * FROM bi.dbt_production_models.fct_ad_performance 
where attribution_model = 'last_click_28d_interactions'
and ad_key = 'google@cpc@uk_en_search_nb_evergreen@(none)@(none)';

select *
from bi.dbt_production_intermediate.int_attributed_interactions
where ad_key = 'google@cpc@uk_en_search_nb_evergreen@(none)@(none)';


select *
from bi.dbt_production_intermediate.int_cost_per_interaction
where ad_key = 'google@cpc@uk_en_search_nb_evergreen@(none)@(none)';