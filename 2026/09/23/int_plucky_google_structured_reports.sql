with campaigns as (select * from bi.historical_newspapers.int_google_campaigns_daily)

select ad_key
     , to_char(day::date,'YYYYMMDD')::int as day
     , NVL(cost, 0) as cost
     , NVL(impressions, 0) as impressions
     , NVL(clicks, 0) as clicks
     , NULL as commissions
from campaigns