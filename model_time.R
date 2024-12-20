#!/usr/bin/env Rscript
library(dplyr)
library(ggplot2)
# explore clock offset drift
# 20241220WF - init

# sesid,run,acqtime_mr,acqtime_task,tdiff
times <- read.csv('txt/combined_mr_task_times.csv') |>
   mutate(task='anti') |>
   rbind(read.csv('txt/combined_habit_times.csv') |> mutate(task='habit', run=1)) |>
   mutate(across(matches('acqtime'), lubridate::ymd_hms))

p_1to1 <-
   ggplot(times) +
   aes(x=acqtime_mr, y=acqtime_task, color=task) +
   geom_smooth(method='lm', aes(color=NULL)) +
   geom_point(alpha=.3) +
   see::theme_modern()

p_tdiff <-
   times |>
   filter(abs(as.numeric(scale(tdiff,center=T)))<2) |>
   ggplot() +
   aes(x=acqtime_task,y=tdiff,color=task) +
   geom_point(alpha=.3) +
   #see::theme_modern() +
   cowplot::theme_cowplot() +
   labs(y="clock difference: task - mr (s)", title="Clock drift")

ggsave(file="clock_drift.png", p_tdiff, width=11.3, height=3.61)

