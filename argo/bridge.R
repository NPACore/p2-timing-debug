#!/usr/bin/env Rscript

#' merge all task and mr timing data for argo's TeenScreen study fMRI
#' some have rest, most have chat and sid
#' study is on BRIDGE 3T scanner. useful to confirm diff-of-diff is valid for P2

library(dplyr)
library(stringr)
library(lubridate)
library(tidyr)


## Read MR
#' R will drop leading zeros in the 'acqhms' column by default (read in as a number) but we need those. so read in all column as 'character'
mr_argo <- read.table("txt/BridgeTeenSceen/mr_times.tsv",
                 col.names=c("rundir","acqdate","acqhms", "tr", "station"),
                 colClasses='character',
                 sep="\t") |>
    mutate(tr=as.numeric(tr)/1000)

#' get just P1 MR data.
#' parsing from dicom header output from ../mr_time.bash.
#' need to combine acqdate (0008,0022) + acqtime (0008,0032)
#' MR time is eastern timezone but we'll use UTC to avoid daylight savings time issues
#'  * needs to have run and task translated from directory (protocol) name
mr <- mr_argo %>%
   mutate(sesid=str_extract(rundir, '(?<=complete/)\\d{5}'),
          # 'RewardedAntisaccade_repeat' is only run 2
          run=1,
          task=str_extract(rundir,'CHAT|SID|RestingState'),
          acqtime=paste(acqdate,acqhms)|>
                  ymd_hms(tz = "America/New_York") |>
                  with_tz("UTC")) %>%
   select(-acqdate, -acqhms)


## Read task
# extracted from eprime onset time
tasks <- read.table('txt/BridgeTeenSceen/tasks_times.tsv',sep="\t",header=T) |>
  mutate(
     acqtime=ymd_hms(acqtime_task),
     task=case_when(
             grepl("Resting",file)~"RestingState",
             grepl("TS",file)~ "SID",
             grepl("chzc", file) ~ "CHAT",
             .default=NA)) |>
  rename(sesid=id_fname, eprime_acqstr=acqtime_task)


# to combine the two tasks:
# habit has some extra columns for QCing that need to be removed
# both need a new column 'task' to distinqush one from the other in the future merge
times <- merge(mr, tasks,
               by=c("sesid","task"),
               suffixes=c("_mr","_task")) %>%
   select(sesid,station,task,matches('acqtime'), tr) %>%
   mutate(tdiff=time_length(acqtime_task - acqtime_mr, 'seconds'))

tdiff <- times %>%
   group_by(sesid,station,tr) %>%
   arrange(acqtime_mr) %>%
   mutate(dod=tdiff-lag(tdiff))

p.data <- tdiff %>%
   #filter(scale(abs(tdiff),center=T) < 2) %>%
   filter(abs(dod) < 30) %>%
   mutate(vdate=as.Date(acqtime_mr),
          TTLerror=abs(dod)>tr,
          label=paste0(round(dod/tr,1),' TRs'))

TR <- mean(as.numeric(times$tr))
p_tr <-
   ggplot(p.data) +
   aes(y=dod, x=vdate, color=TTLerror) +
   # show TR
   geom_hline(yintercept=c(-1,1)*TR, color='green', linetype=2) +
   geom_line(aes(group=paste(sesid,vdate)),alpha=.3) +
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
   scale_shape_manual(values=c(20,22,1))

p_dod <-
 tdiff |> filter(abs(tdiff) < 1000) |>
 ggplot() +
    aes(shape=task, x=acqtime_mr, y=acqtime_task-acqtime_mr, color=dod)+
    geom_point() +
    scale_shape_manual(values=c(20,22,1)) +
    scale_color_gradient2(high="red", low="red", mid="black", limits=c(-3,3)*TR,
                          breaks=c(-3,0,3)*TR, oob=scales::squish) +
    see::theme_modern() +
    labs(color="Diff-of-diff", x="Acq Date", shape="Task")

cowplot::plot_grid(p_tr, p_dod, nrow=2, ncol=1,
                   title="TeenScreen Study MR vs Task Timing")
ggsave('argo/diff-of-diff.png', width=20,height=11)
