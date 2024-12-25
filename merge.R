add_tasknum <- function(d) d|>
    arrange(acqtime) |>
    group_by(wpc,sess_id,sess_day=format(acqtime,"%Y%m%d"), task)|>
    mutate(task_num=rank(acqtime)) |> ungroup() |> select(-sess_day)

add_hr <- function(d) d|>mutate(acqhr=format(acqtime,"%Y%m%dT%H"))

## read in data
all_display <-
    readr::read_delim(Sys.glob('txt/*norm.tsv'), delim="\t") |>
    mutate(acqtime=lubridate::ymd_hms(acqtime)) |>
    add_tasknum()

mr <- read.table(#text=system(intern=T, "sed 's/ /\t/g' txt/luna/*_task_mr.tsv"),
                 "txt/mr_times_p2.tsv",
                 sep="\t",
                 colClasses='character',
                 col.names=c("rundir","acqdate", "acqtime", "tr")) %>%
    mutate(acqdt=paste0(acqdate," ", substr(acqtime,1,2) ,":", substr(acqtime,3,4) ,":", substr(acqtime,5,99)),
           # IMPORTANT! convert Eastern time zone to match UTC
           acqtime=ymd_hms(acqdt, tz = "America/New_York")|>with_tz("UTC"),
           wpc=stringr::str_extract(rundir,'(?<=scan_data/)[A-Za-z]+-\\d+'),
           sess_id=stringr::str_extract(rundir,'(?<=\\.[0-9]{2}\\.[0-9]{2}/)[^/]+'),
           task=gsub('_[0-9x.]+$','',basename(rundir)),
           series=stringr::str_extract(rundir,'(?<=\\.)[0-9]+$'),
           rundir=gsub('.*scan_data/','',rundir)
           ) %>%
    select(-acqdate, -acqdt) |>
    add_tasknum()

## quick inspect
mr |> group_by(wpc,task)|>summarise(n=n(), min(acqtime), max(acqtime))|>arrange(-n)|>filter(n>50)
#   wpc      name                           n `min(acqtime)`      `max(acqtime)`     
#   <chr>    <chr>                      <int> <dttm>              <dttm>             
# 1 WPC-8791 hooley                       118 2023-07-13 15:41:17 2024-12-20 17:55:10
# 2 WPC-8791 visstim                      116 2023-07-13 15:24:27 2024-12-20 18:05:20
# 3 WPC-8620 RewardedAntisaccade          112 2023-05-09 19:11:04 2024-12-19 14:42:49
# 4 WPC-8620 HabitTask                    109 2023-05-09 18:54:44 2024-12-19 14:21:04
# 5 WPC-8620 RewardedAntisaccade_repeat   108 2023-05-09 19:17:00 2024-12-19 14:49:10
# 6 WPC-8791 eegcal                       107 2023-07-13 15:33:19 2024-12-20 18:47:45
# 7 WPC-8791 alternating_1                102 2023-07-13 15:50:20 2024-12-20 18:14:09
# 8 WPC-8791 alternating_2                100 2023-07-13 15:57:38 2024-12-20 18:21:13
# 9 WPC-8791 alternating_3                 98 2023-07-13 16:04:41 2024-12-20 18:28:12
#10 WPC-8791 alternating_4                 97 2023-07-13 16:11:25 2024-12-20 18:35:02
#11 WPC-8791 rfmri                         95 2023-05-22 20:38:59 2024-12-20 18:56:45
#12 WPC-7084 cat-fluency                   83 2023-05-05 15:50:30 2024-12-16 22:01:23
#13 WPC-8399 vabf_tfmri                    74 2023-12-13 22:51:32 2024-12-16 13:51:05
#14 WPC-9053 Reward_task_mb                57 2024-01-19 20:14:42 2024-11-26 21:00:49
#15 WPC-8232 Task_AP_MID_1                 51 2023-05-26 20:27:16 2024-12-20 21:30:32

## all without modifications
easy_match <- merge(mr, all_display,
                 by=c("task","sess_id","wpc","task_num"),
                 all=F,
                 suffixes=c("_mr","_disp"))


## NCANDA
ncanda <- all_display |> filter(wpc=="WPC-6106", grepl('alc',task)) |>
    mutate(sess_id=sprintf("%05d", as.numeric(sess_id)),
           task='ncanda-alcpic-v1')

ncanda_match <- mr |>
    mutate(sess_id=gsub('[ACX]-[70](.*)-[MF]-[0-9]+$','0\\1',sess_id)) |>
    filter(grepl('alcpic',task)) |>
    merge(ncanda, by=c("task","sess_id","wpc"), suffixes=c("_mr","_disp"))

##

## All matches together
matched <- bind_rows(list(ncanda_match, easy_match)) |>
    mutate(tdiff=seconds(acqtime_mr-acqtime_disp))
    


## easy viewing
hmsf <- function(x) format(x, "%H:%M:%S")
match_view <-matched %>% ungroup() |>
    transmute(mr=hmsf(acqtime_mr),
              disp=hmsf(acqtime_disp),
              wpc,
              tdiff=round(tdiff),
              sess_id, task, run,
              dir=gsub('.*\\.[0-9]{2}\\.[0-9]{2}/','',rundir))
match_view |> filter(!grepl('8620',wpc))


matched <- matched |>
    mutate(mr_secs=as.numeric(acqtime_mr),
           mr_secs = mr_secs - min(mr_secs),
           tdiff_s=as.numeric(tdiff))
write.csv('txt/matched.csv', quote=F, row.names=F)

## model
match_clean <- matched |>
    filter(abs(tdiff)<400,tdiff>0)
# extreme filter. cut off in july before cock reset. ignore bad ncanda
match_cut <- match_clean |>
    filter(acqtime_mr <= ymd("2024-07-01"), !grepl("WPC-6106",wpc))
m <- lm(tdiff_s~mr_secs, data=match_cut)
drift_spd <- coef(m)['mr_secs']*(60*60*24) 
#  mr_secs 
#0.7347641 
ggplot(match_cut) +
    aes(x=acqtime_mr,y=tdiff,color=paste(wpc,task)) +
    geom_smooth(method='lm', aes(color=NULL)) +
    geom_point(data=match_clean) +
    theme_bw() +
    guides(color=F)+
    labs(title=sprintf("Clock drifts %.2f s/day", drift_spd),
         y='mr - disp (s)',
         x='acquisition date')

ggsave('clock_drift_lm.png') # 14 x 3.58
# failing: Error in obj0$residuals : $ operator is invalid for atomic vectors
library(segmented); select <- dplyr::select
sm <- segmented(m)
