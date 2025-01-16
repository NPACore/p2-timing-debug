function s=mind_behav_vs_dicom_timing_vabf(id)
% checks whether start time for behavioral file matches start time
% for dicom

badtime=datetime(1000,1,1,0,0,-999);
  

cd ('/ix1/ginger/gsiegle/mind/physiodata/behav_fMRI');

% do matlab vabfdata-?????_Pre-Intervention.mat
% These have vabfdata.TrialStartTimes
% on which you can extract hours, minutes, seconds
try
  load(sprintf('vabfdata_%d_Pre-Intervention.mat',id));
  rs=vabfdata.RunStartTimes; % from clocksec which is the seconds since midnight
  beh.hour=floor(rs./(60.*60));
  rsm=rs-beh.hour.*(60.*60);
  beh.minute=floor(rsm./60);
  rss=rsm-(beh.minute.*60);
  beh.sec=rss;
  s.behtime(1:2)=datetime(1000,1,1,beh.hour,beh.minute,beh.sec);
catch
  s.behtime(1:2)=badtime;
end

try
  load(sprintf('vabfdata_%d_Post-Intervention.mat',id));
  rs=vabfdata.RunStartTimes; % from clocksec which is the seconds since midnight
  beh.hour=floor(rs./(60.*60));
  rsm=rs-beh.hour.*(60.*60);
  beh.minute=floor(rsm./60);
  rss=rsm-(beh.minute.*60);
  beh.sec=rss;
  s.behtime(3:4)=datetime(1000,1,1,beh.hour,beh.minute,beh.sec);
catch
  s.behtime(3:4)=badtime;
end
 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tasknum=1;
days=[3 15];
for daynum=1:length(days)
  try
    cd(sprintf('/ix1/ginger/gsiegle/mind/raw/%d_%d',id,days(daynum)));
    dirs=dir('*-vabf_tfmri');
    for dn=1:length(dirs)
      taskdir=dirs(dn).name;
      cd(sprintf('/ix1/ginger/gsiegle/mind/raw/%d_%d',id,days(daynum)));
      cd(taskdir)
      
      % In a Siemens DICOM file, 
      % "SeriesTime" refers to the time the entire imaging series was acquired, 
      % "AcquisitionTime" represents the specific time when the image data was captured during the scan, and 
      % "ContentTime" is typically considered the time when the image data was reconstructed and finalized, 
      %   often being very close to the "SeriesTime" in most scenarios; 
      % essentially, "AcquisitionTime" is considered the most precise moment of data capture within a series, 
      % "SeriesTime" and "ContentTime" provide a broader timeframe for the entire image sequence.
      
      fils=dir;
      dicomfname=fils(3).name;
      dm=dicominfo(dicomfname);
      %[dm.StudyTime; dm.SeriesTime; dm.AcquisitionTime; dm.ContentTime]
      % it seems we should use the AcquisitionTime of the first image for the
      % trigger
      % in the format HHMMSS.FractionOfSeconds
      
      dm.hour=str2num(dm.AcquisitionTime(1:2));
      dm.minutes=str2num(dm.AcquisitionTime(3:4));
      dm.seconds=str2num(dm.AcquisitionTime(5:end));
      s.acqtime(tasknum)=datetime(1000,1,1,dm.hour,dm.minutes,dm.seconds);
      
      dm.hour=str2num(dm.SeriesTime(1:2));
      dm.minutes=str2num(dm.SeriesTime(3:4));
      dm.seconds=str2num(dm.SeriesTime(5:end));
      s.seriestime(tasknum)=datetime(1000,1,1,dm.hour,dm.minutes,dm.seconds);
      tasknum=tasknum+1;

      dm.year=str2num(dm.SeriesDate(1:4));
      dm.month=str2num(dm.SeriesDate(5:6));
      dm.day=str2num(dm.SeriesDate(7:8));    
      s.seriesdate=sprintf('%d/%d/%d',dm.month,dm.day,dm.year);
      
    end
  catch
    s.acqtime(tasknum:tasknum+1)=badtime;
    s.seriestime(tasknum:tasknum+1)=badtime;
    tasknum=tasknum+2;
    if ~isfield(s,'seriesdate')
      s.seriesdate=sprintf('%d/%d/%d',99,99,9999);
    end

  end
end
if length(s.acqtime)<4
  s.acqtime(end+1:4)=badtime;
end
if length(s.behtime)<4
  s.behtime(end+1:4)=badtime;
end


s.difftiming=s.acqtime-s.behtime;
s.tasks={'Pre_Block1','Pre_Block2','Post_Block1','Post_Block2'};
% this always looks like the behavioral started before the dicom. 
% that can't be right. Probably there are 
% systematic differences between the clocks. To correct that, let's
% assume the task never started before the dicom. So we subtract
% the max positive difference as zero. Now negative numbers are the
% true offsets
%s.reldifftiming=s.difftiming-max(s.difftiming);
% note this is probably not quite right... The measurements on a
% given day seem very close to each other but not between days. 
% So, the clock may be off
% different amounts on different days. 
s.reldifftiming(1:2)=s.difftiming(1:2)-max(s.difftiming(1:2));
s.reldifftiming(3:4)=s.difftiming(3:4)-max(s.difftiming(3:4));

