function mind_all_behav_vs_dicom_timing_vabf()
cd('/ix1/ginger/gsiegle/mind/raw');
ids=dir('95*_3');
fp=fopen('/ix1/ginger/gsiegle/mind/weekly_updates/stimtiming.csv','w');
fprintf(fp,'id,date,Pre1diff,Pre2Diff,Post1diff,Post2diff,Pre1BehTime,Pre2BehTime,Post1yBehTime,Post2BehTime,Pre1AcqTime,Pre2AcqTime,Post1AcqTime,Post2AcqTime,\n');
for sub=1:length(ids)
  id=str2num(ids(sub).name(1:5));
  s=mind_behav_vs_dicom_timing_vabf(id);
  secs=seconds(s.reldifftiming);
  for ct=1:4
    beht{ct}=sprintf('%d:%d:%.2f',hour(s.behtime(ct)),minute(s.behtime(ct)),second(s.behtime(ct)));
    acqt{ct}=sprintf('%d:%d:%.2f',hour(s.acqtime(ct)),minute(s.acqtime(ct)),second(s.acqtime(ct))); 
  end 
  fprintf(fp,'%d,%s,%.2f,%.2f,%.2f,%.2f,%s,%s,%s,%s,%s,%s,%s,%s\n',id,s.seriesdate,secs(1),secs(2),secs(3),secs(4),beht{1},beht{2},beht{3},beht{4},acqt{1},acqt{2},acqt{3},acqt{4});
  fprintf('.');
end
fclose(fp);
