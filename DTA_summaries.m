function DTA_summaries(savelocation,summarieslocation)
%--------------------------------------------------------------------------
% Function Description:
% Created By:     Rebecca Frederick
% Date Created:   24 April 2025
% Modified By:    Rebecca Frederick
% Date Modified:  29 May 2025
%
% FILE OPERATION:
% Summarizes CSC and |Z| and OCP values accross multiple files.
% Use to group by electrode, device, animal, electrolyte, etc.
% 
% [!!!] File Names Must Match Convention:
% YYYYMMDD_WaferID_DeviceID_AnimalID-or-Electrolyte_ElectrodeID_TestID_OtherInfo.DTA
% e.g. 20250130_W008_F_PBSair_E04_A_CV50.DTA
% ------------------------------------------------------------------------
%clear all
%clc
% ------------------------------------------------------------------------
%{
% UPDATE LOG
% 
% Update 2025-06-10
%  - Moved file name / data labels to DTA_read function 
%    to put in initial structure .mat files.
%  - Added "Other" category/column to summary tables.
%  - Added new masterDTA structure compiling info from all files in folder.
%    - [IN PROGRESS] need to fix scan rate to use rounded value.
%    - [IN PROGRESS] need to check that all fieldnames are never numbers.
%
% Update 2025-06-02 & 2025-06-03
%  - Added "if" statements to avoid errors when some data types are not
%    present in raw data or summary files (OCP, EIS, CV).
%  - Added standard deviation row to summary tables, after average row.
%
% Update 2025-05-29 Rebecca Frederick
%  - Added average value row to each summary table (for plots function).
%
% Update 2025-05-27 Rebecca Frederick
%  - Changed file name convention to better accomodate multiplexing.
% 
% Update 2025-05-19 Rebecca Frederick
%   - Added Qc, Qa, Qh, & CV slope to summaries outupt for CV data.
% 
% Update 2025-05-16 by Rebecca Frederick
%   - Added TestID, WaferID, & Animal ID for file naming convention:
%     YYYYMMDD_TestID_WaferID_DeviceID_ElectrodeID_AnimalID/Electrolyte_OtherInfo.DTA
%     e.g. 20250130_A_W008_F_E04_PBSair_CV50.DTA
%   - Removed commented out old/trial lines of code.
%   - Moved data labels from within switch cases to start of for loop.
%   - Changed file from .m script to function.
%   - Added creation of separate save folder for summaries within savelocation.
% 
%}
% ------------------------------------------------------------------------
%                       IMPORT ALL DATA FILE NAMES
% ------------------------------------------------------------------------
% Create Empty Data Tables to Add Data To
Date = [];
AnimalID = [];
WaferID = [];
DeviceID = [];
ElectrodeID = [];
TestID = [];
Other = [];

OCP = [];  % (V) ???
Frequency = [];  % (Hz)
ImpedanceMag = [];  % (Ohm)
ScanRate = [];  % (mV/s)
CSCc = [];  % (mC/cm^2)
CSCa = [];  % (mC/cm^2)
CSCh = [];  % (mC/cm^2)
Qc = []; % nC
Qa = []; % nC
Qh = []; % nC
CVslope = []; % (A/V)
%{
summary_OCP = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,OCP);
summary_EIS = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Frequency,ImpedanceMag);
summary_CV = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,ScanRate,CSCc,CSCa,CSCh,Qc,Qa,Qh,CVslope);
%}
summary_OCP = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Other,OCP);
summary_EIS = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Other,Frequency,ImpedanceMag);
summary_CV = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Other,ScanRate,CSCc,CSCa,CSCh,Qc,Qa,Qh,CVslope);
%
%
% ------------------------------------------------------------------------
% List All .mat Files Within Selected Folder:
nameStructs = dir(sprintf('%s%s',savelocation,'\*.mat')); % all structures in save location
% ------------------------------------------------------------------------
% 
% ------------------------------------------------------------------------
% Create new folder for summary files if it doesn't already exist:
%{  
% MOVED TO main_DTA_batch_process 2025-05-29
newSaveFolder = 'Summaries_Outputs';
summarieslocation = fullfile(savelocation,newSaveFolder);
if exist('summarieslocation')~=7
    savedir = cd(savelocation);
    mkdir(newSaveFolder)
    addpath(newSaveFolder);
    cd(savedir);
else
end 
%}
% ------------------------------------------------------------------------
% Loop through all .mat data structures in savelocation & add
%   calculated values into data table matching meas. type (CV,EIS,OCP):
% ------------------------------------------------------------------------
for k = 1:length(nameStructs) 
    testInfo = nameStructs(k).name;
    current_file = sprintf('%s%s%s',savelocation,'\',testInfo);
    load(current_file);
    testType = DTA_read_output.testType;
    date = DTA_read_output.fileLabels.date;  % format = YYYYMMDD
    wafer = DTA_read_output.fileLabels.wafer;  % format = project-specific
    device = DTA_read_output.fileLabels.device;  % format = project-specific
    animal = DTA_read_output.fileLabels.animal;  % format = project-specific
    electrode = DTA_read_output.fileLabels.electrode;  % format = E00 or E000
    test = DTA_read_output.fileLabels.test;  % format = A (i.e. A,B,...,Z,ZA,ZB,...)
    other = DTA_read_output.fileLabels.other;  % format = project-specific
%}
%{
    % Diana's SPL001_D3 (ZFG5) Files:
    date = info_temp{2};  % format = YYYYMMDD
    wafer = 'SPL001';  % format = project-specific
    device = info_temp{3};  % format = project-specific
    animal = 'PBSair';  % format = project-specific
    electrode = info_temp{4};  % format = E00 or E000
    test = sprintf('%s_%s',info_temp{5},info_temp{6});  % format = A (i.e. A,B,...,Z,ZA,ZB,...)
    test = test(1:end-4);
%}
%{
    % Ifra's PEDOT Files:
    animal = 'PBSair'; 
    electrode = info_temp{8};  % format = E00 or E000
    electrode = electrode(1:end-4); % remove .mat from string
    test = info_temp{6};  % format = A (i.e. A,B,...,Z,ZA,ZB,...)
%}
% END FILE NAME CONVENTION DEFINITIONS
    %
    switch testType
        case 'OCP'
            %
            temp_ocp = DTA_read_output.Calculated{2};
            %
            %summary_OCP = [summary_OCP;{date,animal,wafer,device,electrode,test,temp_ocp}];
            summary_OCP = [summary_OCP;{date,animal,wafer,device,electrode,test,other,temp_ocp}]; %adds other info from file name
            clear DTA_read_output
        case 'EIS'
            %
            if size(DTA_read_output.Calculated)>1
                temp_freq = DTA_read_output.Calculated{1,2};
                temp_z = DTA_read_output.Calculated{2,2};
                %
                %summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,temp_freq,temp_z}];
                summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,other,temp_freq,temp_z}]; %adds other info from file name
            else
                %summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,0,0}];
                summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,other,0,0}]; %adds other info from file name
            end
            clear DTA_read_output
        case 'CV'
            %
            temp_scanrate = round(str2double(DTA_read_output.settings.scanrate));
            if size(DTA_read_output.Calculated)>1
                temp_CSCc = DTA_read_output.Calculated{1,2};
                temp_CSCa = DTA_read_output.Calculated{2,2};
                temp_CSCh = DTA_read_output.Calculated{3,2};
                temp_Qc = DTA_read_output.Calculated{4,2};
                temp_Qa = DTA_read_output.Calculated{5,2};
                temp_Qh = DTA_read_output.Calculated{6,2};
                temp_slope = DTA_read_output.Calculated{7,2};
                %
                %summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,temp_scanrate,temp_CSCc,temp_CSCa,temp_CSCh,temp_Qc,temp_Qa,temp_Qh,temp_slope}];
                summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,other,temp_scanrate,temp_CSCc,temp_CSCa,temp_CSCh,temp_Qc,temp_Qa,temp_Qh,temp_slope}]; %adds other info from file name
            else
                %summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,temp_scanrate,0,0,0,0,0,0,0}];
                summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,other,temp_scanrate,0,0,0,0,0,0,0}]; %adds other info from file name
            end
            clear DTA_read_output
        otherwise
            % if no test type identified, error, skip
            clear DTA_read_output
    end
end
%
% ------------------------------------------------------------------------
% Append tables with average values into new row(s):
nelectrodeAVG = 'AVG';
nelectrodeSTD = 'STDEV';
ntest = 'None';
nother = 'None';
% ------------------------------------------------------------------------
%   OCP summary:
if isempty(summary_OCP)==1
    % skip if no OCP data/files are present in the folder
else
    temp_row_count1 = size(summary_OCP,1);
    ndate1 = summary_OCP{temp_row_count1,"Date"};
    nanimal1 = summary_OCP{temp_row_count1,"AnimalID"};
    nwafer1 = summary_OCP{temp_row_count1,"WaferID"};
    ndevice1 = summary_OCP{temp_row_count1,"DeviceID"};
    avgocp = mean(summary_OCP.OCP);
    stdocp = std(summary_OCP.OCP);
    summary_OCPavg = [summary_OCP; {ndate1,nanimal1,nwafer1,ndevice1,nelectrodeAVG,ntest,nother,avgocp}; ...
        {ndate1,nanimal1,nwafer1,ndevice1,nelectrodeSTD,ntest,nother,stdocp}];
    %
    % Convert Date Cell Data Type to Date-Time Data Type:
    summary_OCPavg.Date = datetime(summary_OCPavg.Date,'InputFormat','yyyyMMdd');
    % Change Cell Arrays to Categorical Data:
    summary_OCPavg.AnimalID = categorical(summary_OCPavg.AnimalID);
    summary_OCPavg.WaferID = categorical(summary_OCPavg.WaferID);
    summary_OCPavg.DeviceID = categorical(summary_OCPavg.DeviceID);
    summary_OCPavg.ElectrodeID = categorical(summary_OCPavg.ElectrodeID);
% ------------------------------------------------------------------------
    % Save OCP summary information in separate folder 
    %   within user-selected savelocation:
    %save(fullfile(summarieslocation,'summary_OCP.mat'),'summary_OCP');
    %writetable(summary_OCP,fullfile(summarieslocation,'summary_OCP.csv'));
    save(fullfile(summarieslocation,'summary_OCPavg.mat'),'summary_OCPavg');
    writetable(summary_OCPavg,fullfile(summarieslocation,'summary_OCPavg.csv'));
end
% ------------------------------------------------------------------------
%
%   EIS summary:
if isempty(summary_EIS)==1
    % skip if no EIS data/files are present in the folder
else
    temp_row_count2 = size(summary_EIS,1);
    ndate2 = summary_EIS{temp_row_count2,"Date"};
    nanimal2 = summary_EIS{temp_row_count2,"AnimalID"};
    nwafer2 = summary_EIS{temp_row_count2,"WaferID"};
    ndevice2 = summary_EIS{temp_row_count2,"DeviceID"};
    nfreq = summary_EIS{temp_row_count2,"Frequency"};
    avgZ = mean(summary_EIS.ImpedanceMag);
    stdZ = std(summary_EIS.ImpedanceMag);
    summary_EISavg = [summary_EIS; {ndate2,nanimal2,nwafer2,ndevice2,nelectrodeAVG,ntest,nother,nfreq,avgZ}; ...
        {ndate2,nanimal2,nwafer2,ndevice2,nelectrodeSTD,ntest,nother,nfreq,stdZ}];
    %
    % Convert Date Cell Data Type to Date-Time Data Type:
    summary_EISavg.Date = datetime(summary_EISavg.Date,'InputFormat','yyyyMMdd');
    % Change Cell Arrays to Categorical Data:
    summary_EISavg.AnimalID = categorical(summary_EISavg.AnimalID);
    summary_EISavg.WaferID = categorical(summary_EISavg.WaferID);
    summary_EISavg.DeviceID = categorical(summary_EISavg.DeviceID);
    summary_EISavg.ElectrodeID = categorical(summary_EISavg.ElectrodeID);
% ------------------------------------------------------------------------
    % Save EIS summary information in separate folder 
    %   within user-selected savelocation:
    %save(fullfile(summarieslocation,'summary_EIS.mat'),'summary_EIS')
    %writetable(summary_EIS,fullfile(summarieslocation,'summary_EIS.csv'));
    save(fullfile(summarieslocation,'summary_EISavg.mat'),'summary_EISavg')
    writetable(summary_EISavg,fullfile(summarieslocation,'summary_EISavg.csv'));
end
% ------------------------------------------------------------------------
%
% CV summary:
if isempty(summary_CV)==1
   % skip if no CV data/files are present in the folder
else
    summary_CVavg = summary_CV;
    temp_row_count3 = size(summary_CV,1);
    CV_means = groupsummary(summary_CV,"ScanRate",["mean","std"],["CSCc","CSCa","CSCh","Qc","Qa","Qh","CVslope"]);
    ndate3 = summary_CV{temp_row_count3,"Date"};
    nanimal3 = summary_CV{temp_row_count3,"AnimalID"};
    nwafer3 = summary_CV{temp_row_count3,"WaferID"};
    ndevice3 = summary_CV{temp_row_count3,"DeviceID"};
    for q=1:height(CV_means)
        nScanRate = CV_means{q,"ScanRate"};
        nCSCc = CV_means{q,"mean_CSCc"};
        nCSCa = CV_means{q,"mean_CSCa"};
        nCSCh = CV_means{q,"mean_CSCh"};
        nQc = CV_means{q,"mean_Qc"};
        nQa = CV_means{q,"mean_Qa"};
        nQh = CV_means{q,"mean_Qh"};
        nCVslope = CV_means{q,"mean_CVslope"};
        %
        nCSCcstd = CV_means{q,"std_CSCc"};
        nCSCastd = CV_means{q,"std_CSCa"};
        nCSChstd = CV_means{q,"std_CSCh"};
        nQcstd = CV_means{q,"std_Qc"};
        nQastd = CV_means{q,"std_Qa"};
        nQhstd = CV_means{q,"std_Qh"};
        nCVslopestd = CV_means{q,"std_CVslope"};
        %
        summary_CVavg = [summary_CVavg; {ndate3,nanimal3,nwafer3,ndevice3,nelectrodeAVG,ntest,nother,nScanRate,nCSCc,nCSCa,nCSCh,nQc,nQa,nQh,nCVslope}; ...
            {ndate3,nanimal3,nwafer3,ndevice3,nelectrodeSTD,ntest,nother,nScanRate,nCSCcstd,nCSCastd,nCSChstd,nQcstd,nQastd,nQhstd,nCVslopestd}];
    end
    %
    % Convert Date Cell Data Type to Date-Time Data Type:
    summary_CVavg.Date = datetime(summary_CVavg.Date,'InputFormat','yyyyMMdd');
    % Change Cell Arrays to Categorical Data:
    summary_CVavg.AnimalID = categorical(summary_CVavg.AnimalID);
    summary_CVavg.WaferID = categorical(summary_CVavg.WaferID);
    summary_CVavg.DeviceID = categorical(summary_CVavg.DeviceID);
    summary_CVavg.ElectrodeID = categorical(summary_CVavg.ElectrodeID);
    summary_CVavg.ScanRate = categorical(summary_CVavg.ScanRate);
    %}
% ------------------------------------------------------------------------
    % Save CV summary information in separate folder 
    %   within user-selected savelocation:
    %save(fullfile(summarieslocation,'summary_CV.mat'),'summary_CV');
    %writetable(summary_CV,fullfile(summarieslocation,'summary_CV.csv'));
    save(fullfile(summarieslocation,'summary_CVavg.mat'),'summary_CVavg','CV_means');
    writetable(summary_CVavg,fullfile(summarieslocation,'summary_CVavg.csv'));
end
%
%
% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------