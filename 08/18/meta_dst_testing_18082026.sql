SELECT * 
FROM bi.dbt_production_intermediate.int_facebook_structured_reports
LIMIT 1000;



SELECT SUM(cost)
FROM bi.mark_dev.int_cost_per_interaction;

--130,497,238.153269
--130,150,481.048736
--130,150,481.048736

SELECT *
FROM bi.dbt_production_intermediate.int_cost_per_interaction
limit 1000;

--130,147,218.544632

--350,020
-- -3263


SELECT SUM(cost)
FROM bi.mark_dev.int_cost_per_interaction
WHERE ad_key NOT LIKE 'facebook%';
--60,401,735.2531374

SELECT SUM(cost)
FROM bi.dbt_production_intermediate.int_cost_per_interaction
WHERE ad_key NOT LIKE 'facebook%';
--60,401,735.2531374


with cte1 as(
SELECT SUM(cost) as cost, substr(day, 1, 6) as yearmonth
FROM bi.mark_dev.int_cost_per_interaction
WHERE ad_key LIKE 'facebook%'
GROUP BY yearmonth
),
cte2 as(
SELECT SUM(cost) as cost, substr(day, 1, 6) as yearmonth
FROM bi.dbt_production_intermediate.int_cost_per_interaction
WHERE ad_key LIKE 'facebook%'
GROUP BY yearmonth
)
select cte1.yearmonth, round(cte1.cost - cte2.cost, 0) as diff, cte1.cost, cte2.cost
from cte1
inner join cte2
on cte1.yearmonth = cte2.yearmonth
order by cte1.yearmonth desc;



select to_date(to_varchar(day), 'yyyymmdd')
FROM bi.dbt_production_intermediate.int_cost_per_interaction
limit 1000;


undrop table bi.dbt_production_intermediate.int_cost_per_interaction;





-- 1. Move the live table aside
ALTER TABLE bi.dbt_production_intermediate.int_cost_per_interaction RENAME TO bi.dbt_production_intermediate.int_cost_per_interaction_current;

-- 2. Restore the most recently dropped version (comes back under the original name)
UNDROP TABLE bi.dbt_production_intermediate.int_cost_per_interaction;

-- 3. Give the restored version its new name
ALTER TABLE bi.dbt_production_intermediate.int_cost_per_interaction RENAME TO bi.dbt_production_intermediate.int_cost_per_interaction_backup;

-- 4. Put the live table back
ALTER TABLE bi.dbt_production_intermediate.int_cost_per_interaction_current RENAME TO bi.dbt_production_intermediate.int_cost_per_interaction;