--testing_300726_2

select count(*), count(distinct original_order_id)
from bi.mark_dev.fct_plucky_reordered_shopify;


select count(*), count(distinct original_order_id)
from bi.plucky_shopify.fct_reorders;
--1	1


select *
from bi.mark_dev.fct_plucky_reordered_shopify;

select *
from bi.plucky_shopify.fct_reorders;


bi.mark_dev.fct_hn_reorders_shopify
bi.historical_newspapers_shopify.fct_reorders


select count(*), count(distinct original_order_id)
from bi.mark_dev.fct_hn_reorders_shopify;
--12677	6500

select count(*), count(distinct original_order_id)
from bi.historical_newspapers_shopify.fct_reorders;
--12673	6498



select count(*), concat(original_order_id,original_line_item_id, replacement_line_item_id) as line_item_pair
from bi.mark_dev.fct_hn_reorders_shopify
where original_line_item_id is not null and replacement_line_item_id is not null
group by 2
having count(*) > 1;



select *
from bi.mark_dev.fct_hn_reorders_shopify
where concat(original_order_id,original_line_item_id, replacement_line_item_id) = '117546103279363494268013811234942773428608';


with cte as (
select *, row_number() over(partition by original_order_id, original_line_item_id, replacement_line_item_id order by original_order_id) as rn
from bi.mark_dev.fct_hn_reorders_shopify
),
cte2 as (
select *, row_number() over(partition by original_order_id, original_line_item_id, replacement_line_item_id order by original_order_id) as rn
from bi.historical_newspapers_shopify.fct_reorders
)
select * 
from cte
left join cte2
on cte.original_order_id = cte2.original_order_id
and cte.original_line_item_id = cte2.original_line_item_id
and cte.replacement_line_item_id = cte2.replacement_line_item_id
where cte.rn = cte2.rn
and cte2.rn is null;




select *
from bi.mark_dev.fct_hn_reorders_shopify
where original_order_id in (13323018043776, 13037693632896);


select *
from bi.historical_newspapers_shopify.fct_reorders
where original_order_id in (13323018043776, 13037693632896);