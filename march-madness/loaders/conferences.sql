begin;

drop table if exists march_madness.conferences;

create table march_madness.conferences (
    conf_abbrev       text,
    description       text
);

copy march_madness.conferences from '/tmp/conferences.csv' with delimiter as ',' header;

commit;
