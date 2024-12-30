-- Insert games (game_id, 'game', {pts_home, pts_away, winning_team})
insert into vertices
select 
	game_id as identifier,
	'game'::vertex_type as type,
	json_build_object(
		'pts_home', pts_home,
		'pts_away', pts_away,
		'winning_team', case when home_team_wins = 1 then home_team_id else visitor_team_id end
	) as properties
from games;

-- Insert players (player_id, 'player', {player_name, number_of_games, total_points, teams})
insert into vertices
with player_agg as (
	select 
		player_id as identifier,
		max(player_name) as player_name,
		COUNT(1) as number_of_games,
		SUM(pts) as total_points,
		array_agg(distinct team_id) as teams
	from game_details gd
	group by player_id
)
select 
	identifier,
	'player'::vertex_type,
	json_build_object(
		'player_name', player_name,
		'number_of_games', number_of_games,
		'total_points', total_points,
		'teams', teams
	) as properties
from player_agg;

-- Insert teams (team_id, 'team', {'abbreviation', 'nickname', city', 'arena', 'year_founded'})
insert into vertices
with teams_deduped as ( -- Mistake while loading the data
	select *, row_number() OVER(partition by team_id) as row_num 
	from teams
)

select 
	team_id as identifier,
	'team'::vertex_type as type,
	json_build_object(
		'abbreviation', abbreviation,
		'nickname', nickname,
		'city', city,
		'arena', arena,
		'year_founded', yearfounded
	) 
from teams_deduped
where row_num = 1