select net_revenue_shipping
from bi.mark_dev.fct_order_items
where order_number = '#HN606176';

select discounted_shipment_price, local_discounted_shipment_price
from bi.mark_dev.int_temp_finance_units
where order_id = '12299302928768';

select net_revenue_shipping
from bi.mark_dev.int_finance_units_profit_and_loss
where order_id = '12299302928768';



select count(*), count(distinct order_number), sum(net_revenue) as total_net_revenue, sum(net_revenue_shipping) as total_net_revenue_shipping, sum(royalty_fees) as total_royalty_fees
from bi.mark_dev.fct_order_items;
--2844950	2535125	96034589.0115723	13867425.3322226


select count(*), count(distinct order_number), sum(net_revenue) as total_net_revenue, sum(net_revenue_shipping) as total_net_revenue_shipping, sum(royalty_fees) as total_royalty_fees
from bi.historical_newspapers_shopify.fct_order_items;