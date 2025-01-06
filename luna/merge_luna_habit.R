#!/usr/bin/env Rscript

# merge.R copy for habit task
# 20241220WF - init
# 20250105WF - fix formating (diff R version on laptop?)
library(dplyr)
library(stringr)
library(lubridate)

mr   <- read.table(text=system("sed 's/ /\\t/g' txt/luna/habit_task_mr.tsv", intern=T),
                   col.names=c("rundir","acqdate","acqhms", "tr"),
                   colClasses='character',
                   sep="\t") %>%
   mutate(sesid=str_extract(rundir, '\\d{5}_\\d{8}'),
          acqtime=paste(acqdate,acqhms)|>
                  ymd_hms(tz = "America/New_York") |>
                  with_tz("UTC")) %>%
   select(-acqdate, -acqhms)

# /Volumes/L/bea_res/Data/Tasks/Habit/MR/11668_20240620/sub-11668_task-mr_habit_ses-20240504_run-1_1718889196248.json	150	1718889196248
task <- read.table('txt/luna/habit_task_display.tsv',
                   col.names=c("fname","nrt", "acqtime"),sep="\t") %>%
   mutate(sesid=str_extract(fname, '\\d{5}_\\d{8}'),
          acqtime=as_datetime(acqtime/1000))

times <- merge(mr, task, by=c("sesid"), suffixes=c("_mr","_task")) %>%
   select(sesid,matches('acqtime')) %>%
   mutate(tdiff=time_length(acqtime_task - acqtime_mr, 'seconds'))

write.csv(times, 'txt/combined_habit_times.csv', quote=F, row.names=F)
