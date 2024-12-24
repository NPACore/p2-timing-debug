#!/usr/bin/env Rscript
# normalize luna task logs for easy merge
#  columns wpc, sesid, task, run, acqtime
# 20241223WF - init
suppressPackageStartupMessages({library(dplyr); library(lubridate);library(stringr);})
habit <-
   read.table('txt/luna/habit_task_display.tsv',
           col.names=c("fname","nrt", "acqtime"),sep="\t") |>
   transmute(
          sess_id=str_extract(fname, '\\d{5}_\\d{8}'),
          # match MR dicom header for sequence name
          task="HabitTask",
          run=1,
          acqtime=as_datetime(acqtime/1000))
anti <- 
   read.table('txt/luna/anti_task_display.tsv',
                   col.names=c("sesid","run","acqtime"),sep="\t") |>
   transmute(
          sess_id=sesid,
          run=1,
          task_run=as.numeric(gsub('-.*','',run)),
          # match MR dicom header for sequence name
          task=case_when(task_run==1~~'RewardedAntisaccade',
                         task_run==2~~'RewardedAntisaccade_repeat',
                         .default='RewardedAntisaccade_ERROR')
          acqtime=as_datetime(acqtime)) |>
   select(-taskrun)

wpc8620 <- rbind(anti,habit) |>
  mutate(wpc="WPC-8620") |> relocate(wpc) |>
  arrange(acqtime)

write.table(wpc8620, 'txt/luna-wpc8620_display-norm.tsv', sep="\t", quote=F, row.names=F)
