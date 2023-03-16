begin;

drop table if exists march_madness.w_schedule_factors;

create table march_madness.w_schedule_factors (
        team_id                 integer,
        season                  integer,
        offensive               float,
        defensive               float,
        strength                float,
        schedule_offensive      float,
        schedule_defensive      float,
        schedule_strength       float,
        schedule_offensive_all	float,
        schedule_defensive_all	float,
        primary key (team_id,season)
);

-- defensive
-- offensive
-- strength 
-- schedule_offensive
-- schedule_defensive
-- schedule_strength 

insert into march_madness.w_schedule_factors
(team_id,season,offensive,defensive)
(
select o.level::integer,o.season,o.exp_factor,d.exp_factor
from march_madness.w_factors o
left outer join march_madness.w_factors d
  on (d.level,d.season,d.parameter)=(o.level,o.season,'defense')
where o.parameter='offense'
);

update march_madness.w_schedule_factors
set strength=offensive/defensive;

----

create temporary table r (
         team_id		integer,
	 team_conf_id		text,
         opponent_id		integer,
	 opponent_conf_id	text,
         season                   integer,
	 field_id		text,
         offensive              float,
         defensive		float,
         strength               float,
	 field			float,
	 o_conf			float,
	 d_conf			float
);

insert into r
(team_id,team_conf_id,opponent_id,opponent_conf_id,season,field_id)
(
select
r.team_id,
r.team_conf_id,
r.opponent_id,
r.opponent_conf_id,
r.season,
r.field
from march_madness.w_results r
where r.season between 2002 and 2023
);

update r
set
offensive=o.offensive,
defensive=o.defensive,
strength=o.strength
from march_madness.w_schedule_factors o
where (r.opponent_id,r.season)=(o.team_id,o.season);

-- field

update r
set field=f.exp_factor
from march_madness.w_factors f
where (f.parameter,f.level)=('field',r.field_id);

-- opponent o_conf

update r
set o_conf=f.exp_factor
from march_madness.w_factors f
where (f.parameter,f.level::text)=('o_conf',r.opponent_conf_id);

-- opponent d_conf

update r
set d_conf=f.exp_factor
from march_madness.w_factors f
where (f.parameter,f.level::text)=('d_conf',r.opponent_conf_id);

create temporary table rs (
         team_id		integer,
         season                   integer,
         offensive              float,
         defensive              float,
         strength               float,
         offensive_all		float,
         defensive_all		float
);

insert into rs
(team_id,season,
 offensive,defensive,strength,offensive_all,defensive_all)
(
select
team_id,
season,
exp(avg(log(offensive*o_conf))),
exp(avg(log(defensive*d_conf))),
exp(avg(log(strength*o_conf/d_conf))),
exp(avg(log(offensive*o_conf/field))),
exp(avg(log(defensive*d_conf*field)))
from r
group by team_id,season
);

update march_madness.w_schedule_factors
set
  schedule_offensive=rs.offensive,
  schedule_defensive=rs.defensive,
  schedule_strength=rs.strength,
  schedule_offensive_all=rs.offensive_all,
  schedule_defensive_all=rs.defensive_all
from rs
where
  (w_schedule_factors.team_id,w_schedule_factors.season)=
  (rs.team_id,rs.season);

commit;
