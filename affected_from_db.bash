#!/usr/bin/env bash

DB=db.sqlite
find_bold_in_db(){
  sqlite3 -separator $'\t' "$DB" "
select Project, SubID, AcqDate, AcqTime, SequenceName, SequenceType, SeriesNumber 
from acq join acq_param on acq.param_id=acq_param.rowid
where 
  SequenceType like '%epfid2d%'
  -- and Station like 'MRC67078'
  and Station like 'AWP167046'
  -- and not SequenceName like '%rest%'
  and not SequenceName like '%SBRef%'
  and not SequenceName like '%MoCoSeries%';"
}

find_dir() {
 proj="${1-?project like Brain^wpc-8620}"; shift
 acqdate="${1-?date like yyymmdd}"; shift
 projdir=${proj/Brain^/}
 projdir=${projdir^^}
 sesdir="${acqdate:0:4}.${acqdate:4:2}.${acqdate:6:2}"
 #echo "$proj => $projdir; $acqdate => $sesdir" >&2
 echo /disk/mace2/scan_data/${projdir}/$sesdir*/$subj/*.$series
}

if [[ "$(caller)" == "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e" >&2' EXIT
  find_bold_in_db |
   while read proj subj acqdate acqtime name type series; do
     dir=$(find_dir "$proj" "$acqdate")
     test ! -d "$dir" && echo "#WARNING: no '$_' dir" >&2 && continue
     grep -q "$dir" ./txt/mr_times_p2.tsv && continue
     echo "$dir" 
  done | xargs ./mr_time.bash
  exit $?
fi
