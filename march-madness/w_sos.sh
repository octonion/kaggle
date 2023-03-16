#!/bin/bash

psql kaggle -f w_sos/w_standardized_results.sql

psql kaggle -c "drop table march_madness.w_parameter_levels;"
psql kaggle -c "drop table march_madness.w_basic_factors;"

psql kaggle -c "vacuum analyze march_madness.w_results;"

Rscript w_sos/w_lmer.R

psql kaggle -c "vacuum analyze march_madness.w_parameter_levels;"
psql kaggle -c "vacuum analyze march_madness.w_basic_factors;"

psql kaggle -f w_sos/w_normalize_factors.sql

psql kaggle -c "vacuum analyze march_madness.w_factors;"

psql kaggle -f w_sos/w_schedule_factors.sql

psql kaggle -c "vacuum analyze march_madness.w_schedule_factors;"

psql kaggle -f w_sos/w_current_ranking.sql > w_sos/w_current_ranking.txt
cp /tmp/w_current_ranking.csv w_sos/w_current_ranking.csv
