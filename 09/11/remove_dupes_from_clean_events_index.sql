select count(*), event_key
from bi.dbt_production_ga4.clean_events_index
where to_date(event_timestamp)>= '2026-09-08'
group by event_key
having count(*) > 1
limit 1000;

select *, row_number() over(partition by event_key order by event_key) as rn
from bi.dbt_production_ga4.clean_events_index
where event_key in
(
'1789070114624622#first_visit#1988464544.1789070115#1',
'1789070260331416#page_view#1988464544.1789070115#1',
'1789070114663125#optimizely-decision-fs#1988464544.1789070115#1',
'1789070260244758#search#1988464544.1789070115#1',
'1789070260367833#optimizely-decision-fs#1988464544.1789070115#1',
'1789070114623187#search#1988464544.1789070115#1',
'1789070114624622#page_view#1988464544.1789070115#1',
'1789070114624622#session_start#1988464544.1789070115#1'
);


create temporary table tmp_dedup as
select *
from bi.dbt_production_ga4.clean_events_index
where event_key in (
    '1789070114624622#first_visit#1988464544.1789070115#1',
    '1789070260331416#page_view#1988464544.1789070115#1',
    '1789070114663125#optimizely-decision-fs#1988464544.1789070115#1',
    '1789070260244758#search#1988464544.1789070115#1',
    '1789070260367833#optimizely-decision-fs#1988464544.1789070115#1',
    '1789070114623187#search#1988464544.1789070115#1',
    '1789070114624622#page_view#1988464544.1789070115#1',
    '1789070114624622#session_start#1988464544.1789070115#1'
)
qualify row_number() over(partition by event_key order by event_key) = 1;

-- 2. Delete all rows for those keys (both copies)
delete from bi.dbt_production_ga4.clean_events_index
where event_key in 
(
    '1789070114624622#first_visit#1988464544.1789070115#1',
    '1789070260331416#page_view#1988464544.1789070115#1',
    '1789070114663125#optimizely-decision-fs#1988464544.1789070115#1',
    '1789070260244758#search#1988464544.1789070115#1',
    '1789070260367833#optimizely-decision-fs#1988464544.1789070115#1',
    '1789070114623187#search#1988464544.1789070115#1',
    '1789070114624622#page_view#1988464544.1789070115#1',
    '1789070114624622#session_start#1988464544.1789070115#1'
);

-- 3. Put the single copies back
insert into bi.dbt_production_ga4.clean_events_index
select * from tmp_dedup;