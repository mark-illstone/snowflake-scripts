select count(*), count(distinct order_id), sum(net_revenue), sum(gross_profit), sum(royalty_fees)
from bi.mark_dev.fct_hn_order_items_shopify;

--2872646	405914	98234263.4487465	64457591.3626722	3194875.57349762
--2872646	405914	98234263.4487465	64469108.9626722	3183357.97349762
--2872646	405914	98234263.4487465	64469471.7459292	3182995.19024059

select count(*), count(distinct order_id), sum(net_revenue), sum(gross_profit), sum(royalty_fees)
from bi.historical_newspapers_shopify.fct_order_items;

--2872646	405914	98234263.4487465	64469169.1864565	3183297.74971329
--2872646	405914	98234263.4487465	64469108.9626722	3183357.97349762


--+£11578 royalty fees
-- +£60 royalty fees


select count(*), count(distinct order_id), sum(net_revenue), sum(gross_profit), sum(royalty_fees)
from bi.mark_dev.fct_hn_order_items_shopify
where royalty_name = 'Telegraph'
and paid_at like '2026-09%';

--37314	10260	2156509.08643136	1179595.80071096	168635.122494033

select count(*), count(distinct order_id), sum(net_revenue), sum(gross_profit), sum(royalty_fees)
from bi.historical_newspapers_shopify.fct_order_items
where royalty_name = 'Telegraph'
and paid_at like '2026-09%';

--37314	10260	2156509.08643136	1191173.6244953	157057.298709697



with cte1 as
(
select order_number, royalty_fees as new, paid_at::date as paid_at
from bi.mark_dev.fct_hn_order_items_shopify
where royalty_name = 'Telegraph'
)
,cte2 as
(
select order_number, royalty_fees as old, paid_at::date as paid_at
from bi.historical_newspapers_shopify.fct_order_items
where royalty_name = 'Telegraph'
)
select concat(year(cte1.paid_at), '-', month(cte1.paid_at)) as year_month, sum(cte1.new) as new, sum(cte2.old) as old, round(sum(cte1.new - cte2.old), 0) as diff, 
from cte1
inner join cte2
on cte1.order_number = cte2.order_number
group by 1
order by 1 desc;



select *
from bi.mark_dev.int_hn_finance_royalties_shopify
where line_item_id = '38371749659008';


select *
from bi.historical_newspapers_shopify.int_finance_royalties
where line_item_id = '38371749659008';



select *
from bi.historical_newspapers_shopify.fct_order_items
where order_id = 13501082632576;