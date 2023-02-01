-- This code cleans the raw goal tables created by your google sheets > BigQuery ingests, and unions all week into the same goal table. SL and FO goals remain in two distinct tables.
-- Find and replace xx with your state code. 
drop table if exists xx_cc_2022.xx_gotv_sl_goals_2022;
create table xx_cc_2022.xx_gotv_sl_goals_2022 as select * from (
SELECT
date(2022,10,7) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_oct7_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,10,14) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_oct14_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,10,21) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_oct21_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,10,28) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_oct28_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,11,5) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_nov5_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,11,6) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_nov6_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,11,7) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_nov7_sl_goals_raw
where staging_location_name is not null

union all

SELECT
date(2022,11,8) as reporting_week
, state_code
,region_name
,staging_location_name
, door_shifts_scheduled
, door_shifts_completed
, phone_shifts_scheduled
, phone_shifts_completed
, doors_attempted
FROM demsdscc.xx_cc_2022.xx_nov8_sl_goals_raw
where staging_location_name is not null
);


drop table if exists xx_cc_2022.xx_gotv_fo_goals_2022;
create table xx_cc_2022.xx_gotv_fo_goals_2022 as select * from (
SELECT
date(2022,10,7) as reporting_week,
state_code,
region_name,
fo_name,
cast(myc_calls as integer) as myc_calls,
cast(active_vols as integer) as active_vols
FROM `demsdscc.xx_cc_2022.xx_oct7_fo_goals_raw`
where region_name not in ('Region')


union all

SELECT
date(2022,10,14) as reporting_week,
state_code,
region_name,
fo_name,
cast(myc_calls as integer) as myc_calls,
cast(active_vols as integer) as active_vols
FROM `demsdscc.xx_cc_2022.xx_oct14_fo_goals_raw`
where region_name not in ('Region')

union all

SELECT
date(2022,10,21) as reporting_week,
state_code,
region_name,
fo_name,
cast(myc_calls as integer) as myc_calls,
cast(active_vols as integer) as active_vols
FROM `demsdscc.xx_cc_2022.xx_oct21_fo_goals_raw`
where region_name not in ('Region')

union all

SELECT
date(2022,10,28) as reporting_week,
state_code,
region_name,
fo_name,
cast(myc_calls as integer) as myc_calls,
cast(active_vols as integer) as active_vols
FROM `demsdscc.xx_cc_2022.xx_oct28_fo_goals_raw`
where region_name not in ('Region')




);
