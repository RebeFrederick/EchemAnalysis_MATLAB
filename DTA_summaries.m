function DTA_summaries(savelocation,summarieslocation)
%--------------------------------------------------------------------------
% Function Description:
% Created By:     Rebecca Frederick
% Date Created:   24 April 2025
% Modified By:    Rebecca Frederick
% Date Modified:  16 May 2025
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
% Update 2025-05-16 by Rebecca Frederick
%   - Added TestID, WaferID, & Animal ID for file naming convention:
%     YYYYMMDD_TestID_WaferID_DeviceID_ElectrodeID_AnimalID/Electrolyte_OtherInfo.DTA
%     e.g. 20250130_A_W008_F_E04_PBSair_CV50.DTA
%   - Removed commented out old/trial lines of code.
%   - Moved data labels from within switch cases to start of for loop.
%   - Changed file from .m script to function.
%   - Added creation of separate save folder for summaries within savelocation.
% 
% Update 2025-05-19 Rebecca Frederick
%   - Added Qc, Qa, Qh, & CV slope to summaries outupt for CV data.
% 
% Update 2025-05-27 Rebecca Frederick
%  - Changed file name convention to better accomodate multiplexing.
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
%Other = [];

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

summary_OCP = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,OCP);
summary_EIS = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Frequency,ImpedanceMag);
summary_CV = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,ScanRate,CSCc,CSCa,CSCh,Qc,Qa,Qh,CVslope);
%{
summary_OCP = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Other,OCP);
summary_EIS = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Other,Frequency,ImpedanceMag);
summary_CV = table(Date,AnimalID,WaferID,DeviceID,ElectrodeID,TestID,Other,ScanRate,CSCc,CSCa,CSCh,Qc,Qa,Qh,CVslope);
%}
% ------------------------------------------------------------------------
% List All .mat Files Within Selected Folder:
nameStructs = dir(sprintf('%s%s',savelocation,'\*.mat')); % all structures in save location
% ------------------------------------------------------------------------
% Create new folder for summary files if it doesn't already exist:
%newSaveFolder = 'Summaries_Outputs';
%summarieslocation = fullfile(savelocation,newSaveFolder);
if exist('summarieslocation')~=7
    savedir = cd(savelocation);
    mkdir(newSaveFolder)
    addpath(newSaveFolder);
    cd(savedir);
else
end 

% ------------------------------------------------------------------------
% Loop through all .mat data structures in savelocation & add
%   calculated values into data table matching meas. type (CV,EIS,OCP):
% ------------------------------------------------------------------------
for k = 1:length(nameStructs) 
    testInfo = nameStructs(k).name;
    current_file = sprintf('%s%s%s',savelocation,'\',testInfo);
    load(current_file);
    testType = DTA_read_output.testType;
  % EDIT FILE NAME CONVENTION BELOW !!!
    info_temp = split(testInfo,'_');  % labels separated by underscores
    date = info_temp{2};  % format = YYYYMMDD
    wafer = info_temp{3};  % format = project-specific
    device = info_temp{4};  % format = project-specific
    animal = info_temp{5};  % format = project-specific
    electrode = info_temp{6};  % format = E00 or E000
    test = info_temp{7};  % format = A (i.e. A,B,...,Z,ZA,ZB,...)
    %other = info_temp{e:end};  % format = project-specific
  % END FILE NAME CONVENTION DEFINITIONS
    %
    switch testType
        case 'OCP'
            %
            temp_ocp = DTA_read_output.Calculated{2};
            %
            summary_OCP = [summary_OCP;{date,animal,wafer,device,electrode,test,temp_ocp}];
            %summary_OCP = [summary_OCP;{date,animal,wafer,device,electrode,test,temp_ocp}]; %adds other info from file name
            clear DTA_read_output
        case 'EIS'
            %
            if size(DTA_read_output.Calculated)>1
                temp_freq = DTA_read_output.Calculated{1,2};
                temp_z = DTA_read_output.Calculated{2,2};
                %
                summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,temp_freq,temp_z}];
                %summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,temp_freq,temp_z}]; %adds other info from file name
            else
                summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,0,0}];
                %summary_EIS = [summary_EIS;{date,animal,wafer,device,electrode,test,0,0}]; %adds other info from file name
            end
            clear DTA_read_output
        case 'CV'
            %
            temp_scanrate = DTA_read_output.settings.scanrate;
            if size(DTA_read_output.Calculated)>1
                temp_CSCc = DTA_read_output.Calculated{1,2};
                temp_CSCa = DTA_read_output.Calculated{2,2};
                temp_CSCh = DTA_read_output.Calculated{3,2};
                temp_Qc = DTA_read_output.Calculated{4,2};
                temp_Qa = DTA_read_output.Calculated{5,2};
                temp_Qh = DTA_read_output.Calculated{6,2};
                temp_slope = DTA_read_output.Calculated{7,2};
                %
                summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,temp_scanrate,temp_CSCc,temp_CSCa,temp_CSCh,temp_Qc,temp_Qa,temp_Qh,temp_slope}];
                %summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,temp_scanrate,temp_CSCc,temp_CSCa,temp_CSCh,temp_Qc,temp_Qa,temp_Qh,temp_slope}]; %adds other info from file name
            else
                summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,temp_scanrate,0,0,0,0,0,0,0}];
                %summary_CV = [summary_CV;{date,animal,wafer,device,electrode,test,temp_scanrate,0,0,0,0,0,0,0}]; %adds other info from file name
            end
            clear DTA_read_output
        otherwise
            % if no test type identified, error, skip
            clear DTA_read_output
    end
end

% Save summary information in separate folder 
%   within user-selected savelocation:
save(fullfile(summarieslocation,'summary_EIS.mat'),'summary_EIS')
writetable(summary_EIS,fullfile(summarieslocation,'summary_EIS.csv'));
save(fullfile(summarieslocation,'summary_CV.mat'),'summary_CV');
writetable(summary_CV,fullfile(summarieslocation,'summary_CV.csv'));
save(fullfile(summarieslocation,'summary_OCP.mat'),'summary_OCP');
writetable(summary_OCP,fullfile(summarieslocation,'summary_OCP.csv'));

%
% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------