begin;

drop table if exists march_madness.m_teams;

create table march_madness.m_teams (
    team_id           integer,
    team_name         text,
    first_d1_season   integer,
    last_d1_season    integer
);

copy march_madness.m_teams from '/tmp/m_teams.csv' with delimiter as ',' header;

commit;
