%function DTA_master_struct(StructuresLocation,AnalysisLocation)
%--------------------------------------------------------------------------
% Function Description:
% Created By:     Rebecca Frederick
% Date Created:   24 April 2025
% Modified By:    Rebecca Frederick (RAF)
% Date Modified:  09 July 2025
%
% FILE OPERATION:
%   [1] Opens "combinedDTA" structres ouput by "DTA_combined_struct" function.
%   [2] Requires user definition of folder locations of structures to add.
%   !!! Expects "combinedDTA" structres to be 2 subfolder levels below
%       defined StructuresLocation folder path.
%   [3] Nested loops open each combinedDTA structure and saves all levels
%       as identical levels in masterDTA structure.
%   [4] Saves masterDTA structure in user defined "AnalysisLocation".
% ------------------------------------------------------------------------
%clear all
%clc
% ------------------------------------------------------------------------
%{
% UPDATE LOG
% 
% Update 2025-07-09 RAF
%  - Added comments and descriptions throughout file.
%
% Update 2025-07-08 RAF
%  - Created "DTA_combined_struct" to replace "DTA_master_struct" in
%    "main_DTA_batch_process"... used to create data analysis within a
%    single folder (single device, single day).
%  - Changed master struct to combine existing structures into one
%    by looping through all fieldnames in all structure levels.
%    Combines data from multiple devices/days.
% 
% Update 2025-06-18 RAF
%  - Created file.
%  - Fixed scan rate field name to use rounded values.
%}
% ------------------------------------------------------------------------
%%                       DEFINE FILE LOCATIONS
% ------------------------------------------------------------------------
%   
% ^^^ 
% To run as function, add bracket in line above and uncomment line 1.
%   Ensure function inputs are defined before running.
% To run as .m file, remove bracket in line 39.
% Then remove or replace bracket as needed.

% "StrucuresLocation" is where outputs from "main_DTA_batch_process" 
%   function "DTA_combined_struct" stored the data structure "combinedDTA"
%   for each individual data folder.
% Expects folder & subfoler names in format:
%   StructuresLocation 
%   (e.g. 'S:\[00] Project Folders\Aging_PI-vs-aSiC_Pt_MEAs\RawDataFiles')
%     > Study Group Folders
%     > Device/Day Folders
%     > Raw Data .dta Files AND Folder "MATLAB_Output"
%     > (within "MATLAB_Output") Folder "Summaries_Outputs"
%     > (within "Summaries_Outputs") "combinedDTA_Struct.mat"
%         and other .mat and .csv data summaries files
StructuresLocation = 'S:\[00] Project Folders\Aging_PI-vs-aSiC_Pt_MEAs\RawDataFiles';

% "AnalysisLocation" is where the masterDTA structure will be saved.
AnalysisLocation = 'S:\[00] Project Folders\Aging_PI-vs-aSiC_Pt_MEAs\DataAnalysisFiles\MATLAB_Aging_Analysis';

% "structLocation" is where to find combinedDTA_Struct.mat files to pull
%   combinedDTA structure. DO NOT EDIT.
structLocation = '\MATLAB_Output\Summaries_Outputs\combinedDTA_Struct.mat';

%}
%
% ------------------------------------------------------------------------
%%                     IMPORT MASTER DATA STRUCTURE
% ------------------------------------------------------------------------
% 
%load(fullfile(AnalysisLocation,'masterDTA_Struct.mat'))
%
% ------------------------------------------------------------------------
%%               CREAT LIST OF ALL PATHS FOR ALL DATA
% ------------------------------------------------------------------------
% Create List of 1st Level of Subfolders (Study Groups)
%    [1] PI-aSiC device data, [2] PI-Only device data
groupfold = dir(StructuresLocation); % pulls all folders in directory StructuresLocation
for i = 3:length(groupfold)  % removes first two empty lines in list
    groupfolders{i-2} = char(string([sprintf('%s%s%s',StructuresLocation,'\',groupfold(i).name)]));
end

% Create List of 2nd Level of Subfolders (Days/Devices)
%    YYYYMMDD_WaferID_DeviceID
for j = 1:length(groupfolders)  % for each group folder in directory StructuresLocation
    dataFolds = dir(groupfolders{j});  % pull list of all folders in each group folder
    for k = 3:length(dataFolds)  % removes first two empty lines in list
        dataFolders{j,k-2} = string([sprintf('%s%s%s',groupfolders{j},'\',dataFolds(k).name)]);
    end
end

% Append List "dataFolders" from 2nd Level of Subfolders with 
%   Structure File Location:  "structLocation" defined in section above.
index = 1;
[a,b] = size(dataFolders);
for m = 1:a
    for n = 1:b
        if isempty(dataFolders{m,n}) == 1
            % skip to next entry in loop
        else
            dataList{index,1} = char(string([sprintf('%s%s',dataFolders{m,n},structLocation)]));
            index = index+1;
        end
    end
end


% ------------------------------------------------------------------------
%%       CREATE MASTER STRUCTURE FROM EACH DAY'S DATA STRUCTURE
% ------------------------------------------------------------------------

% for loop 1 = open each combinedDTA structure in each subfolder for the
%   project folder defined as "StructuresLocation".
for q = 1:length(dataList)  % q = count for items in dataList
    if exist(dataList{q})==0  % check if current location contains a combinedDTA_Struct.mat file
        warning('File does not exist: %s', dataList{q});  % warning message if no file in current folder
    else  % if file does exist in current folder...
        load(dataList{q});      % Load data structure in current dataList entry
        % Multi-Loop, through fieldnames for each structure level:
        wafer_list = fieldnames(combinedDTA);  % list all wafer IDs (should be one per combinedDTA file)
        for r = 1:length(wafer_list)  % r = count for waferIDs (lvl01) in combinedDTA
        wafer = wafer_list{r};  % pull current loop's waferID
        device_list = fieldnames(combinedDTA.(wafer)); % list all device IDs (should be one per combinedDTA file)
            for s = 1:length(device_list) % s = count for device IDs (lvl02) in combined DTA
                device = device_list{s}; % pull current loop's deviceID
                date_list = fieldnames(combinedDTA.(wafer).(device)); % list all dates (often one per combinedDTA file, can be more)
                for t = 1:length(date_list) % t = count for dates (lvl03) in combined DTA
                    date = date_list{t}; % pull current loop's date
                    electrode_list = fieldnames(combinedDTA.(wafer).(device).(date)); % list all electrode IDs
                    for u = 1:length(electrode_list) % u = count for electrode IDs
                        electrode = electrode_list{u}; % pull current loop's electrode ID
                        testType_list = fieldnames(combinedDTA.(wafer).(device).(date).(electrode)); % list all test IDs (OCP, EIS, CV)
                        for v = 1:length(testType_list) % v = count for test IDs
                            testType = testType_list{v}; % pull current loop's test ID
                            switch testType % use switch case to setup struct format depending on type of measurement (OCP, EIS, or CV)
                                case 'OCP' % if OCP, save identical levels of current combinedDTA struct to masterDTA struct
                                    masterDTA.(wafer).(device).(date).(electrode).(testType) = combinedDTA.(wafer).(device).(date).(electrode).(testType);
                                case 'EIS' % if EIS, save identical levels of current combinedDTA struct to masterDTA struct
                                    masterDTA.(wafer).(device).(date).(electrode).(testType) = combinedDTA.(wafer).(device).(date).(electrode).(testType);
                                case 'CV' % if CV, loop through additional scan rate struct level and save identical levels of current combinedDTA struct to masterDTA struct
                                    scanrate_list = fieldnames(combinedDTA.(wafer).(device).(date).(electrode).(testType)); % list all scan rates
                                    for w = 1:length(scanrate_list) % w = count for scan rates measured for current wafer/device/date/electrode
                                        scanrate = scanrate_list{w}; % pull current loop iteration's scan rate
                                        masterDTA.(wafer).(device).(date).(electrode).(testType).(scanrate) = combinedDTA.(wafer).(device).(date).(electrode).(testType).(scanrate);
                                    end  % end for w, loop through scanrate
                            end  % end of switch case
                        end  % end for v, loop through testType
                    end  % end for u, loop through electrode
                end  % end for t, loop through date
            end  % end for s, loop through device
        end  % end for r, loop through wafer
        clear combinedDTA
    end  % end for file check warning message
end  % end for q, loop through all combinedDTA files

%{
% Test loop
wafer_list = fieldnames(combinedDTA);
for r = 1:length(wafer_list)
    wafer = wafer_list{r};
    device_list = fieldnames(combinedDTA.(wafer));
        for s = 1:length(device_list)
            device = device_list{s};
            output = combinedDTA.(wafer).(device).d20250707.E01.OCP;
        end
end
%}

% Save new masterDTA structure:
save(fullfile(AnalysisLocation,'masterDTA_Struct.mat'),'masterDTA');

% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------