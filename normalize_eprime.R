#!/usr/bin/env Rscript

suppressPackageStartupMessages({library(dplyr); library(lubridate);library(stringr);})

d <- read.table('txt/eprime_times.tsv',sep="\t",header=T)
normed <- d |>
    transmute(wpc='WPC-UNKNOWN',
              #wpc=case_when(
                  #grepl('CENTRIM', file) ~ "WPC-Phil1",
                  #grepl('^(C4|FH)', file) ~ "WPC-Sarp",
                  #grepl('^(alcpic)', file) ~ "WPC-Clark",
                  #grepl('^Diamond', file) ~ "WPC-Phil2",
                  #grepl('^Resting_plus', file) ~ "WPC-Phil3",
                  #.default="WPC-UNKNOWN"),
              sess_id=id_fname,
              task=gsub('-.*.txt','',file),
              run=1,
              acqtime=acqtime_task)

write.table(normed, 'txt/eprime-norm.tsv', sep="\t", quote=F, row.names=F)
