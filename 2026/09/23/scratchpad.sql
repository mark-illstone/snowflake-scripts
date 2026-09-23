SELECT sum(cost), sum(clicks), sum(impressions)
FROM bi.mark_dev.fct_plucky_marketing_performance;

select count(*), ad_key, day
from bi.mark_dev.fct_plucky_marketing_performance
group by all
having count(*)>1;

select *
from bi.mark_dev.fct_plucky_marketing_performance
order by day, ad_key;