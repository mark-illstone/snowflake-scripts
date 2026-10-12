select order_number, order_item_id, calculated_royalty_value, royalty_fees, (royalty_fees / calculated_royalty_value) * 100 as percentage, royalty_fees / 0.18 as original_value
from bi.mark_dev.fct_order_items
where royalty_fees > 0
--and order_item_id = 21348153
--and round(percentage, 0) != 18
limit 1000;


select count(*), count(distinct order_number), sum(net_revenue), sum(royalty_fees)
from bi.mark_dev.fct_order_items;

--13797228	10137183	403117309.21583	1678662.45609104


select count(*), count(distinct order_number), sum(net_revenue), sum(royalty_fees)
from bi.dbt_production_models.fct_order_items;

--13797228	10137183	403117309.21583	1678662.45609104