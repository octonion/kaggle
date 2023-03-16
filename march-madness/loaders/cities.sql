begin;

drop table if exists march_madness.cities;

create table march_madness.cities (
    city_id           integer,
    city              text,
    state             text
);

copy march_madness.cities from '/tmp/cities.csv' with delimiter as ',' header;

commit;
