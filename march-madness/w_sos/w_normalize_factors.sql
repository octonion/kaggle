begin;

create temporary table seasons (
       first_season      integer,
       last_season       integer
);

insert into seasons
(first_season,last_season)
(select min(level::integer),max(level::integer)
from march_madness.w_parameter_levels
where parameter='season'
);

drop table if exists march_madness.w_factors;

create table march_madness.w_factors (
       parameter		text,
       level			text,
       type			text,
       method			text,
       season			integer,
       first_season		integer,
       last_season		integer,
       raw_factor		float,
       exp_factor		float,
       factor			float
--       primary key (team_name,type,method,season,first_season,last_season)
);

-- this can/should be rewritten agnostically
-- do random/fixed separately
-- test for the prescence of '/' using like

-- Random factors

-- defense,offense

insert into march_madness.w_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
split_part(wpl.level,'/',2) as level,
wpl.type as type,
'log_regression' as method,
split_part(wpl.level,'/',1)::integer as season,
split_part(wpl.level,'/',1)::integer as first_season,
split_part(wpl.level,'/',1)::integer as last_season,
estimate as raw_factor,
null as exp_factor
--exp(estimate) as exp_factor
from march_madness.w_parameter_levels wpl
left outer join march_madness.w_basic_factors nbf
  on (nbf.factor,nbf.level,nbf.type)=(wpl.parameter,wpl.level,wpl.type)
where
    wpl.type='random'
and wpl.parameter in ('defense','offense')
);

-- other random

insert into march_madness.w_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
null as season,
null as first_season,
null as last_season,
estimate as raw_factor,
null as exp_factor
--exp(estimate) as exp_factor
from march_madness.w_parameter_levels wpl
left outer join march_madness.w_basic_factors nbf
  on (nbf.factor,nbf.level,nbf.type)=(wpl.parameter,wpl.level,wpl.type)
where
    wpl.type='random'
and wpl.parameter not in ('defense','offense')
);

-- Fixed factors

-- season

insert into march_madness.w_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
wpl.level::integer as season,
wpl.level::integer as first_season,
wpl.level::integer as last_season,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from march_madness.w_parameter_levels wpl
left outer join march_madness.w_basic_factors nbf
  on (nbf.factor,nbf.type)=(wpl.parameter||wpl.level,wpl.type)
where
    wpl.type='fixed'
and wpl.parameter in ('season')
);

-- field

insert into march_madness.w_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
null as season,
null as first_season,
null as last_season,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from march_madness.w_parameter_levels wpl
left outer join march_madness.w_basic_factors nbf
  on (nbf.factor,nbf.type)=(wpl.parameter||wpl.level,wpl.type)
where
    wpl.type='fixed'
and wpl.parameter in ('field')
and wpl.level not in ('none')
);

-- other fixed

insert into march_madness.w_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
null as season,
null as first_season,
null as last_season,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from march_madness.w_parameter_levels wpl
left outer join march_madness.w_basic_factors nbf
  on (nbf.factor,nbf.type)=(wpl.parameter||wpl.level,wpl.type)
where
    wpl.type='fixed'
and wpl.parameter not in ('field','season')
);

create temporary table scale (
       parameter		text,
       mean			float,
       primary key (parameter)
);

insert into scale
(parameter,mean)
(select
parameter,
avg(raw_factor)
from march_madness.w_factors
where parameter not in ('o_conf','d_conf')
group by parameter
);

update march_madness.w_factors
set raw_factor=raw_factor-s.mean
from scale s
where s.parameter=march_madness.w_factors.parameter;

update march_madness.w_factors
set exp_factor=exp(raw_factor);

-- 'neutral' park confounded with 'none' field; set factor = 1.0 for field 'none'

insert into march_madness.w_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
values
('field','none','fixed','log_regression',null,null,null,0.0,1.0);

commit;
