#!/usr/bin/env Rscript

# plot tdiff with given TR   
# makes run_diffs_over_date.png
library(dplyr)
library(ggplot2)


tdiff <- read.csv('txt/combined_tdiff.csv')
TR <- 1.300 # seconds

p.data <- tdiff %>%
   #filter(scale(abs(tdiff),center=T) < 2) %>%
   filter(abs(tdiff) < 30) %>%
   mutate(vdate=lubridate::ymd(vdate),
          TTLerror=abs(tdiff)>TR,
          label=paste0(round(tdiff/TR,1),' TRs'))

p <-
   ggplot(p.data) +
   aes(y=tdiff, x=vdate, color=TTLerror) +
   # show TR
   geom_hline(yintercept=c(-1,1)*TR, color='green', linetype=2) +
   geom_label(data=filter(p.data, TTLerror),
              aes(label=label, color=NULL),
              vjust=1,hjust=-.1) +
   geom_point() +
   #cowplot::theme_cowplot() +
   see::theme_modern() +
   theme(axis.title.y = element_text(size = 14)) +
   labs(y=expression(run1["task-mr"] - run2['task-mr'] ~ (s)),
        x='acquisition date') +
   scale_color_manual(values=c("black","red"), guide="none")

ggsave(p, file="run_diffs_over_date.png", height=3, width=12)
