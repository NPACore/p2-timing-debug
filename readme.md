# Time differences between MR task trigger and DICOM Acq time

![](missed_ttl_cartoon.svg)

## Overview

The MRRC Prisma 2 fiber to copper TTL converter box likely started failing in 2023-07 and was caught and replaced 2024-12.

This repository demonstrates pulling task onset times from two independent sources, the task display computer and the scan computer, to check for mismatches as a result of erroneously missing TTL TR triggers (`=` sent to start the task).

We can combine the two sources useing participant ID, session date, task name, and run number to explore timing differences.

Unfortunately, we cannot directly compare onset times because the computer clocks are not synced. But that can be tackled different ways

  1. With enough display onset + MR onset pairs, we can model the offset and dift between the clocks.
  2. For sessions with multiple back-to-back tasks or runs, for example the `AntiSaccade` task herein, we can compare the MR-display offset from run1 to run2 to check the task start time onsets. **If TTL was not sent when expected, this difference of differences will be non-zero and greater than the TR of the task acquisition**.
  3. deconvolve high HRF responses in fMRI task data with a TENT model to measure peak response against expected time


See [`Makefile`](Makefile) for recipes.

### Hardware failure
![](ttl_tracker/TTL.png)

## Notes on timing

Computer clocks drift [due to frequency error](https://www.ntp.org/ntpfaq/ntp-s-sw-clocks-quality/)
> Even if the systematic error of a clock model is known, the clock will never be perfect. This is because the frequency varies over time, mostly influenced by temperature, ... or magnetic fields.
> ... oscillator’s correction value increases by about 11 PPM..
> .. 12 PPM correspond to one second per day 

On the scan side, first dicom's `Acquisition Time` is the closest to the pulse send time (see [`mr_time.bash`](mr_time.bash)).
[neurostars](https://neurostars.org/t/dicom-header-acquisition-time-study-time-series-time-content-time/23280/2), [snug-discuss](https://www.snug-discuss.org/t/what-is-relationship-between-acquisitiontime-in-dicom-and-trigger-pulse/490/3)
> (0008,0032) Acquisition Time → MARS timestamp
> MHD.DICOM.AcquisitionTime is defined by the timestamp of the first ‘imaging’ Readout of a certain slice (Mdh.isImagingScan(), Mdh.getTimeStamp()).

On the task side, 
 * E-Prime logs session start (task loaded, `SessionSTartDateTimeUtc`) with only second precision (?)  and hopefully first `=` translated scanner TR pulse like `WaitForScanner.OnsetTime` in milliseconds. See [`extract_eprime.pl`](extract_eprime.pl).
 * PsychoPy can record flip time in unix epoch. See [`lncdtask_display_time.bash`](lncdtask_display_time.bash).
 * In psychtoolbox, on Windows, `GetSecs()` is ["number of seconds since system start up"](http://psychtoolbox.org/docs/GetSecs) and will need an additional timestamp to covert events to time. Maybe file modification time?

## HRF
Here are two individual runs with button pushes modeled using `TENT`. The top run was triggered when expected whereas the bottom was tiggered late but modeled with stim onsets as if the task startd when expected. The cross hairs are focused on motor cortex. You can see the response is delayed in the bottom plot (index 5 instead of index 2).
![](afni_hrf.png)

```
3dDeconvolve \
      -overwrite \
      -input "$habit_task" \
      -jobs 32 \
      -num_stimts 1 \
      -ortvec "$regs" confounds \
      -stim_times 1 "$eventd/button.1d"  'TENT(0,13,11)'  -stim_label 1 all_pushes \
      -bucket  "${outprefix}_bucket.nii.gz" \
      -iresp 1 "${outprefix}_iresp.nii.gz" \
      -fout -rout
```

## Modeling drift

  * MR clock start time for all `epfid2d1` (bold EPI) are in [`txt/mr_times_p2.tsv`](txt/mr_times_p2.tsv).
  * an example for parsing eprime logs is in [`extract_eprime.pl`](extract_eprime.pl).
  * pairing the two (WIP) in [`merge.R`](merge.R). Currently (20241223), [`model_time.R`](model_time.R) has the most insight into the clock drift.


![](clock_drift.png)
![](clock_drift_lm.png)

MR time is moved into UTC timezone to avoid daylight savings time jumps. Still, the drift has discrete jumps likely from one clock being adjusted manually.

## Example session diff

![](run_diffs_over_date.png)

|script|desc|
|---|---|
|[`lncdtask_display_time.bash`](lncdtask_display_time.bash) | extract "EPrime" PC task start time from log|
|[`mr_time.bash`](mr_time.bash) | extract acquisition start time from first dicom in series|
|[`merge_luna_anti.R`](merge_luna_anti.R)| merge times and explore the onset differences |



| output file | desc| 
| ---- | ----| 
| [`txt/combined_tdiff.csv`](txt/combined_tdiff.csv) | diff of differences, see [`merge.R`](merge.R) |
| [`txt/combined_anti_times.csv`](txt/combined_anti_times.csv) | row per visit, merged times ready for inspecting | 
| `txt/luna/anti_task_display.tsv`      | `=` trigger recieved times from task/display PC| 
| `txt/luna/anti_task_mr.tsv`           | DICOM Acq Time headers | 


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
