% Created By:     Rebecca Frederick
% Date Created:   24 April 2025
% Modified By:    Rebecca Frederick
% Date Modified:  16 May 2025
% ------------------------------------------------------------------------
%                           FILE INFORMATION
% ------------------------------------------------------------------------
% FILE OPERATION:
% Pulls list of all Gamry .dta files within a folder.
% Runs DTA_file_read function to
%   create & save an organized MATLAB data structure for each file.
% Runs DTA_calc function to
%   append the structure with calculated values depending on measurement
%   (EIS or CV or OCP)
% ------------------------------------------------------------------------
clear all
clc
% ------------------------------------------------------------------------
% UPDATE LOG
% 
% Update 2025-05-16 by Rebecca Frederick
%   - Changed DTA_process function name to DTA_calc
%   - Added DTA_summaries function to run after DTA_calc
%   - Created user input request for values to pass to DTA_calc function
%     freq. for |Z| values, electrode GSA, CV curve# for CSC, percent of 
%     data to average for OCP values.
% 
% ------------------------------------------------------------------------
%                       IMPORT ALL DATA FILE NAMES
% ------------------------------------------------------------------------
% List All .DTA Files Within Selected Main Folder:
% ------------------------------------------------------------------------
%savelocation = 'S:\Code Repository\Deku_NeuroEng_EchemAnalysis_MATLAB\Test_File_Outputs';
%MainFolder = 'S:\Code Repository\Deku_NeuroEng_EchemAnalysis_MATLAB\Test_Data_Files';
MainFolder = uigetdir('Pick folder location containing raw data files:');
savelocation = uigetdir('Pick desired save location for ouputs:');
%
allNames = dir(sprintf('%s%s',MainFolder,'\*.dta')); % all files in "MainFolder"
% ------------------------------------------------------------------------
% Creates array for all file locations in MainFolder
for i = 1:length(allNames)
    nameFiles(i) = string([sprintf('%s%s%s',MainFolder,'\',allNames(i).name)]);
end

% ------------------------------------------------------------------------
%                    PUT ALL DATA FILES INTO STRUCTURES
% ------------------------------------------------------------------------
% Run Function DTA_read to Create Data Structure for Each File:
for j = 1:length(nameFiles)   
    DTA_read(nameFiles(j),savelocation)
end
%
% ------------------------------------------------------------------------
%                 ADD CALCULATED VALUES INTO STRUCTURES
% ------------------------------------------------------------------------
% Pull names of all structures in save location:
nameStructs = dir(sprintf('%s%s',savelocation,'\*.mat')); 
% clear DTA_read_output from last-run loop of DTA_read function:
clear DTA_read_output
% Ask user to input values needed for |Z|, CSC, and OCP
%   calculations/summaries:
prompt = {'Frequency to Use for |Z| Summaries (in Hz)','Electrode GSA (in um^2)','CV Curve Number to Use for CSC (positive integer)','Percent of Data to Average for OCP Value (positive integer)'};
dlgtitle = 'Input Values for Calculations';
fieldsize = [1 45; 1 45; 1 45; 1 45];
definput = {'1000', '2000', '3', '10'};
uservals = inputdlg(prompt,dlgtitle,fieldsize,definput)
% Move user inputs to variables for DTA_calc function inputs:
eis_val = str2double(uservals{1});
cv_val = {str2double(uservals{2}),str2double(uservals{3}),'Time'};
ocp_val = str2double(uservals{4});
% 
% Run function DTA_calc on all .mat structures in savelocation:
for k = 1:length(nameStructs) 
    current_file = fullfile(savelocation,nameStructs(k).name);
    load(current_file);
    testType = DTA_read_output.testType; % needed for function input
    DTA_read_output.Calculated = DTA_calc(DTA_read_output,testType,eis_val,cv_val,ocp_val);
    save(current_file,'DTA_read_output');
    clear DTA_read_output
end
%
% ------------------------------------------------------------------------
%                 ADD SUMMARIES FOR |Z|, CSC, & OCP
% ------------------------------------------------------------------------
% Run function DTA_summaries on all .mat sturctures in savelocation:
DTA_summaries(savelocation);
%
% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------