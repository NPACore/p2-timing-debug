#!/usr/bin/env bash
#
# example decon
#
# 20220916WF - init
# 20250130WF - running to test TTL missing
#   also see ./button_tent_series.bash and ./button_tent_series.R
#
#   mkmissing -p '\d{5}_[12]' -1 '../mhproc/*/habit/func.nii.gz' -2 'decon/btn/1*_*/mdl-btn_tent_in-mhfmp_cnf-no_mask_iresp.nii.gz'|xargs -n1  echo ./button_push_decon.bash
# 
#
[ -v DRYRUN ] && DRYRUN=echo || DRYRUN=
warn(){ echo "$@" >&2; }

decon_button(){
   [ $# -ne 1 ] &&
      echo -e "USAGE: $0 id_ses\nsee mhproc/\$id_ses; output to decon/btn/" &&
      return 1
   id_ses="${1-?ses id}"
   ! [[ $id_ses =~ [0-9]{5}_[0-9]$ ]] && echo "expect lunaid_sesnumber (1234_1)" && return 1
   id=${id_ses%_*}
   ses=${id_ses##*_}
   confounds="../deriv/sub-$id/ses-$ses/func/sub-${id}_ses-${ses}_task-habit_desc-confounds_timeseries.tsv"
   oned=$(ls -d txt/1d/"${id_ses}"_[0-9]*/btn/|sed 1q)
   ! [[ $oned =~ ([0-9]{5})_([0-9]_[0-9]{8}) ]] && echo "failed to find id_ses_vdate in $oned" >&2 && exit 1
   lds8="${BASH_REMATCH[0]}" # full match 12345_1_20001231
   eventd="txt/1d/$lds8/btn"

   #mhfmp="../mhproc/11878_1/habit/nfsk_func_5.nii.gz"
   mhfmp="../mhproc/$id_ses/habit/nfsk_func_5.nii.gz"
   [ ! -r "$mhfmp" ] && echo "missing mhproc: $mhfmp" >&2 && exit 1
   [ ! -r "$confounds" ] && echo "missing confound: $confounds" >&2 && exit 1
   [ ! -r "$eventd" ] && echo "missing 1d folder: $eventd" >&2 && exit 1

   outd="decon/btn/$lds8"
   test -d "$outd" || mkdir -p "$outd"

   idxes=$(sed 's/\t/\n/g;1q' "$confounds"|cat -n |grep 'rot_.$|fd|csf_wm|global_signal$|trans_.$' -P|awk '{print $1-1}'|paste -sd,)
   warn "# using idxes: $idxes"
   #idxes="0,12,301,305,309,313,317,321"
   regs=$confounds"[$idxes]{1..$}"

   outprefix=$outd/mdl-btn_tent_in-mhfmp_cnf-no_mask
   test -r "${outprefix}_bucket.nii.gz" && echo "# have $_" && exit 0
   $DRYRUN 3dDeconvolve \
      -overwrite \
      -input "$mhfmp" \
      -jobs 32 \
      -num_stimts 1 \
      -ortvec "$regs" confounds \
      -stim_times 1 "$eventd/all.1d"  'TENT(0,13,11)'  -stim_label 1 all_pushes \
      -bucket  "${outprefix}_bucket.nii.gz" \
      -iresp 1 "${outprefix}_iresp.nii.gz" \
      -fout -rout
}

# if not sourced (testing), run as command
if ! [[ "$(caller)" != "0 "* ]]; then
  set -euo pipefail
  trap 'e=$?; [ $e -ne 0 ] && echo "$0 exited in error $e"' EXIT
  decon_button  "$@"
  exit $?
fi

####
# testing with bats. use like
#   bats ./button_push_decon.bash --verbose-run
####
function init_test { #@test 
   [ 0 -eq 1 ]
}
