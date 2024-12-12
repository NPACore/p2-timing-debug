#!/usr/bin/env bash
mkdir -p txt
grep -m 1 starting\ task /Volumes/L/bea_res/Data/Tasks/DollarReward2/MR/1*_*/log/sub-*.log |
   perl -pe '
    s/\r//g;
    s".*(\d{5}_\d{8})/.*_run-(.*).log:"\1 \2\t";
    s/ starting task//' |
   tee txt/anti_task_display.tsv

