-- Origin data
select * from player_seasons ps 
order by player_name, season
select count(1) from player_seasons ps2 -- 12869

-- Create struct to group season data of each player
create type season_stats as (
	season INTEGER,
	gp INTEGER,
	pts real,
	reb real,
	ast real
)

create type scoring_class as enum ('star', 'good', 'average', 'bad')

create table players (
	player_name text,
	height text,
	college text,
	country text,
	draft_year text,
	draft_round text,
	draft_number text,
	season_stats season_stats[],
	scoring_class scoring_class,
	years_since_last_season INTEGER,
	current_season INTEGER, -- This will be the final year in origin dataset
	primary key (player_name, current_season)
)

-- Create cumulative dimensions table
insert into players 
with yesterday as (
	select * from players p
	where current_season = 2001
), 
today as ( -- seed query
	select * from player_seasons ps
	where season = 2002
)

select 
	-- colesce all fixed attributes
	coalesce(t.player_name, y.player_name) as player_name,
	coalesce(t.height, y.height) as height,
	coalesce(t.college, y.college) as college,
	coalesce(t.country, y.country) as country,
	coalesce(t.draft_year, y.draft_year) as draft_year,
	coalesce(t.draft_round, y.draft_round) as draft_round,
	coalesce(t.draft_number, y.draft_number) as draft_number,
	-- Putting season data into an array of struct
	case 
		when y.season_stats is null -- first year
		then array[row(
						t.season,
						t.gp,
						t.pts,
						t.reb,
						t.ast
						)::season_stats]
		when t.season is not null -- not retired
		then y.season_stats || array[row(
						t.season,
						t.gp,
						t.pts,
						t.reb,
						t.ast
						)::season_stats]
		else y.season_stats -- retired this current_season
	end as season_stats,
	case 
		when t.season is not null then
			case when t.pts > 20 then 'star'
				when t.pts > 15 then 'good'
				when t.pts > 10 then 'average'
				else 'bad'
			end::scoring_class
		else y.scoring_class
	end as scoring_class,
	case
		when t.season is not null then 0
		else y.years_since_last_season + 1
	end as years_since_last_season,
	coalesce(t.season, y.current_season + 1) as current_season
from today t full outer join yesterday y
on t.player_name = y.player_name

-- Working with cumulative dimensions table
-- current_season = 1996 - 441 rows
-- current_season = 1997 - 527 rows
-- current_season = 1998 - 602 rows
-- current_season = 1999 - 666 rows
-- current_season = 2000 - 734 rows
-- current_season = 2001 - 804 rows
-- current_season = 2002 - 868 rows
select * from players p 
where player_name = 'Michael Jordan' and current_season = 2002

-- Convert cumulative dimensions table back to origin table
select player_name,
		(UNNEST(SEASON_STATS)::SEASON_STATS).*
from players p where current_season = 2002
where player_name = 'Michael Jordan' and current_season = 2002

-- Analytic queries (Without any group by or aggregation)
select 
	player_name,
	(season_stats[cardinality(season_stats)]::season_stats).pts as latest_season_point,
	(season_stats[1]::season_stats).pts as first_season_point,
	case when (season_stats[1]::season_stats).pts = 0
			then 1
		else (season_stats[cardinality(season_stats)]::season_stats).pts 
		/ 
		(season_stats[1]::season_stats).pts
	end as improvement
from players p 
where current_season = 2001
order by improvement DESC


