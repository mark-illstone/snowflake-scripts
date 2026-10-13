
select count(*), count(distinct order_number), sum(net_Revenue), sum(gross_profit), sum(royalty_fees), sum(product_royalty_fees)
from bi.mark_dev.fct_hn_order_items_shopify;

--2879175	2566078	98760325.0196908	64848329.4191894	3171209.43462994	1434912.10272112

select count(*), count(distinct order_number), sum(net_Revenue), sum(gross_profit), sum(royalty_fees), sum(product_royalty_fees)
from bi.historical_newspapers_shopify.fct_order_items;

--2879175	2566078	98760325.0196908	64813228.8174118	3206310.03640757	1468592.90415054


--33k



with cte as
(
select year(paid_at) as year, month(paid_at) as month, sum(royalty_fees) as new
from bi.mark_dev.fct_hn_order_items_shopify
group by year, month
)
,cte2 as
(
select year(paid_at) as year, month(paid_at) as month, sum(royalty_fees) as old
from bi.historical_newspapers_shopify.fct_order_items
group by year, month
)
select cte.year, cte.month, old, new, old - new as diff
from cte
join cte2
on cte.year = cte2.year
and cte.month = cte2.month
order by cte.year desc, cte.month desc;




select royalty_name, count(*), count(distinct order_number), sum(net_Revenue), sum(gross_profit), sum(product_royalty_fees), sum(addon_deluxe_royalty_fees), sum(cover_royalty_fees)
from bi.mark_dev.fct_hn_order_items_shopify
where paid_at::date between '2026-07-01' and '2026-09-30'
group by royalty_name
order  by royalty_name;
--where addon_deluxe_royalty_name = 'Reuters';

select royalty_name, count(*), count(distinct order_number), sum(net_Revenue), sum(gross_profit), sum(product_royalty_fees), sum(addon_deluxe_royalty_fees), sum(cover_royalty_fees)
from bi.historical_newspapers_shopify.fct_order_items
where paid_at::date between '2026-07-01' and '2026-09-30'
group by royalty_name
order  by royalty_name;
--where addon_deluxe_royalty_name = 'Reuters';



select royalty_name, order_number, royalty_fees, product_royalty_fees, addon_deluxe_royalty_fees, cover_royalty_fees
from bi.mark_dev.fct_hn_order_items_shopify
where paid_at::date between '2026-07-01' and '2026-09-30'
and royalty_name = 'Gannett';