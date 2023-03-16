select wpl.parameter,wpl.type,wpl.level,nbf.estimate
from ncaa._parameter_levels wpl
left outer join ncaa._basic_factors nbf
  on (nbf.factor,nbf.level,nbf.type)=(wpl.parameter,wpl.level,wpl.type)
where wpl.type='random'
order by parameter,level;
