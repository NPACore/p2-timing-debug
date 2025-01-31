#!/usr/bin/env bash
#
# 20250130WF - init
orig_loc="/Volumes/Hera/Projects/Habit/mr/habit"
rsync "$@" -vhir --size-only $orig_loc/button_push_decon.bash $orig_loc/button_tent*{sh,.R} $orig_loc/bntpush-motor_thres-2.9103_tents.png $orig_loc/txt/buttonpush-tent_PMC_fstat-2.9103.txt  ./
