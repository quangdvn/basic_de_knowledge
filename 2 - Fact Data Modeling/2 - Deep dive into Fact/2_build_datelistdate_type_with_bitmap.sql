-- Create bitmap list for 30 days
-- Left most bit is the recent date
with users as (
	select * from users_cumulated
	where date = date('2023-01-30')
), series as (
	select * 
	from generate_series(DATE('2023-01-01'), DATE('2023-01-30'), interval '1 day') as series_date
), placeholder_ints as (
	select
		case when dates_active @> array[DATE(series_date)]
			then CAST(pow(2, 29 - (date - DATE(series_date))) as BIGINT) -- how many days between this active date and today
			--then date - DATE(series_date)
			else 0
		end 
		as placeholder_int_value,
		*
	from users u
	cross join series 
	--where user_id = '137925124111668560'
)
select
	user_id,
	cast(cast(sum(placeholder_int_value) as BIGINT) as bit(30)),
	bit_count(cast(cast(sum(placeholder_int_value) as BIGINT) as bit(30))) > 0 as dim_is_monthly_active,
	-- Use BITWISE AND logic to create a bitmap of active status
	bit_count(cast('111111100000000000000000000000' as bit(30)) & cast(cast(sum(placeholder_int_value) as BIGINT) as bit(30))) > 0 as dim_is_monthly_active,
	bit_count(cast('100000000000000000000000000000' as bit(30)) & cast(cast(sum(placeholder_int_value) as BIGINT) as bit(30))) > 0 as dim_is_daily_active
from placeholder_ints
group by user_id