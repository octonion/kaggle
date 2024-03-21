begin;

drop table if exists march_madness.w_results;

create table march_madness.w_results (
	game_id		      integer,
	season		      integer,
	team_name	      text,
	team_id           integer,
	team_conf_id      text,
	opponent_name     text,
	opponent_id	      integer,
	opponent_conf_id  text,
	location_name     text,
	location_id	      integer,
	field		      text,
	team_score	      integer,
	opponent_score    integer,
	game_length	      text
);

insert into march_madness.w_results
(game_id,
 season,
 team_id,
 opponent_id,
 location_name,location_id,field,
 team_score,
 opponent_score,
 game_length)
(
select
game_id,
season,
w_team_id as team_id,
l_team_id as opponent_id,
 (case when w_loc='H' then w_team_id::text
       when w_loc='A' then l_team_id::text
       when w_loc='N' then 'neutral' end) as location_name,
 (case when w_loc='H' then w_team_id
       when w_loc='A' then l_team_id
       when w_loc='N' then 0 end) as location_id,
 (case when w_loc='H' then 'offense_home'
       when w_loc='A' then 'defense_home'
       when w_loc='N' then 'none' end) as field,
w_score as team_score,
l_score as opponent_score,
num_ot as game_length
from march_madness.w_regular_season_compact_results
union
select
1000000+game_id,
season,
w_team_id as team_id,
l_team_id as opponent_id,
 (case when w_loc='H' then w_team_id::text
       when w_loc='A' then l_team_id::text
       when w_loc='N' then 'neutral' end) as location_name,
 (case when w_loc='H' then w_team_id
       when w_loc='A' then l_team_id
       when w_loc='N' then 0 end) as location_id,
 (case when w_loc='H' then 'offense_home'
       when w_loc='A' then 'defense_home'
       when w_loc='N' then 'none' end) as field,
w_score as team_score,
l_score as opponent_score,
num_ot as game_length
from march_madness.w_ncaa_tourney_compact_results
where
season between 2002 and 2024
);

insert into march_madness.w_results
(game_id,
 season,
 team_id,
 opponent_id,
 location_name,location_id,field,
 team_score,
 opponent_score,
 game_length)
(
select
game_id,
season,
l_team_id as team_id,
w_team_id as opponent_id,
 (case when w_loc='H' then l_team_id::text
       when w_loc='A' then w_team_id::text
       when w_loc='N' then 'neutral' end) as location_name,
 (case when w_loc='H' then l_team_id
       when w_loc='A' then w_team_id
       when w_loc='N' then 0 end) as location_id,
 (case when w_loc='H' then 'defense_home'
       when w_loc='A' then 'offense_home'
       when w_loc='N' then 'none' end) as field,
l_score as team_score,
w_score as opponent_score,
num_ot as game_length
from march_madness.w_regular_season_compact_results
union
select
1000000+game_id,
season,
l_team_id as team_id,
w_team_id as opponent_id,
 (case when w_loc='H' then l_team_id::text
       when w_loc='A' then w_team_id::text
       when w_loc='N' then 'neutral' end) as location_name,
 (case when w_loc='H' then l_team_id
       when w_loc='A' then w_team_id
       when w_loc='N' then 0 end) as location_id,
 (case when w_loc='H' then 'defense_home'
       when w_loc='A' then 'offense_home'
       when w_loc='N' then 'none' end) as field,
l_score as team_score,
w_score as opponent_score,
num_ot as game_length
from march_madness.w_ncaa_tourney_compact_results
where
season between 2002 and 2024
);

update march_madness.w_results
set team_conf_id=conf_abbrev
from march_madness.w_team_conferences wtc
where (wtc.season,wtc.team_id)=(w_results.season,w_results.team_id);

update march_madness.w_results
set opponent_conf_id=conf_abbrev
from march_madness.w_team_conferences wtc
where (wtc.season,wtc.team_id)=(w_results.season,w_results.opponent_id);

commit;
