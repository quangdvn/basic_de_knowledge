create table players_scd (
	player_name text,
	scoring_class scoring_class,
	is_active BOOLEAN,
	start_season INTEGER,
	end_season INTEGER,
	current_season INTEGER, -- state
	primary key(player_name, start_season)
)
----------------------------------------------------------------------------------------------------------------
-- Scan the whole history everyday
-- Prone to "Out of memory" error
-- Work with millions of row of data
-- Can't work with billions of row of data
insert into players_scd
with with_previous as (
	select 
		player_name,
		current_season,
		scoring_class, 
		is_active,
		LAG(scoring_class, 1) over (partition by player_name order by current_season) as previous_scoring_class,
		LAG(is_active, 1) over (partition by player_name order by current_season) as previous_is_active
	from players
	where current_season <= 2021
),
with_indicators as (
	select *,
		case 
			WHEN scoring_class::TEXT <> previous_scoring_class::TEXT THEN 1
			WHEN is_active <> previous_is_active then 1
			else 0
		end as change_indicator
	from with_previous
),
with_streak_identifier as (
	select *,
		sum(change_indicator) over (partition by player_name order by current_season) as streak_identifier 
	from with_indicators
)
select
	player_name,
	scoring_class,
	is_active,
	MIN(current_season) as start_season,
	MAX(current_season) as end_season,
	2021 as current_season
from with_streak_identifier
group by player_name, streak_identifier, is_active, scoring_class
order by player_name, streak_identifier