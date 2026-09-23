select count(*), market, sum(amount_spent)
from bi.dbt_production_intermediate.int_facebook_categorised
where day between '2026-08-17' and '2026-08-23'
and meta_ad_type = 'Meta DPA'
group by market
order by market;


select *
from bi.dbt_production_intermediate.int_facebook_categorised
limit 1000;


select *
from bi.dbt_production_intermediate.int_facebook_categorised
where day between '2026-08-17' and '2026-08-23'
and campaign_name = 'Prospecting_ASC_Global_Mixed_060126_Conversion_Seasonal';

select *
from bi.mark_dev.int_facebook_categorised
where day between '2026-08-17' and '2026-08-23'
and campaign_name = 'Prospecting_ASC_Global_Mixed_060126_Conversion_Seasonal';



SELECT campaign_id, max(updated_campaign_name) as campaign_name 
FROM bi.google_sheets.facebook_campaign_names 
WHERE campaign_name = 'Prospecting_ASC_Global_Mixed_060126_Conversion_Seasonal'
group by all;


select *
FROM bi.google_sheets.facebook_campaign_names
--where updated_campaign_name = 'Prospecting_ASC_Global_Mixed_060126_Conversion_Seasonal';
where lower(updated_campaign_name) like '%global%';



select *
from bi.fivetran_facebook_ads_granular.custom_product_id
where product_id like '%newspaper%'
order by date desc
limit 1000;




select sum(cost)
from bi.dbt_production_intermediate.int_all_channels_long
where channel = 'Google PMAX'
and day >= '2026-08-17'
and day < '2026-08-24';

select sum(google_pmax_spend)
from bi.dbt_production_models.fct_paid_marketing_by_channel_pivoted
where google_pmax_spend is not null
and day >= '2026-08-17'
and day < '2026-08-24';

select sum(google_pmax_spend)
from bi.dbt_production_models.fct_marketing_pnl_merged
where google_pmax_spend is not null
and day >= '2026-08-17'
and day < '2026-08-24';


SELECT
    COALESCE(SUM(fct_paid_marketing_by_channel_pivoted."GOOGLE_PMAX_SPEND" ), 0) AS "fct_paid_marketing_by_channel_pivoted.google_pmax_spend"
FROM "BI"."DBT_PRODUCTION_MODELS"."FCT_MARKETING_PNL_MERGED"  AS fct_paid_marketing_by_channel_pivoted
WHERE ((( fct_paid_marketing_by_channel_pivoted."DAY"  ) >= (TO_DATE(TO_TIMESTAMP('2026-08-17'))) AND ( fct_paid_marketing_by_channel_pivoted."DAY"  ) < (TO_DATE(TO_TIMESTAMP('2026-08-24')))));


select sum(cost)
from bi.dbt_production_intermediate.int_base_performance_max_spend
where day >= '2026-08-17'
and day < '2026-08-24';



select * from bi.fivetran_granular_google_ads_3.granular_pmax_daily;



select *
from bi.mark_dev.int_facebook_categorised
where day like '2025-%'
and countries_top_8 = 'ROW'
limit 1000;


select sum(amount_spent), market
from bi.dbt_production_intermediate.int_facebook_categorised
where day like '2025-%'
group by market
order by market;

-- 359770.92001	    AU
-- 313382.990002	CA
-- 191782.09	    ES
-- 238006.470004	ROW-DE
-- 1921631.390208	ROW-EN
-- 122515.009997	ROW-ES
-- 262444.820006	ROW-FR
-- 107597.509998	ROW-JP
-- 109658.889996	ROW-NL
-- 1285789.099985	UK
-- 3348904.420116	US


select sum(amount_spent), market
from bi.mark_dev.int_facebook_categorised
where day like '2025-%'
group by market
order by market;


-- 496873.560013	AU
-- 305875.019999	CA
-- 191782.09	ES
-- 238006.470004	ROW-DE
-- 1288223.980208	ROW-EN
-- 122515.009997	ROW-ES
-- 262444.820006	ROW-FR
-- 107597.509998	ROW-JP
-- 109658.889996	ROW-NL
-- 1404351.799985	UK
-- 3734154.460116	US

-- 496873.560013	AU
-- 305875.019999	CA
-- 191782.09	    ES
-- 238006.470004	ROW-DE
-- 1244648.460208	ROW-EN
-- 122515.009997	ROW-ES
-- 262444.820006	ROW-FR
-- 107597.509998	ROW-JP
-- 114064.569996	ROW-NL
-- 1404351.799985	UK
-- 3773324.300116	US

-- 1787910.079995	AU
-- 305875.019999	CA
-- 191782.09	    ES
-- 238006.470004	ROW-DE
-- 1244648.460208	ROW-EN
-- 122515.009997	ROW-ES
-- 262444.820006	ROW-FR
-- 107597.509998	ROW-JP
-- 114064.569996	ROW-NL
-- 1404351.799985	UK
-- 2482287.780134	US

-- 1792925.459995	AU
-- 305875.019999	CA
-- 191782.09	    ES
-- 673464.740201	ROW-DE
-- 848360.030011	ROW-EN
-- 122515.009997	ROW-ES
-- 262444.820006	ROW-FR
-- 107597.509998	ROW-JP
-- 114064.569996	ROW-NL
-- 1404351.799985	UK
-- 2438102.560134	US

select 
    adset_name, 
    market,
    CASE
            WHEN CONTAINS(adset_name, 'ROW') OR CONTAINS(adset_name, 'GLOBAL') OR CONTAINS(adset_name, '_ALL_') THEN
                CASE
                    WHEN CONTAINS(adset_name, '_JP') OR CONTAINS(adset_name, '-JP') OR CONTAINS(adset_name, 'JP_') THEN 'ROW-JP'
                    WHEN CONTAINS(adset_name, '_DE') OR CONTAINS(adset_name, '-DE') OR CONTAINS(adset_name, 'DE_') THEN 'ROW-DE'
                    WHEN CONTAINS(adset_name, '_NL') OR CONTAINS(adset_name, '-NL') OR CONTAINS(adset_name, 'NL_') THEN 'ROW-NL'
                    WHEN CONTAINS(adset_name, '_ES') OR CONTAINS(adset_name, '-ES') OR CONTAINS(adset_name, 'ES_') THEN 'ROW-ES'
                    WHEN CONTAINS(adset_name, '_FR') OR CONTAINS(adset_name, '-FR') OR CONTAINS(adset_name, 'FR_') THEN 'ROW-FR'
                    ELSE 'ROW-EN'
                END
            WHEN CONTAINS(adset_name, '_UK') OR CONTAINS(adset_name, '-UK') OR CONTAINS(adset_name, '_GBR') OR CONTAINS(adset_name, 'GBR_') OR CONTAINS(adset_name, 'GB_') THEN 'UK'
            WHEN CONTAINS(adset_name, '_US') OR CONTAINS(adset_name, '-US') OR CONTAINS(adset_name, '_USA') OR CONTAINS(adset_name, 'USA_') OR CONTAINS(adset_name, 'US_') THEN 'US'
            WHEN CONTAINS(adset_name, '_AU') OR CONTAINS(adset_name, '-AU') OR CONTAINS(adset_name, '_AUS') OR CONTAINS(adset_name, 'AUS_') OR CONTAINS(adset_name, 'AU_') THEN 'AU'
            WHEN CONTAINS(adset_name, '_CA') OR CONTAINS(adset_name, '-CA') OR CONTAINS(adset_name, '_CAN') OR CONTAINS(adset_name, 'CAN_') OR CONTAINS(adset_name, 'CA_') THEN 'CA'
            WHEN CONTAINS(adset_name, '_FR') OR CONTAINS(adset_name, '-FR') OR CONTAINS(adset_name, '_FRA') OR CONTAINS(adset_name, 'FRA_') OR CONTAINS(adset_name, 'FR_') THEN 'FR'
            WHEN CONTAINS(adset_name, '_ES') OR CONTAINS(adset_name, '-ES') OR CONTAINS(adset_name, '_ESP') OR CONTAINS(adset_name, 'ESP_') OR CONTAINS(adset_name, 'ES_') THEN 'ES'
            WHEN CONTAINS(adset_name, '_IT') OR CONTAINS(adset_name, '-IT') OR CONTAINS(adset_name, '_ITA') OR CONTAINS(adset_name, 'ITA_') OR CONTAINS(adset_name, 'IT_') THEN 'IT'
            WHEN CONTAINS(adset_name, '_DE') OR CONTAINS(adset_name, '-DE') OR CONTAINS(adset_name, '_DEU') OR CONTAINS(adset_name, 'DEU_') OR CONTAINS(adset_name, 'DE_') THEN 'DE'
            ELSE 'ROW-EN'
        END AS country
from bi.mark_dev.int_facebook_categorised
where adset_name = 'AU_GEN_BROAD_MF_2065';



select *
from bi.mark_dev.int_facebook_categorised
where day like '2025-%'
and market = 'ROW-EN'
and adset_name not like '%ROW%'
and adset_name not like '%ALL%'
and campaign_name_gsheet not like '%ROW%'
and campaign_name_gsheet not like '%ALL%'
limit 1000;


select *
from bi.mark_dev.int_facebook_categorised
where day like '2025-%'
and market = 'ROW-EN'
and adset_name not like '%ROW%'
and adset_name not like '%ALL%'
--and campaign_name not like '%ROW%'
--and campaign_name not like '%ALL%'
limit 1000;




SELECT *
FROM bi.google_sheets.marketing_country_grouping;