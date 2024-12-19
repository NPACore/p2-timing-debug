# Time differences between MR task trigger and DICOM Acq time


## Overview
This repository demonstrates pulling task onset times from two independent sources, the task display computer and the scan computer, to check for mismatches as a result of erroneously missing TTL TR triggers (`=` sent to start the task).

Using participant ID (and possibly session date), we can combine the two sources and explore timing differences.

Unfortunately, we cannot directly compare onset times because the computer clocks are not synced. 

For the `AntiSaccade` task herein, we have two runs of the same task back to back and can compare the MR-display offset from run1 to run2 to check the task start time onsets. **If TTL was not sent when expected, this difference of differences will be non-zero and greater than the TR of the task acquisition**.


To this end, we extract the participant ID and task start time for each source, merge the two datasets, and compare timing offsets.

|script|desc|
|---|---|
|[`display_time.bash`](display_time.bash) | extract "EPrime" PC task start time from log|
|[`mr_time.bash`](mr_time.bash) | extract acquisition start time from first dicom in series|
|[`merge.R`](merge.R)| merge times and explore the onset differences |

See [`Makefile`](Makefile) for recipes

## Comparison
(extreme outliers -- bad input data? -- removed)

![](run_diffs_over_date.png)

| file | desc| 
| ---- | ----| 
| [`txt/combined_tdiff.csv`](txt/combined_tdiff.csv) | diff of differences, see [`merge.R`](merge.R) |
| [`txt/combined_mr_task_times.csv`](txt/combined_mr_task_times.csv) | row per visit, merged times ready for inspecting | 
| `txt/anti_task_display.tsv`      | `=` trigger recieved times from task/display PC| 
| `txt/anti_task_mr.tsv`           | DICOM Acq Time headers | 


## Pull repo data (Git Large File Storage)

using [`git-lfs`](https://git-lfs.com/) to store csv and png files.
```
git clone https://github.com/NPACore/p2-timing-debug
cd p2-timing-debug
git lfs install
git lfs checkout
```

## Stats

```
tdiff <- read.csv('txt/combined_tdiff.csv')
summary(tdiff$tdiff)
     Min.   1st Qu.    Median      Mean   3rd Qu.      Max.
-338.9225   -0.0135    0.2300   -4.0310    0.5670   72.8050
```

## More than 1 seconds off

```
times <- read.csv('txt/combined_mr_task_times.csv')
tdiff <- read.csv('txt/combined_tdiff.csv')
tdiff %>%
 filter(abs(tdiff)>1) %>%
 transmute(sesid=paste(luanid,gsub('-','',vdate),sep="_"),diffdiff=tdiff) %>%
 merge(times, by="sesid") %>%
 head
```

```
           sesid diffdiff run          acqtime_mr        acqtime_task    tdiff
1 11957_20230720   6.3005   2 2023-07-20 09:41:48 2023-07-20 13:39:40 14271.81
2 11957_20230720   6.3005   1 2023-07-20 09:35:42 2023-07-20 13:33:27 14265.51
3 11958_20230801  15.1875   2 2023-08-01 13:30:55 2023-08-01 17:28:50 14274.54
4 11958_20230801  15.1875   1 2023-08-01 13:24:59 2023-08-01 17:22:38 14259.35
5 11961_20230725  72.8050   1 2023-07-25 15:40:10 2023-07-25 19:37:53 14262.88
6 11961_20230725  72.8050   1 2023-07-25 15:38:58 2023-07-25 19:37:53 14335.69
```
