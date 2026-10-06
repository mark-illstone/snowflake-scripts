select count(*), count(distinct order_number), sum(net_revenue), sum(gross_profit), sum(adjusted_price_without_addons), sum(royalty_fees)
from bi.mark_dev.fct_hn_order_items_shopify
limit 1000;

--2873727	2561338	98320655.6286122	64526310.2152176	78854052.6913355	3186730.10509575

select count(*), count(distinct order_number), sum(net_revenue), sum(gross_profit), sum(adjusted_price_without_addons), sum(royalty_fees)
from bi.historical_newspapers_shopify.fct_order_items
limit 1000;

--2873727	2561338	98320655.6286122	64526235.9902372	78853754.0841651	3186804.33007617

-- -298 value
-- -74 fees



select adjusted_price_without_addons, royalty_fees, order_id
from bi.mark_dev.fct_hn_order_items_shopify
where order_number in
(
'#HN847992',
'#HN834873',
'#HN862234',
'#HN856728',
'#HN836591',
'#HN833235',
'#HN833682',
'#HN855671',
'#HN835826',
'#HN841446',
'#HN858797',
'#HN833986',
'#HN852864',
'#HN829562',
'#HN864781',
'#HN845315',
'#HN857151',
'#HN848556',
'#HN856450',
'#HN833679',
'#HN867382',
'#HN833235',
'#HN854411',
'#HN841989',
'#HN855693',
'#HN839335',
'#HN833339',
'#HN834537',
'#HN833684',
'#HN837196',
'#HN838179',
'#HN834822',
'#HN861093',
'#HN840502',
'#HN846634',
'#HN854838',
'#HN864781',
'#HN848475',
'#HN829367',
'#HN841892',
'#HN840534',
'#HN854021',
'#HN836824',
'#HN858739',
'#HN858524',
'#HN839807',
'#HN853197',
'#HN866236',
'#HN839986',
'#HN837567'
)
order by 2
limit 1000;