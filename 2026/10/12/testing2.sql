select count(*), count(distinct order_number), sum(net_Revenue), sum(gross_profit), sum(royalty_fees), sum(product_royalty_fees)
from bi.mark_dev.fct_hn_order_items_shopify;

--2879175	2566078	98760325.0196908	64820680.9081392	3198857.94568009	1461140.81342306

select count(*), count(distinct order_number), sum(net_Revenue), sum(gross_profit), sum(royalty_fees), sum(product_royalty_fees)
from bi.historical_newspapers_shopify.fct_order_items;

--2879175	2566078	98760325.0196908	64816772.5666066	3202766.28721275	1465049.15495572

-- -31,557


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