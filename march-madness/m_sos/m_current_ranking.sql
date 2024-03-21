begin;

create temporary table r (
       rk	 serial,
       team 	 text,
       team_id integer,
       conf_id	 text,
       season	 integer,
       str	 numeric(4,3),
       ofs	 numeric(4,3),
       dfs	 numeric(4,3),
       sos	 numeric(4,3)
);

insert into r
(team,team_id,conf_id,season,str,ofs,dfs,sos)
(
select
mt.team_name,
sf.team_id,
mtc.conf_abbrev as conf_id,
sf.season,
(sf.strength*o.exp_factor/d.exp_factor)::numeric(4,3) as str,
(offensive*o.exp_factor)::numeric(4,3) as ofs,
(defensive*d.exp_factor)::numeric(4,3) as dfs,
schedule_strength::numeric(4,3) as sos
from march_madness.m_schedule_factors sf
join march_madness.m_teams mt
  on (mt.team_id)=(sf.team_id)
join march_madness.m_team_conferences mtc
  on (mtc.team_id,mtc.season)=(sf.team_id,sf.season)
join march_madness.m_factors o
  on (o.parameter,o.level::text)=('o_conf',mtc.conf_abbrev)
join march_madness.m_factors d
  on (d.parameter,d.level::text)=('d_conf',mtc.conf_abbrev)
where sf.season in (2024)
order by (sf.strength*o.exp_factor/d.exp_factor) desc);

select
rk,
team,
conf_id as conf,
str,ofs,dfs,sos
from r
order by rk asc;

copy (
select
rk,
team,
conf_id as conf,
str,ofs,dfs,sos
from r
order by rk asc
) to '/tmp/m_current_ranking.csv' csv header;

commit;
