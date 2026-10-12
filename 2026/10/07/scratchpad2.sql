select *
from bi.google_sheets.ops_fc_country_mapping;



select sum(units_actual)
from bi.historical_newspapers_shopify.fct_ops_unit_forecast;


select sum(units_actual)
from bi.dbt_production_models.fct_ops_unit_forecast;