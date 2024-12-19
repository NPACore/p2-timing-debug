#!/usr/bin/env Rscript
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)

# 20241212WF - init

# /disk/mace2/scan_data/WPC-8620/2023.05.09-14.23.47/11925_20230509/RewardedAntisaccade_704x752.17/	20230509 151104.610000
mr   <- read.table('txt/anti_task_mr.tsv',
                   col.names=c("rundir","acqtime"),sep="\t") %>%
   mutate(sesid=str_extract(rundir, '\\d{5}_\\d{8}'),
          run=ifelse(grepl('repeat',rundir),2,1),
          acqtime=ymd_hms(acqtime))

# 11668_20240620 1-1718889937	1718890013.03579
task <- read.table('txt/anti_task_display.tsv',
                   col.names=c("sesid_run","acqtime"),sep="\t") %>%
   separate(sesid_run, c('sesid', 'run'), sep=" ") %>%
   mutate(run=as.numeric(gsub('-.*','',run)),
          acqtime=as_datetime(acqtime))

times <- merge(mr, task, by=c("sesid","run"), suffixes=c("_mr","_task")) %>%
   select(sesid,run,matches('acqtime')) %>%
   mutate(tdiff=time_length(acqtime_task - acqtime_mr, 'seconds'))

write.csv(times, 'txt/combined_mr_task_times.csv', quote=F, row.names=F)


tdiff <- times %>%
   group_by(sesid) %>% arrange(run) %>%
   summarise(tdiff=diff(tdiff)) %>%
   separate(sesid, c('luanid','vdate')) %>%
   mutate(vdate=ymd(vdate)) 
write.csv(tdiff, 'txt/combined_tdiff.csv', quote=F, row.names=F)

