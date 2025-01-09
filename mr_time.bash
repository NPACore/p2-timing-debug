#!/usr/bin/env bash
get_acq_times(){
  # tab seprated dicom header values:
  # fname date time TR station
  # TODO: speed up by sorting file names and taking first?
  find "${1:?input dicom folder to get times}"  \
    \( -iname '*.dcm' -or -iname 'MR*' \) \
    -exec dicom_hinfo -no_name -sepstr $'\t' \
       -tag 0008,0022 -tag 0008,0032 -tag 0018,0080 -tag 0008,1010 {} \+ || :
}
first_time(){ sort -n | sed 1q; }

mr_times_of_pdirs(){

  cnt=1
  for run in "$@"; do
    [ $(( $cnt % 100)) -eq 0 ] && echo "# [$(date)] $cnt $run" >&2
    let ++cnt
    ! test -d "$run" && echo "# ERROR: '$run' is not a directory" >&2 && continue
    time_first=$(get_acq_times "$run" | first_time || :)
    [ -z "$time_first" ] && echo "# ERROR: '$run' missing dicom headers?" >&2 && continue
    echo -e "$run\t$time_first"
  done
}

usage(){
  echo "USAGE: $0 [anti|habit|/path/to/ses/id/pdir*glob]" >&2
  echo "$*" >&2
  exit
}

if [[ "$(caller)" == "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e" >&2' EXIT
  [ $# -lt 1 ] && usage "ERROR: need a study or path to work on"
  case "$1" in
     #anti) all_runs=(/disk/mace2/scan_data/WPC-8620/2*/1*_2*/*RewardedAnti*[^f]_704*/);;
     anti) all_runs=(/Volumes/Hera/Raw/MRprojects/Habit/2*/1*_2*/*RewardedAnti*[^f]_704*/);;
     habit) all_runs=(/Volumes/Hera/Raw/MRprojects/Habit/2*/1*_2*/HabitTask_704x752.*/);;
     *) test -d $1 || usage "ERROR: unknown study '$1' is not a directory/protocol dir";
        all_runs=("$@");;
  esac

  echo "[$(date)] have ${#all_runs[@]} runs" >&2
  mr_times_of_pdirs "${all_runs[@]}"
  echo "[$(date)] finished" >&2
fi
