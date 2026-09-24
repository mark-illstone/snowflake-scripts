select *
from BI.GOOGLE_SHEETS.OPS_UNIT_FORECAST;
--where gb_deluxe_format is not null
--and gb_deluxe_units > 0


SELECT * 
FROM bi.dbt_production_intermediate.int_finance_addons
where generic_sku like '%GB%'
limit 1000;



select *
from bi.mark_dev.fct_ops_unit_forecast
where gift_box_deluxe_actual > 0
limit 1000;


select count(*), sum(units), sum(gw_units), sum(gb_units), sum(gb_deluxe_units), sum(units_actual), sum(gift_wrap_actual), sum(gift_box_actual), sum(gift_box_deluxe_actual)
from bi.mark_dev.fct_ops_unit_forecast
where phasing_date between '2026-01-01' and '2026-09-23';

--433643	3585367.1404	528055.65919	301443.2424	42071.0282	1942769	264692	159456	5276
--221720	858979.001	116919.49069	77454.2428	6752.8958	771524	131540	62438	5276

select count(*), sum(units), sum(gw_units), sum(gb_units), sum(gb_deluxe_units), sum(units_actual), sum(gift_wrap_actual), sum(gift_box_actual), sum(gift_box_deluxe_actual)
from bi.dbt_production_models.fct_ops_unit_forecast
where phasing_date between '2026-01-01' and '2026-09-23';

--433643	3585367.1404	528055.65919	301443.2424	42071.0282	1942769	264692	159456	3766
--221720	858979.001	116919.49069	77454.2428	6752.8958	771524	131540	62438	3766



select gb_deluxe_format, sum(gb_deluxe_units), sum(gift_box_deluxe_actual)
from bi.dbt_production_models.fct_ops_unit_forecast
where phasing_date between '2026-09-01' and '2026-09-23'
group by 1
order by 1;


SELECT distinct generic_sku
FROM bi.dbt_production_intermediate.int_finance_addons
--where generic_sku = 'GB Tabloid LRG Deluxe'
order by 1
limit 1000;



select gb_deluxe_format, sum(gb_deluxe_units), sum(gift_box_deluxe_actual)
from bi.mark_dev.fct_ops_unit_forecast
where phasing_date between '2026-09-01' and '2026-09-23'
group by 1
order by 1;