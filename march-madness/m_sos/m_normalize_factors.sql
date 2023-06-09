begin;

create temporary table seasons (
       first_season      integer,
       last_season       integer
);

insert into seasons
(first_season,last_season)
(select min(level::integer),max(level::integer)
from march_madness.m_parameter_levels
where parameter='season'
);

drop table if exists march_madness.m_factors;

create table march_madness.m_factors (
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

insert into march_madness.m_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
mpl.parameter as parameter,
split_part(mpl.level,'/',2) as level,
mpl.type as type,
'log_regression' as method,
split_part(mpl.level,'/',1)::integer as season,
split_part(mpl.level,'/',1)::integer as first_season,
split_part(mpl.level,'/',1)::integer as last_season,
estimate as raw_factor,
null as exp_factor
--exp(estimate) as exp_factor
from march_madness.m_parameter_levels mpl
left outer join march_madness.m_basic_factors mbf
  on (mbf.factor,mbf.level,mbf.type)=(mpl.parameter,mpl.level,mpl.type)
where
    mpl.type='random'
and mpl.parameter in ('defense','offense')
);

-- other random

insert into march_madness.m_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
mpl.parameter as parameter,
mpl.level as level,
mpl.type as type,
'log_regression' as method,
null as season,
null as first_season,
null as last_season,
estimate as raw_factor,
null as exp_factor
--exp(estimate) as exp_factor
from march_madness.m_parameter_levels mpl
left outer join march_madness.m_basic_factors nbf
  on (nbf.factor,nbf.level,nbf.type)=(mpl.parameter,mpl.level,mpl.type)
where
    mpl.type='random'
and mpl.parameter not in ('defense','offense')
);

-- Fixed factors

-- season

insert into march_madness.m_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
mpl.parameter as parameter,
mpl.level as level,
mpl.type as type,
'log_regression' as method,
mpl.level::integer as season,
mpl.level::integer as first_season,
mpl.level::integer as last_season,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from march_madness.m_parameter_levels mpl
left outer join march_madness.m_basic_factors nbf
  on (nbf.factor,nbf.type)=(mpl.parameter||mpl.level,mpl.type)
where
    mpl.type='fixed'
and mpl.parameter in ('season')
);

-- field

insert into march_madness.m_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
mpl.parameter as parameter,
mpl.level as level,
mpl.type as type,
'log_regression' as method,
null as season,
null as first_season,
null as last_season,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from march_madness.m_parameter_levels mpl
left outer join march_madness.m_basic_factors nbf
  on (nbf.factor,nbf.type)=(mpl.parameter||mpl.level,mpl.type)
where
    mpl.type='fixed'
and mpl.parameter in ('field')
and mpl.level not in ('none')
);

-- other fixed

insert into march_madness.m_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
(
select
mpl.parameter as parameter,
mpl.level as level,
mpl.type as type,
'log_regression' as method,
null as season,
null as first_season,
null as last_season,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from march_madness.m_parameter_levels mpl
left outer join march_madness.m_basic_factors nbf
  on (nbf.factor,nbf.type)=(mpl.parameter||mpl.level,mpl.type)
where
    mpl.type='fixed'
and mpl.parameter not in ('field','season')
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
from march_madness.m_factors
where parameter not in ('o_conf','d_conf')
group by parameter
);

update march_madness.m_factors
set raw_factor=raw_factor-s.mean
from scale s
where s.parameter=march_madness.m_factors.parameter;

update march_madness.m_factors
set exp_factor=exp(raw_factor);

-- 'neutral' park confounded with 'none' field; set factor = 1.0 for field 'none'

insert into march_madness.m_factors
(parameter,level,type,method,season,first_season,last_season,raw_factor,exp_factor)
values
('field','none','fixed','log_regression',null,null,null,0.0,1.0);

commit;
