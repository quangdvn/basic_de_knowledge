-- Dimensional analytic
with agg as (
	select 
	metric_name, 
	month_start, 
	array[
		sum(metric_array[1]), 
		sum(metric_array[2]), 
		sum(metric_array[3])
	] as summed_array
	from array_metrics am 
	group by 1, 2
)

select 
	metric_name,
	month_start + cast(cast(index - 1 as text) || ' day' as interval) as date,
	elem as value
from agg cross join unnest(agg.summed_array)
with ordinality as a(elem, index)
