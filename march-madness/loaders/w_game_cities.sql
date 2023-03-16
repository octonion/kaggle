begin;

drop table if exists march_madness.w_game_cities;

create table march_madness.w_game_cities (
    season            integer,
    day_num           integer,
    w_team_id         integer,
    l_team_id         integer,
    cr_type           text,
    city_id           integer
);

copy march_madness.w_game_cities from '/tmp/w_game_cities.csv' with delimiter as ',' header;

commit;
