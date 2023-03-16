select npl.parameter,npl.type,npl.level,nbf.estimate
from march_madness.m_parameter_levels npl
left outer join march_madness.m_basic_factors nbf
  on (nbf.factor,nbf.type)=(npl.parameter||npl.level,npl.type)
where npl.type='fixed'
order by parameter,level;
