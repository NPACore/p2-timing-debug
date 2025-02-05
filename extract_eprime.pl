#!/usr/bin/env perl
use strict; use warnings; use feature qq/say/;
use Time::Piece;
use open IN=>":encoding(utf-16)";
use File::Basename 'basename';

# 20241223WF - init, extracted from one liner

if($#ARGV < 0 or "@ARGV" =~ /^-+h/){
   print <<HEREDOC;
USAGE:
 $0 path/to/*eprime/*log\n

SYNOPSIS:
 get scanner start time combining:
  SessionStartDateTimeUtc: 2/1/2024 7:09:40 PM
  WaitForScanner.OnsetTime: 46713
 
 get id from log file like
  Resting_plus_questionnaire_MNA-\${YYYMMDD.ID}-1.txt

 print tsv of session start time from (UTF-16 encoded) eprime text log file
 combines SessionSTartDateTimeUtc with Onset time of '=' trigger

 NB. also includes Clock.Information which is often a second off from SessionSTartDateTimeUtc
HEREDOC

   exit(1)
}

print join("\t",qw/file Start task_clock clock_count clock_freq TriggerOffset acqtime_task id_fname id_log/),"\n";

foreach my $fname (@ARGV) {
 my $sesid_file=$fname=~s/.*[_.-]([^-]+)-\d+.txt.*/$1/r;
 my $sesid_label="NA";
 my ($on_utcstr, $offset, $on_clock, $clock_count, $freq);
 open(my $fh, '<', $fname) or die "$fname: $!";
 while($_=<$fh>) {

    if(m/SessionStartDateTimeUtc: (.*(AM|PM))/){
       $on_utcstr=Time::Piece->strptime($1, "%m/%d/%Y %r");
       next;
    }

    # subject not always set. grabbing anyway but maybe trust filename over this
    if(m/Subject: (.*)\S?/){
      $sesid_label=$1;
      next;
    }

    # TODO: bottom of file has clock info but is occastionally a second before SessionStartDateTimeUtc
    # Clock.Information: <?xml version="1.0"?>\n<Clock xmlns:dt="urn:schemas-microsoft-com:datatypes"><Description dt:dt="string">E-Prime Primary Realtime Clock</Description><StartTime><Timestamp dt:dt="int">0</Timestamp><DateUtc dt:dt="string">2024-05-23T12:05:56Z</DateUtc></StartTime><FrequencyChanges><FrequencyChange><Frequency dt:dt="r8">3515693</Frequency><Timestamp dt:dt="r8">1535486416407</Timestamp><Current dt:dt="r8">0</Current><DateUtc dt:dt="string">2024-05-23T12:05:56Z</DateUtc></FrequencyChange></FrequencyChanges></Clock>
    if(m/Timestamp><DateUtc dt:dt="string">(.*?)Z<.*<Frequency dt:dt="r8">(\d+)<.*<Timestamp dt:dt="r8">(\d+)</){
       # 2024-01-16T19:19:30
       # TODO: used  dt="r8" -- not unix (or windows?) epoch time
       $on_clock=Time::Piece->strptime($1, "%Y-%m-%dT%H:%M:%S");
       $freq=$2;
       $clock_count=$3;
       next;
    }

    # seen PreSipRating.OnsetTime (ncanda alc), WaitForScanner, and WaitForScanner1 
    if(/(PreSipRating|WaitRF|WaitForScanner.*)\.OnsetTime: (\d+)/){
        $offset=$2;
     }
 }

 close($fh);
 if(not $on_utcstr and not $on_clock){
    print(STDERR "WARNING: no 'SessionStartDateTimeUtc' or Clock Timestamp_r8 in '$fname'\n");
    next;
 }
 if(not $offset){
   print(STDERR "WARNING: '$fname' did not have expected log info. not extracted\n") if(not $offset);
   next;
 }
 say join("\t", basename($fname),
           $on_utcstr||"", $on_clock||"",
           $clock_count||"",
           $freq||"",
           $offset,
           (($on_utcstr||$on_clock)+$offset/1000)->strftime("%F %R:%S"),
           $sesid_file, $sesid_label);
}
