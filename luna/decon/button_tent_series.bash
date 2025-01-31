#!/usr/bin/env bash
#
# 20250130WF - init
#

thres=2.9103 # Fstat of p=.01
#thres=4      # only what fits really well. missing most w/bad TTL at 6
for bucket in decon/btn/1*_[1-3]_2*/mdl-btn_tent_in-mhfmp_cnf-no_mask_bucket.nii.gz; do
  tent=${bucket/bucket.nii.gz/iresp.nii.gz}
  ! [[ $bucket =~ [0-9]{5}_[0-3]_[0-9]{8} ]] && warn "no id in $bucket" && continue 
  id="${BASH_REMATCH}"
  outdir=txt/ts/btn/${id}/
  mkdir -p "$outdir"
  out=$outdir/PMC_fstat-${thres}.txt
  mask=$outdir/PMC_fstat-${thres}_mask.nii.gz
  [ -r "$out" ] && continue
  ! [ -r "$mask" ] &&
     3dcalc -m Glasser-leftPrimMotor_res-func.nii.gz \
     -t "${bucket}[all_pushes_Fstat]"  \
     -expr "m*step(t-$thres)" \
     -prefix "$mask" 

  [[ "$(3dBrickStat -max "$mask" )" =~ ^0 ]] && warn "$mask: no values in mask" && continue

  3dROIstats \
   -mask "$mask" \
   -nzmean -nzvoxels -nzsigma -nomeanout \
   "$tent" > "$out"
  ! grep -q NZMean_1 "$out" && rm "$out"
done
