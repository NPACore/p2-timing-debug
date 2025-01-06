#!/usr/bin/env Rscript

#' merge all task and mr timing data for luna study with fmri tasks
#' habit (one run) and anti (two runs)
#' look at just P1 times

library(dplyr)
library(stringr)
library(lubridate)
library(tidyr)


#' @description
#' lunaid_yyyymmdd isn't correct for 12031 MR (20241200 instead of 09)
#' so we'll clear the date part of the id and get visit date from the acquistion time instead
#' @param d input dataframe has `acqtime` and `sesid`
#' @return dataframe with `pid` and `vdate` added
mk_pid_vdate <- function(d)
    mutate(d, vdate=format(acqtime, "%Y%m%d"), pid=gsub('_.*','',sesid))


## Read MR
#' all_with_station is not actually tsv. generated before -sepstr added to dicom_hinfo. use sed to make spaces tabs.
#' R will drop leading zeros in the 'acqhms' column by default (read in as a number) but we need those. so read in all column as 'character'
mr_tabdel <- system("sed 's/ /\\t/g' txt/luna/all_with_station.tsv",
                    intern=T)
mr_luna  <- read.table(text=mr_tabdel,
                   col.names=c("rundir","acqdate","acqhms", "tr", "station"),
                   colClasses='character',
                   sep="\t") |>
            mutate(tr=as.numeric(tr)/1000)

#' get just P1 MR data.
#' parsing from dicom header output from ../mr_time.bash.
#' need to combine acqdate (0008,0022) + acqtime (0008,0032)
#' MR time is eastern timezone but we'll use UTC to avoid daylight savings time issues
#'  * needs to have run and task translated from directory (protocol) name
mr_p1 <- mr_luna %>%
   mutate(sesid=str_extract(rundir, '\\d{5}_\\d{8}'),
          # 'RewardedAntisaccade_repeat' is only run 2
          run=ifelse(grepl('repeat',rundir),2,1),
          task=ifelse(grepl('HabitTask',rundir),'habit','anti'),
          acqtime=paste(acqdate,acqhms)|>
                  ymd_hms(tz = "America/New_York") |>
                  with_tz("UTC")) %>%
   select(-acqdate, -acqhms) %>%
   mk_pid_vdate()


## Read task
#
# lines like
# /Volumes/L/bea_res/Data/Tasks/Habit/MR/11668_20240620/sub-11668_task-mr_habit_ses-20240504_run-1_1718889196248.json	150	1718889196248
habit <- read.table('txt/luna/habit_task_display.tsv',
                   col.names=c("fname","nrt", "acqtime"),sep="\t") %>%
   mutate(sesid=str_extract(fname, '\\d{5}_\\d{8}'),
          acqtime=as_datetime(acqtime/1000))

anti <- read.table('txt/luna/anti_task_display.tsv',
                   col.names=c("sesid", "run","acqtime"),sep="\t") %>%
   mutate(run=as.numeric(gsub('-.*','',run)),
          acqtime=as_datetime(acqtime))

# to combine the two tasks:
# habit has some extra columns for QCing that need to be removed
# both need a new column 'task' to distinqush one from the other in the future merge
tasks <- rbind(habit|>transmute(sesid, run=1, acqtime, task='habit'),
               anti |> mutate(task='anti')) |> mk_pid_vdate()


times <- merge(mr_p1, tasks,
               by=c("pid","vdate", "task", "run"),
               suffixes=c("_mr","_task")) %>%
   select(pid,station,vdate,task,run,matches('acqtime'), tr) %>%
   mutate(tdiff=time_length(acqtime_task - acqtime_mr, 'seconds'))

tdiff <- times %>%
   mutate(vdate=ymd(vdate)) %>%
   group_by(pid,vdate,station,tr) %>%
   arrange(acqtime_mr) %>%
   mutate(tdiff=tdiff-lag(tdiff))

# AWP167046=p2, MRC67078=p1
tdiff %>% filter(grepl("MRC", station)) |> print.data.frame()


p.data <- tdiff %>%
   #filter(scale(abs(tdiff),center=T) < 2) %>%
   filter(abs(tdiff) < 30) %>%
   mutate(vdate=lubridate::ymd(vdate),
          TTLerror=abs(tdiff)>tr,
          label=paste0(round(tdiff/tr,1),' TRs'))

TR <- mean(as.numeric(times$tr))
p <-
   ggplot(p.data) +
   aes(y=tdiff, x=vdate, color=TTLerror) +
   # show TR
   geom_hline(yintercept=c(-1,1)*TR, color='green', linetype=2) +
   geom_line(aes(group=paste(pid,vdate)),alpha=.3) +
   geom_label(data=filter(p.data, TTLerror),
              aes(label=label, color=NULL),
              vjust=1,hjust=-.1, alpha=.3, size=3) +
   geom_point(aes(shape=task)) +
   #cowplot::theme_cowplot() +
   see::theme_modern() +
   theme(axis.title.y = element_text(size = 14)) +
   labs(y=expression(run1["task-mr"] - run2['task-mr'] ~ (s)),
        x='acquisition date') +
   scale_color_manual(values=c("black","red"), guide="none") +
   scale_shape_manual(values=c(20,22)) +
   facet_grid(station~.)
