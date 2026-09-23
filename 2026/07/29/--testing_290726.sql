--testing

select sum(amount_spent) as total_spent
from bi.mark_dev.fct_facebook_granular_data;
--29,237,572.89

select sum(amount_spent) as total_spent
from bi.dbt_production_models.fct_facebook_granular_data;
--29,266,926.87

--£29,354

select count(DISTINCT ad_id, day)
from bi.mark_dev.fct_facebook_granular_data
where keepsake_kids IS NOT NULL;
--700,205 / 781,194  = 89.63%

select count(DISTINCT ad_id, day)
from bi.dbt_production_models.fct_facebook_granular_data
where keepsake_kids IS NOT NULL;
--562176 / 781,194 = 71.96%

--increase of 17.67% in the number of rows with keepsake_kids populated





select sum(cost) as total_spent
from bi.mark_dev.fct_granular_google_pmax;
--11,821,124.551546

select sum(cost) as total_spent
from bi.dbt_production_models.fct_granular_google_pmax;
--11,879,818.449316

--£58,694

select count(DISTINCT campaign_id, day, product_item_id)
from bi.mark_dev.fct_granular_google_pmax
where keepsake_kids IS NOT NULL;
--4,404,497 / 4,859,923  = 90.62%

select count(DISTINCT campaign_id, day, product_item_id)
from bi.dbt_production_models.fct_granular_google_pmax
where keepsake_kids IS NOT NULL;
--3,704,682 / 4,860,654 = 76.21%

--increase of 14.41% in the number of rows with keepsake_kids populated






select sum(cost), count(*) as total_spent
from bi.mark_dev.fct_granular_google_shopping;
--17,277,099.136694     10995238

select sum(cost), count(*) as total_spent
from bi.dbt_production_models.fct_granular_google_shopping;
--17,436,176.700977     10997114

--£159,077      1,876 rows difference

select count(DISTINCT campaign_id, day, product_item_id)
from bi.mark_dev.fct_granular_google_shopping
where keepsake_kids IS NOT NULL;
--9,363,468 / 10,895,265  = 85.94%

select count(DISTINCT campaign_id, day, product_item_id)
from bi.dbt_production_models.fct_granular_google_shopping
where keepsake_kids IS NOT NULL;
--7,794,732 / 10,897,012 = 71.54%

--increase of 14.39% in the number of rows with keepsake_kids populated


--Overall increase of 15.49% in the number of rows with keepsake_kids populated across all platforms




select sum(cost), count(*) as total_spent
from bi.mark_dev.fct_granular_google_campaigns;
--2,252,142,253.551881	    2,160,309

select sum(cost), count(*) as total_spent
from bi.dbt_production_models.fct_granular_google_campaigns;
--48,012,639.19471	1,663,898

--£159,077      1,876 rows difference
