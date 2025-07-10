% Created By:     Rebecca Frederick
% Date Created:   24 April 2025
% Modified By:    Rebecca Frederick
% Date Modified:  29 May 2025
% ------------------------------------------------------------------------
%                           FILE INFORMATION
% ------------------------------------------------------------------------
% FILE OPERATION:
% Pulls list of all Gamry .dta files within a folder.
% Runs DTA_read function to
%   create & save an organized MATLAB data structure for each file.
% Runs DTA_calc function to
%   append the structure with calculated values depending on measurement
%   (EIS or CV or OCP)
% Runs DTA_summaries function to
%   create .mat and .csv files of all files' OCP, |Z|, and CSC data.
% Runs DTA_combined_struct function to
%   place data from each individual .dta file into one combined structure
%   for that day/folder
% Runs DTA_plots function to
%   output .mat and .png figures of
%     - OCP for each electrode and avg. +/- std. dev.
%     - |Z| at selected freq. for each electrode and avg. +/- std. dev.
%     - CSC at each scan rate for each electrode and avg. +/- std. dev.
%
% ------------------------------------------------------------------------
clear all
clc
% ------------------------------------------------------------------------
%{
% UPDATE LOG
% 
% Update 2025-05-16 by Rebecca Frederick
%   - Changed DTA_process function name to DTA_calc
%   - Added DTA_summaries function to run after DTA_calc
%   - Created user input request for values to pass to DTA_calc function
%     freq. for |Z| values, electrode GSA, CV curve# for CSC, percent of 
%     data to average for OCP values.
% 
% Update 2025-05-29 by Rebecca Frederick
%   - Added section to run DTA_plots function.
%}
% ------------------------------------------------------------------------
%                       IMPORT ALL DATA FILE NAMES
% ------------------------------------------------------------------------
% List All .DTA Files Within Selected Main Folder:
% ------------------------------------------------------------------------
%savelocation = 'S:\Code Repository\Deku_NeuroEng_EchemAnalysis_MATLAB\Test_File_Outputs';
%MainFolder = 'S:\Code Repository\Deku_NeuroEng_EchemAnalysis_MATLAB\Test_Data_Files';
MainFolder = uigetdir('Pick folder location containing raw data files:');
savelocation = uigetdir('Pick desired save location for ouputs:');
% Create new folder for summary files if it doesn't already exist:
newSaveFolder = 'Summaries_Outputs';
summarieslocation = fullfile(savelocation,newSaveFolder);
%
allNames = dir(sprintf('%s%s',MainFolder,'\*.dta')); % all files in "MainFolder"
% ------------------------------------------------------------------------
% Creates array for all file locations in MainFolder
for i = 1:length(allNames)
    nameFiles(i) = string([sprintf('%s%s%s',MainFolder,'\',allNames(i).name)]);
end

% ------------------------------------------------------------------------
%%                    PUT ALL DATA FILES INTO STRUCTURES
% ------------------------------------------------------------------------
% Run Function DTA_read to Create Data Structure for Each File:
for j = 1:length(nameFiles)   
    DTA_read(nameFiles(j),savelocation)
end
%
% ------------------------------------------------------------------------
%%                ADD CALCULATED VALUES INTO STRUCTURES
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
definput = {'1000', '2000', '3', '10'}; % Hz, um^2, integer, integer
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
%%                 ADD SUMMARIES FOR |Z|, CSC, & OCP
% ------------------------------------------------------------------------
% !!! NOTE !!!
% File Names Must Match Convention:
% YYYYMMDD_WaferID_DeviceID_AnimalID-or-Electrolyte_ElectrodeID_TestID_OtherInfo.DTA
% e.g. 20250130_W008_F_PBSair_E04_A_CV50.DTA
if exist('summarieslocation')~=7
    savedir = cd(savelocation);
    mkdir(newSaveFolder)
    addpath(newSaveFolder);
    cd(savedir);
else
end
% Run function DTA_summaries on all .mat structures in savelocation:
DTA_summaries(savelocation,summarieslocation);

% ------------------------------------------------------------------------
%%                   COMBINE FILE STRUCTURES INTO ONE
% ------------------------------------------------------------------------
% Run function DTA_master_struct on all .mat structures in savelocation:
DTA_combined_struct(savelocation,summarieslocation)
%
% ------------------------------------------------------------------------
%%                    ADD PLOTS FOR OCP, |Z|, & CSC
% ------------------------------------------------------------------------
% Run function DTA_plots on summary files in savelocation:
DTA_plots(savelocation,summarieslocation,uservals);
%
% ------------------------------------------------------------------------
%%               COMBINE STRUCTURES INTO MASTER STRUCTURE
% ------------------------------------------------------------------------
% Run function DTA_master_struct on all .mat structures in savelocation:
%{    
% ^^^ Remove Bracket in Line Above and Run Section. Then Replace Bracket.
StructuresLocation = 'S:\[00] Project Folders\Aging_PI-vs-aSiC_Pt_MEAs\RawDataFiles';
AnalysisLocation = 'S:\[00] Project Folders\Aging_PI-vs-aSiC_Pt_MEAs\DataAnalysisFiles\MATLAB_Aging_Analysis';
DTA_master_struct(StructuresLocation,AnalysisLocation)
%}
%
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------