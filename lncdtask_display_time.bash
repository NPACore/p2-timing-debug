#!/usr/bin/env bash
# 
if [[ $# -eq 0 || "$*" =~ "^-+h" ]]; then
   cat >&2 <<HEREDOC
USAGE: $0 [anti|glob/to/*log]

output is tab separated id,run number,unix epoch

given lncdtask like log output
 1. find 'starting task' unix epoch timestamp and
 2. pair with extracted IDPATT from log fliename


change ID pattern like
  IDPATT=[0-9]{5}_[0-9]{8} $0 ../*/log/sub-*.log
HEREDOC

   exit 1
fi

case "${1:?task name or glob}" in
   anti) logfiles=(/Volumes/L/bea_res/Data/Tasks/DollarReward2/MR/1*_*/log/sub-*.log);;
   *) logfiles=("$@");;
esac

test ! -r "${logfiles[0]}" && echo "ERROR: bad input. '$_' does not exit" >&2 && exit 2

export IDPATT=${IDPATT:-'[0-9]{5}_[0-9]{8}'}
perl -slane '
    next unless s/ starting task//;
    s/\r//g;
    $onset = $_;
    $id=($ARGV =~ /$ENV{IDPATT}/)?$&:$ARGV;
    $run=($ARGV =~ /run-(\d+)/)?$1:0;
    print "$id\t$run\t$onset";
    close($ARGV)
    ' "${logfiles[@]}"
