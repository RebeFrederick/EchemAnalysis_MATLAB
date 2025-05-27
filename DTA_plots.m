function DTA_plots(savelocation)
% ------------------------------------------------------------------------
%                           FILE INFORMATION
% ------------------------------------------------------------------------
% File Name:      DTA_summaries_plots.m
% Created By:     Rebecca Frederick
% Date Created:   16 May 2025
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
% Update 2025-05-27 by Rebecca Frederick
%   - Added comments with general structure for each code section.
%     ask user for file location(s), read test type from each file, 
%     add data into new summary tables by testType, plot data, save plots.
%}
% ------------------------------------------------------------------------
newSaveFolder = 'Summaries_Outputs';
summarieslocation = fullfile(savelocation,newSaveFolder);
%{ 
SECTION 01
select data folders:
user query 01 = how many devices do you want to analyze? (ans=1:n)
user query 02 = how many subfolders per device do you want to analyze?
                device 01? (ans=1:m_01)
    ...         device n?  (ans=1:m_n) >>> m = 1xn array
user query 03 = folder location for device01/date01 (n1, m1)
    ...         device_n/date_m

read all files within folder
    load(filename(n,m))
    DTA_read_output.testType
%}

% Create empty data tables to fill in during for loop:
ocpVals = [];
eisfVals = [];
eisZVals = [];
eisPhVals = [];
cvCathVals = [];
cvAnodVals = [];
ocpTable = table(ocpVals);
eisfTable = table(eisfVals);
eisZTable = table(eisZVals);
eisPhTable = table(eisPhVals);
cvCathTable = table(cvCathVals);
cvAnodTable = table(cvAnodVals);

% Loop through all user-selected data files:
for k = 1:length(nameStructs) 
    testInfo = nameStructs(k).name;
    current_file = sprintf('%s%s%s',savelocation,'\',testInfo);
    load(current_file);
    testType = DTA_read_output.testType;
    
switch testType
    case 'OCP'
%{
SECTION 02
if 'OCP'...
    put OCP value into table:
        rows = electrode ID
        columns = device ID
    plots01 = within one device:
        x-values = Electrode ID + Avg All Electrodes
        y-values = OCP + Avg & StdDev All Electrodes
    plots02 = accross multiple devices...
        x-values = Device ID + Avg All Devices
        y-values = OCP Avg & StdDev All Electrodes + Avg & StdDev All Devices
%}
        
    case 'EIS'
%{
SECTION 03
if 'EIS'...
    put freq., |Z|, Phase values into tables:
        rows = electrode ID
        columns = device ID
    plots01 = within one device:
        x-values = Electrode ID + Avg All Electrodes
        y-values = |Z| + Avg & StdDev All Electrodes
    plots02 = accross multiple devices...
        x-values = Device ID + Avg All Devices
        y-values = |Z| Avg & StdDev All Electrodes + Avg & StdDev All Devices
%}
        
    case 'CV'
%{
SECTION 04
if 'CV'...
    put CSCc,CSCa,CSCh values into tables:
        rows = electrode ID
        columns = device ID
    plots01 = within one device:
        x-values = Electrode ID + Avg All Electrodes
        y-values = CSCc&CSCa + Avg & StdDev All Electrodes
    plots02 = accross multiple devices...
        x-values = Device ID + Avg All Devices
        y-values = CSCc&CSCa Avg & StdDev All Electrodes + Avg & StdDev All Devices

%}
        
        
end

%{
SECTION 05
save plots options
%}



% ------------------------------------------------------------------------
%                             END OF FILE
% ------------------------------------------------------------------------