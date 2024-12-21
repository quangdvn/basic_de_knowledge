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
	years_since_last_active INTEGER,
  is_active BOOLEAN,
	current_season INTEGER, -- This will be the final year in origin dataset
	primary key (player_name, current_season)
)
