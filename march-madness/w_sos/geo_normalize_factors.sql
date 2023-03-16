begin;

create temporary table years (
       first_year      integer,
       last_year       integer
);

insert into years
(first_year,last_year)
(select min(level::integer),max(level::integer)
from ncaa._geo_parameter_levels
where parameter='year'
);

drop table if exists ncaa._geo_factors;

create table ncaa._geo_factors (
       parameter		text,
       level			text,
       type			text,
       method			text,
       year			integer,
       first_year		integer,
       last_year		integer,
       raw_factor		float,
       exp_factor		float,
       factor			float
--       primary key (team_name,type,method,year,first_year,last_year)
);

-- this can/should be rewritten agnostically
-- do random/fixed separately
-- test for the prescence of '/' using like

-- Random factors

-- defense,offense

insert into ncaa._geo_factors
(parameter,level,type,method,year,first_year,last_year,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
split_part(wpl.level,'/',2) as level,
wpl.type as type,
'log_regression' as method,
split_part(wpl.level,'/',1)::integer as year,
split_part(wpl.level,'/',1)::integer as first_year,
split_part(wpl.level,'/',1)::integer as last_year,
estimate as raw_factor,
null as exp_factor
--exp(estimate) as exp_factor
from ncaa._geo_parameter_levels wpl
left outer join ncaa._geo_basic_factors nbf
  on (nbf.factor,nbf.level,nbf.type)=(wpl.parameter,wpl.level,wpl.type)
where
    wpl.type='random'
and wpl.parameter in ('defense','offense')
);

-- other random

insert into ncaa._geo_factors
(parameter,level,type,method,year,first_year,last_year,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
null as year,
null as first_year,
null as last_year,
estimate as raw_factor,
null as exp_factor
--exp(estimate) as exp_factor
from ncaa._geo_parameter_levels wpl
left outer join ncaa._geo_basic_factors nbf
  on (nbf.factor,nbf.level,nbf.type)=(wpl.parameter,wpl.level,wpl.type)
where
    wpl.type='random'
and wpl.parameter not in ('defense','offense')
);

-- Fixed factors

-- year

insert into ncaa._geo_factors
(parameter,level,type,method,year,first_year,last_year,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
wpl.level::integer as year,
wpl.level::integer as first_year,
wpl.level::integer as last_year,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from ncaa._geo_parameter_levels wpl
left outer join ncaa._geo_basic_factors nbf
  on (nbf.factor,nbf.type)=(wpl.parameter||wpl.level,wpl.type)
where
    wpl.type='fixed'
and wpl.parameter in ('year')
);

-- field

insert into ncaa._geo_factors
(parameter,level,type,method,year,first_year,last_year,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
null as year,
null as first_year,
null as last_year,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from ncaa._geo_parameter_levels wpl
left outer join ncaa._geo_basic_factors nbf
  on (nbf.factor,nbf.type)=(wpl.parameter||wpl.level,wpl.type)
where
    wpl.type='fixed'
and wpl.parameter in ('field')
and wpl.level not in ('none')
);

-- other fixed

insert into ncaa._geo_factors
(parameter,level,type,method,year,first_year,last_year,raw_factor,exp_factor)
(
select
wpl.parameter as parameter,
wpl.level as level,
wpl.type as type,
'log_regression' as method,
null as year,
null as first_year,
null as last_year,
coalesce(estimate,0.0) as raw_factor,
null as exp_factor
--coalesce(exp(estimate),1.0) as exp_factor
from ncaa._geo_parameter_levels wpl
left outer join ncaa._geo_basic_factors nbf
  on (nbf.factor,nbf.type)=(wpl.parameter||wpl.level,wpl.type)
where
    wpl.type='fixed'
and wpl.parameter not in ('field','year')
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
from ncaa._geo_factors
where parameter not in ('o_div','d_div')
group by parameter
);

update ncaa._geo_factors
set raw_factor=raw_factor-s.mean
from scale s
where s.parameter=ncaa._geo_factors.parameter;

update ncaa._geo_factors
set exp_factor=exp(raw_factor);

-- 'neutral' park confounded with 'none' field; set factor = 1.0 for field 'none'

insert into ncaa._geo_factors
(parameter,level,type,method,year,first_year,last_year,raw_factor,exp_factor)
values
('field','none','fixed','log_regression',null,null,null,0.0,1.0);

commit;
