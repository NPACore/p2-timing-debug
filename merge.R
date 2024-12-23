all_display <-
    readr::read_delim(Sys.glob('txt/*norm.tsv'), delim="\t") |>
    mutate(acqtime_hr=gsub(':\\d+:\\d+$','',acqtime),
           acqtime=lubridate::ymd_hms(acqtime))

mr <- read.table(text=system("sed 's/ /\t/g' txt/mr_times.tsv", intern=T),
                 sep="\t",
                 colClasses='character',
                 col.names=c("rundir","acqdate", "acqtime", "tr")) %>%
    mutate(acqdt=paste0(acqdate," ", substr(acqtime,1,2) ,":", substr(acqtime,3,4) ,":", substr(acqtime,5,99)),
           acqtime=ymd_hms(acqdt, tz = "America/New_York")|>with_tz("UTC"),
           acqtime_hr=format(acqtime,"%Y-%m-%d %H"),
           wpc=stringr::str_extract(rundir,'(?<=scan_data/)[A-Za-z]+-\\d+')
           ) %>%
    select(-acqdate, -acqdt)

matched <- merge(mr, all_display, by="acqtime_hr",all=F,suffixes=c("_mr","_disp")) |>
    mutate(tdiff=seconds(acqtime_mr-acqtime_disp)) |>
    group_by(acqtime_hr,sess_id,task) |> filter(abs(tdiff)==min(abs(tdiff))) |>
    arrange(acqtime_hr)

matched %>% ungroup() |> transmute(acqtime_mr,acqtime_disp, wpc_mr,wpc_disp, tdiff=round(tdiff), rundir)
