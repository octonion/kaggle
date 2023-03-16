select mpl.parameter,mpl.type,mpl.level,nbf.estimate
from march_madness.m_parameter_levels mpl
left outer join march_madness.m_basic_factors nbf
  on (nbf.factor,nbf.type)=(mpl.parameter||mpl.level,mpl.type)
where mpl.type='fixed'
order by parameter,level;
