SELECT * 
FROM bi.google_sheets.ops_addon_unit_forecast
WHERE solidus_sku = 'giftwrap:giftbox-square:large-deluxe';


SELECT * 
FROM bi.dbt_production_intermediate.int_variants
WHERE sku = 'giftwrap:giftbox-square:large-deluxe';


SELECT * 
FROM bi.dbt_production_intermediate.int_orders_deduplication
where id = 1787604;



SELECT * 
FROM bi.dbt_production_intermediate.int_addons a
LEFT JOIN bi.dbt_production_intermediate.int_variants b
    ON a.sku = b.sku
left join bi.google_sheets.ops_addon_unit_forecast c
on b.sku = c.solidus_sku
and a.created_at::date between c.effective_date_from and c.effective_date_to
where a.order_id = 1787604;



select number, created_at, process_at, completed_at, id
from bi.fivetran_eagle_public.spree_orders
where number in
(
'R136969229',
'R081159684',
'R289908169',
'R694024661',
'R043378344',
'R996048747',
'R081393555',
'R959584747',
'R246723218',
'R099143687',
'R936236779',
'R091662775',
'R830543763',
'R588310658',
'R040925215',
'R922694211',
'R364362028'
);



select number, created_at, process_at, completed_at
from bi.fivetran_eagle_public.spree_orders
where completed_at is not null
order by completed_at desc
limit 1000;


select *
from bi.mark_dev.int_finance_addons
where order_number in
(
'R136969229',
'R081159684',
'R289908169',
'R694024661',
'R043378344',
'R996048747',
'R081393555',
'R959584747',
'R246723218',
'R099143687',
'R936236779',
'R091662775',
'R830543763',
'R588310658',
'R040925215',
'R922694211',
'R364362028'
);



select count(*), sum(local_price)
from bi.mark_dev.int_finance_addons;

--14219400	175953007.27


select count(*), sum(local_price)
from bi.dbt_production_intermediate.int_finance_addons;

--14219389	175952953.27




select *
from bi.dbt_production_intermediate.int_finance_addons
where order_number in
(
'R136969229',
'R081159684',
'R289908169',
'R694024661',
'R043378344',
'R996048747',
'R081393555',
'R959584747',
'R246723218',
'R099143687',
'R936236779',
'R091662775',
'R830543763',
'R588310658',
'R040925215',
'R922694211',
'R364362028'
);



alter table bi.mark_dev.int_finance_addons_new rename to bi.dbt_production_intermediate.int_finance_addons;

drop table bi.dbt_production_intermediate.int_finance_addons;