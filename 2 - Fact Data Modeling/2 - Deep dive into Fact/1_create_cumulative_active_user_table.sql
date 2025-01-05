create table users_cumulated(
	user_id TEXT, --- Overcome the biggest INT type
	dates_active DATE[], --- The list of dates in the past where the user was active
	date DATE, -- The current date for the user
	primary key (user_id, date)
)

-- Almost identical to the approach of cumulative table design
insert into users_cumulated
with yesterday as (
	select * from users_cumulated
	where date = DATE('2023-01-29')
), today as (
	select 
		cast(user_id as text) as user_id,
		DATE(CAST(e.event_time as timestamp)) AS date_active
	from events e 
	where DATE(CAST(e.event_time as timestamp)) = date('2023-01-30') and user_id is not NULL
	group by user_id, DATE(CAST(e.event_time as timestamp))
)
select 
	coalesce(t.user_id, y.user_id) as user_id,
	case when y.dates_active is null
			then array[t.date_active]
		when t.date_active is null 
			then y.dates_active
		else array[t.date_active] || y.dates_active -- CONCAT
	end
	as dates_active,
	coalesce(t.date_active, y.date + interval '1 day') as date -- y.date is yesterday's current_date value
from today t 
	full outer join yesterday y
	on t.user_id = y.user_id