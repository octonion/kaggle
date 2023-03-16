#!/bin/bash

cmd="psql template1 --tuples-only --command \"select count(*) from pg_database where datname = 'kaggle';\""

db_exists=`eval $cmd`
 
if [ $db_exists -eq 0 ] ; then
   cmd="createdb kaggle;"
   eval $cmd
fi

psql kaggle -f schema/march_madness.sql

cp csv/Cities.csv /tmp/cities.csv
psql kaggle -f loaders/cities.sql
rm /tmp/cities.csv

cp csv/Conferences.csv /tmp/conferences.csv
psql kaggle -f loaders/conferences.sql
rm /tmp/conferences.csv

# Men

cp csv/MRegularSeasonCompactResults.csv /tmp/m_regular_season_compact_results.csv
psql kaggle -f loaders/m_regular_season_compact_results.sql
rm /tmp/m_regular_season_compact_results.csv

cp csv/MNCAATourneyCompactResults.csv /tmp/m_ncaa_tourney_compact_results.csv
psql kaggle -f loaders/m_ncaa_tourney_compact_results.sql
rm /tmp/m_ncaa_tourney_compact_results.csv

cp csv/MSecondaryTourneyCompactResults.csv /tmp/m_secondary_tourney_compact_results.csv
psql kaggle -f loaders/m_secondary_tourney_compact_results.sql
rm /tmp/m_secondary_tourney_compact_results.csv

cp csv/MTeams.csv /tmp/m_teams.csv
psql kaggle -f loaders/m_teams.sql
rm /tmp/m_teams.csv

cp csv/MTeamConferences.csv /tmp/m_team_conferences.csv
psql kaggle -f loaders/m_team_conferences.sql
rm /tmp/m_team_conferences.csv

cp csv/MGameCities.csv /tmp/m_game_cities.csv
psql kaggle -f loaders/m_game_cities.sql
rm /tmp/m_game_cities.csv

# Women

cp csv/WRegularSeasonCompactResults.csv /tmp/w_regular_season_compact_results.csv
psql kaggle -f loaders/w_regular_season_compact_results.sql
rm /tmp/w_regular_season_compact_results.csv

cp csv/WNCAATourneyCompactResults.csv /tmp/w_ncaa_tourney_compact_results.csv
psql kaggle -f loaders/w_ncaa_tourney_compact_results.sql
rm /tmp/w_ncaa_tourney_compact_results.csv

cp csv/WTeams.csv /tmp/w_teams.csv
psql kaggle -f loaders/w_teams.sql
rm /tmp/w_teams.csv

cp csv/WTeamConferences.csv /tmp/w_team_conferences.csv
psql kaggle -f loaders/w_team_conferences.sql
rm /tmp/w_team_conferences.csv

cp csv/WGameCities.csv /tmp/w_game_cities.csv
psql kaggle -f loaders/w_game_cities.sql
rm /tmp/w_game_cities.csv

#psql basketball-m -f sql/geo.sql
