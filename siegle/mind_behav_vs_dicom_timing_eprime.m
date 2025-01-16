function s=mind_behav_vs_dicom_timing_eprime(id,daynum)
% checks whether start time for behavioral file matches start time
% for dicom

cd ('/ix1/ginger/gsiegle/mind/physiodata/behav_fMRI');
badtime=datetime(1000,1,1,0,0,-999);

btasks={'AS_MIND','AS_FANI', 'Rest','EEGCalib_MIND'};
for tasknum=1:length(btasks)
  bf=dir(sprintf('%s*-%d-%.2d*.txt',btasks{tasknum},id,daynum));
  if isempty(bf)
       bf=dir(sprintf('%s*-%d-%d*.txt',btasks{tasknum},id,daynum));
  end
  if isempty(bf) & strcmp(btasks{tasknum},'Rest')
    bf=dir(sprintf('Baseline*-%d-%.2d*.txt',id,daynum));  
  end
  if isempty(bf) & strcmp(btasks{tasknum},'Rest')
    bf=dir(sprintf('Baseline*-%d-%d*.txt',id,daynum));  
  end

  if isempty(bf)
    s.behtime(tasknum)=badtime;
  else
   try
    behavfname=bf(1).name;
    % can do mindreadansbehav which gets stimonsettime data - but
    % these seem to be in milliseconds from task
    % onset
    % but really - has SessionTime which is the start of the program
    % and then the first OnsetTime starts the program
    if isunicode(behavfname)
      ansifname=sprintf('%s_ansi',behavfname);
      if ~probe(ansifname)
	fprintf('%s is unicode. Moving original to %s_orig and converting\n',behavfname,behavfname);
	unicode2ascii(behavfname,ansifname);
      end
      behavfname=sprintf('%s_ansi',behavfname);
    end
    
    rawtxt=textread(behavfname,'%s','delimiter',':\n','whitespace',''); % had whitespace be \n
    st=find(strcmp('SessionTime',rawtxt)); 
    beh.hour=str2num(rawtxt{st(1)+1});
    beh.minute=str2num(rawtxt{st(1)+2});
    beh.second=str2num(rawtxt{st(1)+3});

    stt=find(~cellfun('isempty',(strfind(rawtxt,'OnsetTime'))));
    toff=str2num(rawtxt{stt(1)+1})./1000;
    s.behtime(tasknum)=datetime(1000,1,1,beh.hour,beh.minute,beh.second)+seconds(toff);
   catch
     s.behtime(tasknum)=badtime;
   end
  end
end
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ftasks={'as_mind','as_fani', 'rfmri','eegcal'};
for tasknum=1:length(ftasks)
  cd(sprintf('/ix1/ginger/gsiegle/mind/raw/%d_%d',id,daynum)); 
  dirs=dir(sprintf('*-%s_tfmri',ftasks{tasknum}));
  if isempty(dirs)
      s.acqtime(tasknum)=badtime;
      s.seriestime(tasknum)=badtime;
      if ~isfield(s,'seriesdate')
	s.seriesdate=sprintf('%d/%d/%d',99,99,9999);
      end
  else
      taskdir=dirs(1).name;
      cd(sprintf('/ix1/ginger/gsiegle/mind/raw/%d_%d',id,daynum));
      cd(taskdir)

      % In a Siemens DICOM file, 
      % "SeriesTime" refers to the time the entire imaging series was acquired, 
      % "AcquisitionTime" represents the specific time when the image data was captured during the scan, and 
      % "ContentTime" is typically considered the time when the image data was reconstructed and finalized, 
      %   often being very close to the "SeriesTime" in most scenarios; 
      % essentially, "AcquisitionTime" is considered the most precise moment of data capture within a series, 
      % "SeriesTime" and "ContentTime" provide a broader timeframe for the entire image sequence.
      
      fils=dir('MR*');
      if isempty(fils)
          fils=dir('*.dcm');
      end
      dicomfname=fils(1).name;
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
      
      dm.year=str2num(dm.SeriesDate(1:4));
      dm.month=str2num(dm.SeriesDate(5:6));
      dm.day=str2num(dm.SeriesDate(7:8));    
      s.seriesdate=sprintf('%d/%d/%d',dm.month,dm.day,dm.year);

      tasknum=tasknum+1;
  end
end
s.difftiming=s.acqtime-s.behtime;
s.tasks=ftasks;
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
s.reldifftiming=s.difftiming-max(s.difftiming(find(s.behtime~=badtime)));
s.reldifftiming(find(s.behtime==badtime))=seconds(-999);
s.reldifftiming(find(s.acqtime==badtime))=seconds(-999);
