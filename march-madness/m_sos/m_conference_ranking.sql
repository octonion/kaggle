begin;

create temporary table r (
       team_id	 integer,
       conf	 	 text,
       season 	 integer,
       str	 	 numeric(4,3),
       ofs	 	 numeric(4,3),
       dfs	 	 numeric(4,3),
       sos	 	 numeric(4,3)
);

insert into r
(team_id,conf,season,str,ofs,dfs,sos)
(
select
msf.team_id,
mtc.conf_abbrev as conf,
msf.season,
(msf.strength*o.exp_factor/d.exp_factor)::numeric(4,3) as str,
(offensive*o.exp_factor)::numeric(4,3) as ofs,
(defensive*d.exp_factor)::numeric(4,3) as dfs,
schedule_strength::numeric(4,3) as sos
from march_madness.m_schedule_factors msf
left outer join march_madness.m_team_conferences mtc
  on (mtc.team_id,mtc.season)=(msf.team_id,msf.season)
left outer join march_madness.m_factors o
  on (o.parameter,o.level)=('o_conf',mtc.conf_abbrev)
left outer join march_madness.m_factors d
  on (d.parameter,d.level)=('d_conf',mtc.conf_abbrev)
where msf.season in (2023)
order by str desc);

select
season,
exp(avg(log(str)))::numeric(4,3) as str,
exp(avg(log(ofs)))::numeric(4,3) as ofs,
exp(-avg(log(dfs)))::numeric(4,3) as dfs,
exp(avg(log(sos)))::numeric(4,3) as sos,
count(*) as n
from r
group by season
order by season asc;

select
season,
conf,
exp(avg(log(str)))::numeric(4,3) as str,
exp(avg(log(ofs)))::numeric(4,3) as ofs,
exp(-avg(log(dfs)))::numeric(4,3) as dfs,
exp(avg(log(sos)))::numeric(4,3) as sos,
--avg(str)::numeric(4,3) as str,
--avg(ofs)::numeric(4,3) as ofs,
--(1/avg(dfs))::numeric(4,3) as dfs,
--avg(sos)::numeric(4,3) as sos,
count(*) as n
from r
where conf is not null
group by season,conf
order by season asc,str desc;

select * from r
where conf is null
and season=2023;

commit;
