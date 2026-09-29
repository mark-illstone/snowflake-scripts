select *
from bi.dbt_production_models.fct_facebook_granular_data
order by created_date desc
limit 1000;


-- Mixed_ASC_150526__IT_18_Plus_MF_Conversions_7Dclick1Deng_
-- Prospecting_ASC_IT_Mixed_150526_Conversion_Evergreen
-- EN_MBS_Keepsake_LongVid_160926_Walkthrough_VeryBoringBedtimeRoutine_UGC___Partnership_mama.lyssss_F30-40_US-EN___New__ProductPage_____
-- EN_MBS_Kids_LongVid_080926_POV_NobodyWarnedMe_UGC___Catalyst_Presley_F20-30_US-EN_ToyFatigueParent__New__ProductPage_Wave10___Parent_1-3


select *
from bi.mark_dev.fct_facebook_granular_data
where ad_age_range != ''
order by created_date desc
limit 1000;


select sum(gb_luxury_actual)
from bi.mark_dev.fct_hn_ops_unit_forecast_shopify;


select sum(gb_luxury_actual)
from bi.historical_newspapers_shopify.fct_ops_unit_forecast;



select count(*)
from bi.historical_newspapers_shopify.fct_order_items
where addon_giftbox_sku = 'giftwrap:giftbox-tabloid:hn-premium';


select count(*)
from bi.historical_newspapers_shopify.fct_order_items
where addon_giftbox_sku = 'giftwrap:giftbox-tabloid-hn:deluxe';