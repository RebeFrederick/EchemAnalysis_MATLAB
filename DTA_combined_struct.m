function DTA_combined_struct(savelocation,summarieslocation)
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
% Update 2025-06-18
%  - Created file.
%  - Fixed scan rate field name to use rounded values.
%}
% ------------------------------------------------------------------------
%                       IMPORT ALL DATA FILE NAMES
% ------------------------------------------------------------------------
% Create Empty Data Tables to Add Data To
%
%
% ------------------------------------------------------------------------
% List All .mat Files Within Selected Folder:
nameStructs = dir(sprintf('%s%s',savelocation,'\*.mat')); % all structures in save location
% ------------------------------------------------------------------------
%
% ------------------------------------------------------------------------
%                          ...IN PROGRESS...
% ------------------------------------------------------------------------
% Loop through all .mat data structures in savelocation & create
%   master structure:
% ------------------------------------------------------------------------
for k = 1:length(nameStructs) 
    testInfo = nameStructs(k).name;
    current_file = sprintf('%s%s%s',savelocation,'\',testInfo);
    load(current_file);
    testType = DTA_read_output.testType;
    date = sprintf('%s%s','d',DTA_read_output.fileLabels.date);  % format = YYYYMMDD
    wafer = DTA_read_output.fileLabels.wafer;  % format = project-specific
    device = DTA_read_output.fileLabels.device;  % format = project-specific
    animal = DTA_read_output.fileLabels.animal;  % format = project-specific
    electrode = DTA_read_output.fileLabels.electrode;  % format = E00 or E000
    test = DTA_read_output.fileLabels.test;  % format = A (i.e. A,B,...,Z,ZA,ZB,...)
    %other = DTA_read_output.fileLabels.other;  % format = project-specific
    %
    calcdata = {DTA_read_output.Calculated};
    %
    switch testType
        case 'OCP'
            rawdata = DTA_read_output.ocpcurve;
            combinedDTA.(wafer).(device).(date).(electrode).(testType) = struct('testID',test,'rawdata',rawdata,'calcdata',calcdata);
%            combinedDTA.(wafer).(device).(animal).(date).(electrode).(testType) = struct('testID',test,'rawdata',rawdata,'calcdata',calcdata);
        case 'EIS'
            rawdata = DTA_read_output.eis;
            combinedDTA.(wafer).(device).(date).(electrode).(testType) = struct('testID',test,'rawdata',rawdata,'calcdata',calcdata);
%            combinedDTA.(wafer).(device).(animal).(date).(electrode).(testType) = struct('testID',test,'rawdata',rawdata,'calcdata',calcdata);
        case 'CV'
            scanrate = sprintf('%s%d','sr',round(str2num(DTA_read_output.settings.scanrate)));
            rawdata = DTA_read_output.cvcurve(end-1);  % pulls only 2nd to last curve
            combinedDTA.(wafer).(device).(date).(electrode).(testType).(scanrate) = struct('testID',test,'rawdata',rawdata,'calcdata',calcdata);
%            combinedDTA.(wafer).(device).(animal).(date).(electrode).(testType).(scanrate) = struct('testID',test,'rawdata',rawdata,'calcdata',calcdata);
    end
    %
    clear DTA_read_output
end
%
% Save new masterDTA structure:
save(fullfile(summarieslocation,'combinedDTA_Struct.mat'),'combinedDTA');
%
%
% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------