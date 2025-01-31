#!/usr/bin/env Rscript
library(dplyr)
dod <- read.csv('../txt/luna/diff-of-diff.csv') |>
 mutate(ld8=paste0(pid,"_",substr(gsub('-','',acqtime_mr),0,8)))

peak <- read.csv('decon/buttonpush-tent_PMC_fstat-2.9103.txt') |>
    mutate(ld8=gsub("_\\d_", "_",ses))

habit <-
    dod|>filter(task=="habit") |>
    merge(peak, by="ld8") |>
    mutate(
        vdate=lubridate::ymd_hms(acqtime_mr),
        dod=floor(abs(dod/1.3)),
        hrf=peak-2,
        is_match=dod==hrf,
        nonzero=hrf*dod!=0)

ggplot(habit) +
 aes(x=hrf,
     y=dod,
     color=is_match) +
 geom_point(size=.1,color="black") +
 geom_hline(linewidth=.3,yintercept=0,color="red")+
 geom_vline(linewidth=.3,xintercept=0,color="red")+
 geom_jitter(width=.2,height=.2) +
 scale_x_continuous(breaks=c(-2:9)) +
 scale_y_continuous(breaks=c(-2:9)) +
 theme_bw() +
 labs(title="TTL Offset calc: DoD vs Tent Peak")

p_data <- habit |> select(ld8,vdate,dod,hrf,is_match,nonzero) |>
    gather("calc","offset", -ld8,-vdate,-is_match, -nonzero)

ggplot(p_data) +
  aes(color=calc, x=vdate, y=offset, group=ld8, shape=is_match) +
    geom_line(color="black")+
    geom_jitter(height=.1,width=.1,alpha=.7) +
    theme_bw()+
    scale_y_continuous(breaks=c(-2:9))


p_data|>filter(!is_match|nonzero) |>
ggplot() +
  aes(color=calc,
      x=ld8,
      #x=vdate,
      shape=is_match,
      y=offset,
      group=ld8) +
    geom_line(color="black")+
    geom_point() +
    see::theme_modern(axis.text.angle = 90)+
    scale_y_continuous(breaks=c(-2:9)) +
    labs(title="TTL Offset calc: DoD vs Tent Peak by sessions")
