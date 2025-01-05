-- Create a fact table to make analytics query fun and understandable
select 
	dim_player_name,
	dim_is_playing_at_home,
	count(1) as num_games,
	sum(m_pts) as total_points,
	count(CASE WHEN dim_not_with_team IS TRUE THEN 1 END) as bailed,
	cast(count(CASE WHEN dim_not_with_team IS TRUE THEN 1 END) as REAL) / count(1) as bailed_per
from fact_game_details
group by 1, 2
order by 1, 3 asc
order by 6 desc

select dim_player_name,
	dim_is_playing_at_home
from fact_game_details