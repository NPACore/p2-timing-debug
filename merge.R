add_tasknum <- function(d) d|>
    arrange(acqtime) |>
    group_by(wpc,sess_id,sess_day=format(acqtime,"%Y%m%d"))|>
    mutate(task_num=rank(acqtime)) |> ungroup() |> select(-sess_day)

add_hr <- function(d) d|>mutate(acqhr=format(acqtime,"%Y%m%dT%H"))

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
           acqtime=ymd_hms(acqdt, tz = "America/New_York")|>with_tz("UTC"),
           wpc=stringr::str_extract(rundir,'(?<=scan_data/)[A-Za-z]+-\\d+'),
           sess_id=stringr::str_extract(rundir,'(?<=\\.[0-9]{2}\\.[0-9]{2}/)[^/]+'),
           name=gsub('_[0-9x.]+$','',basename(rundir)),
           series=stringr::str_extract(rundir,'(?<=\\.)[0-9]+$'),
           rundir=gsub('.*scan_data/','',rundir)
           ) %>%
    select(-acqdate, -acqdt) |>
    add_tasknum()

matched <- merge(mr, all_display, all=F,suffixes=c("_mr","_disp")) |>
    mutate(tdiff=seconds(acqtime_mr-acqtime_disp), task_diff=task_num_mr-task_num_disp) |>
    #group_by(acqtime_hr,sess_id,task) |> filter(abs(tdiff)==min(abs(tdiff))) |>
    #ungroup()|>group_by(acqtime_hr,acqtime_mr) |> filter(abs(tdiff)==min(abs(tdiff))) |>
    arrange(acqtime_hr)
write.csv(matched, 'txt/combined_normalized.tsv', quote=F, row.names=F)

## easy viewing
hmsf <- function(x) format(x, "%H:%M:%S")
match_view <-matched %>% ungroup() |>
    transmute(mr=hmsf(acqtime_mr),disp=hmsf(acqtime_disp),
              wpc_mr, wpc_disp,
              tdiff=round(tdiff),
              task_diff,
              sess_id_disp, task, run,
              dir=gsub('.*\\.[0-9]{2}\\.[0-9]{2}/','',rundir))
match_view |> filter(!grepl('8620',wpc_mr), task_diff==0)
