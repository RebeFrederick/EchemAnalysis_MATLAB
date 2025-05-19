function DTA_summaries(savelocation)
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
%}
% ------------------------------------------------------------------------
%                       IMPORT ALL DATA FILE NAMES
% ------------------------------------------------------------------------
% Create Empty Data Tables to Add Data To
Date = [];
TestID = [];
WaferID = [];
DeviceID = [];
ElectrodeID = [];
AnimalID = [];

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

summary_OCP = table(Date,TestID,WaferID,DeviceID,ElectrodeID,AnimalID,OCP);
summary_EIS = table(Date,TestID,WaferID,DeviceID,ElectrodeID,AnimalID,Frequency,ImpedanceMag);
summary_CV = table(Date,TestID,WaferID,DeviceID,ElectrodeID,AnimalID,ScanRate,CSCc,CSCa,CSCh,Qc,Qa,Qh,CVslope);

% ------------------------------------------------------------------------
% List All .mat Files Within Selected Folder:
nameStructs = dir(sprintf('%s%s',savelocation,'\*.mat')); % all structures in save location
% ------------------------------------------------------------------------
% Create new folder for summary files if it doesn't already exist:
newSaveFolder = 'Summaries_Outputs';
summarieslocation = fullfile(savelocation,newSaveFolder);
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
    info_temp = split(testInfo,'_');
    date = info_temp{2};
    test = info_temp{3};
    wafer = info_temp{4};
    device = info_temp{5};
    electrode = info_temp{6};
    animal = info_temp{7};
    %
    switch testType
        case 'OCP'
            %
            temp_ocp = DTA_read_output.Calculated{2};
            %
            summary_OCP = [summary_OCP;{date,test,wafer,device,electrode,animal,temp_ocp}];
            clear DTA_read_output
        case 'EIS'
            %
            if size(DTA_read_output.Calculated)>1
                temp_freq = DTA_read_output.Calculated{1,2};
                temp_z = DTA_read_output.Calculated{2,2};
                %
                summary_EIS = [summary_EIS;{date,test,wafer,device,electrode,animal,temp_freq,temp_z}];
            else
                summary_EIS = [summary_EIS;{date,test,wafer,device,electrode,animal,0,0}];
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
                summary_CV = [summary_CV;{date,test,wafer,device,electrode,animal,temp_scanrate,temp_CSCc,temp_CSCa,temp_CSCh,temp_Qc,temp_Qa,temp_Qh,temp_slope}];
            else
                summary_CV = [summary_CV;{date,test,wafer,device,electrode,animal,temp_scanrate,0,0,0,0,0,0,0}];
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