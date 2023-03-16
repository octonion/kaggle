begin;

drop table if exists march_madness.w_teams;

create table march_madness.w_teams (
    team_id           integer,
    team_name         text
);

copy march_madness.w_teams from '/tmp/w_teams.csv' with delimiter as ',' header;

commit;
