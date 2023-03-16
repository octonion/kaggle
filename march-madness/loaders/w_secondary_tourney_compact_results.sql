begin;

drop table if exists march_madness.w_secondary_tourney_compact_results;

create table march_madness.w_secondary_tourney_compact_results (
    season            integer,
    day_num           integer,
    w_team_id         integer,
    w_score           integer,
    l_team_id         integer,
    l_score           integer,
    w_loc             text,
    num_ot            integer,
    secondary_tourney text
);

truncate table march_madness.w_secondary_tourney_compact_results;

copy march_madness.w_secondary_tourney_compact_results from '/tmp/w_secondary_tourney_compact_results.csv' with delimiter as ',' header;

alter table march_madness.w_secondary_tourney_compact_results add column game_id serial primary key;

commit;
