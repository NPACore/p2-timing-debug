% TR per slice for MB EPI BOLD sequence
% CHM @2024-10-09
%


% Series name
pfolder = 't-clock1_wpc-7341_pdir-A>P_e-bsocial_s-mbep2d_448x448.11';
pfolder = '.';

% fMRI DICOM files
D = dir([pfolder '/MR.*']);
n = length(D);

% MB factor, interleaved slice acquisition from FOOT to HEAD
MB = 5;
bintlv = true; %false; %true;

% Loop for time-series fMRI data
AcquisitionTime = [];
for i=1:1 %n
    name = D(i,1).name;
    folder = D(i,1).folder;
    P = [folder '/' name]; disp(P);
    
    info = dicominfo(P);
        
    TR = info.RepetitionTime;
    TE = info.EchoTime;
    %nslc = ;
    Rows = info.Rows;
    Columns = info.Columns;
    
    nx = info.AcquisitionMatrix(1);
    ny = info.AcquisitionMatrix(4);
    nz = 45; % << should be somewhere in DICOM header
    
    nzMB = nz/MB; %# of MB group
    TRMB = TR/nzMB; %TR per each MB group
    
    % Slice indexing 
    if bintlv==true %interleave
        intlv = [1:2:nzMB 2:2:nzMB];
    else %linear
        intlv = [1:nzMB];
    end
    
    % MB slice indexing 
    TRslc = [];
    islice = [];
    for slcoff=1:nzMB % MB group
        islice = [islice intlv(slcoff):nzMB:nz]; % MB slices per MB group w/ offset (interleaved) slice
        TRslc = [TRslc ones(1,MB)*TRMB*slcoff];
    end
        
    nMosaixx = Rows/nx;
    nMosaixy = Columns/ny;
    
    StudyTime = str2num(info.StudyTime); %: '160316.698000'
    SeriesTime = str2num(info.SeriesTime); %: '161544.370000'
    AcquisitionTime = [AcquisitionTime str2num(info.AcquisitionTime)]; %: '161521.285000'
    ContentTime = str2num(info.ContentTime); %: '161544.385000'

    %
    data = dicomread(info);
    figure(1); imagesc(data); axis image; axis tight;
    
    islice;
    TRslc;
    [sortedislice, I] = sort(islice);
    sortedTRslc = TRslc(I);
    
    figure(2); subplot(4,1,1); plot(islice,'r-+'); axis tight; ylabel('Slice index'); xlabel('Acquisition index');
    figure(2); subplot(4,1,2); plot(TRslc,'b-+'); axis tight; ylabel('TRslice index'); xlabel('Acquisition index');
    figure(2); subplot(4,1,3); plot(islice,TRslc,'r-o'); axis tight; ylabel('TRslice index'); xlabel('Slice index');
    figure(2); subplot(4,1,4); plot(sortedislice,sortedTRslc,'r-o'); axis tight; ylabel('TRslice index'); xlabel('Sorted slice index');
end

% checking TR 600ms per volume
%TRs = diff(AcquisitionTime)*1e+3; %msec
%disp(TRs)