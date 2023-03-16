begin;

drop table if exists march_madness.w_team_conferences;

create table march_madness.w_team_conferences (
    season            integer,
    team_id           integer,
    conf_abbrev       text
);

copy march_madness.w_team_conferences from '/tmp/w_team_conferences.csv' with delimiter as ',' header;

commit;
