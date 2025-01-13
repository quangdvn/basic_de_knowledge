CREATE TABLE array_metrics (
  user_id NUMERIC,
  month_start DATE,
  metric_name VARCHAR(255),
  metric_array REAL[],
  PRIMARY KEY (user_id, month_start, metric_name)
)

WITH daily_aggregate AS (
  SELECT
    user_id,
    DATE(event_time) as date,
    COUNT(1) AS num_site_hits
  FROM events
  WHERE DATE(event_time) = DATE('2023-01-03') and user_id is not null
  GROUP BY user_id, DATE(event_time)
), yesterday_array as (
	select * from array_metrics am 
	where month_start = date('2023-01-01')
)

insert into array_metrics
SELECT 
	coalesce(da.user_id, ya.user_id) as user_id,
	coalesce(ya.month_start, date_trunc('month', da.date)) as month_start,
	'site_hits' as metric_name, --usually hard-coded
	case when ya.metric_array is not null 
		then ya.metric_array || ARRAY[coalesce(da.num_site_hits, 0)] -- first index will be the 1st day of a month
	when ya.metric_array is null 
		then array_fill(0, array[coalesce(date - date(date_trunc('month', date)), 0)]) -- Remember to backfill data if one data appears in the middle
			|| 
			ARRAY[coalesce(da.num_site_hits, 0)]
	end as metric_array
FROM daily_aggregate da
full outer join yesterday_array ya 
on da.user_id = ya.user_id
on conflict (user_id, month_start, metric_name) -- Alternative for overwrite
do
	update set metric_array = excluded.metric_array

--- Verify whether data is backfilled
select * from array_metrics am 

select cardinality(metric_array), count(1)
from array_metrics am 
group by 1
