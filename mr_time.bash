#!/usr/bin/env bash
get_acq_times(){
  find "${1:?input dicom folder to get times}"  \
    -iname 'MR*' \
    -exec dicom_hinfo -no_name -tag 0008,0022 -tag 0008,0032 {} \+
}
first_time(){ sort -n | sed 1q; }

all_runs=(/disk/mace2/scan_data/WPC-8620/2*/1*_2*/*RewardedAnti*[^f]_704*/)
echo "[$(date)] have ${#all_runs[@]} runs"

for run in "${all_runs[@]}"; do
  time_first=$(get_acq_times "$run" | first_time)
  echo -e "$run\t$time_first"
done | tee txt/anti_task_mr.tsv

echo "[$(date)] finished"
