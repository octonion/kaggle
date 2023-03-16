begin;

drop table if exists march_madness.m_team_conferences;

create table march_madness.m_team_conferences (
    season            integer,
    team_id           integer,
    conf_abbrev       text
);

copy march_madness.m_team_conferences from '/tmp/m_team_conferences.csv' with delimiter as ',' header;

commit;
