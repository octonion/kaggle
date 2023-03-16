#!/bin/bash

psql kaggle -f m_sos/m_standardized_results.sql

psql kaggle -c "drop table march_madness.m_parameter_levels;"
psql kaggle -c "drop table march_madness.m_basic_factors;"

psql kaggle -c "vacuum analyze march_madness.m_results;"

Rscript m_sos/m_lmer.R

psql kaggle -c "vacuum analyze march_madness.m_parameter_levels;"
psql kaggle -c "vacuum analyze march_madness.m_basic_factors;"

psql kaggle -f m_sos/m_normalize_factors.sql

psql kaggle -c "vacuum analyze march_madness.m_factors;"

psql kaggle -f m_sos/m_schedule_factors.sql

psql kaggle -c "vacuum analyze march_madness.m_schedule_factors;"

psql kaggle -f m_sos/m_current_ranking.sql > m_sos/m_current_ranking.txt
cp /tmp/m_current_ranking.csv m_sos/m_current_ranking.csv
