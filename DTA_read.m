function DTA_read_output = DTA_read(filename,savelocation)
%--------------------------------------------------------------------------
% Function Description:
%    Reads .DTA files from Gamry potentiostats and outputs test information
%    and raw data in a standardized format for additional processing.
% NOTE: File only processes data for CV, EIS, and OCP measurements !!!
% Rebecca Frederick  2022 DEC
%--------------------------------------------------------------------------
% Inspired by Ellen Shih's MATLAB App NILEchem 
%   (University of Texas at Dallas)
%   & Yarden's github:
%    <https://github.com/gardner-lab/lab-operations/blob/master/utilities/Electrochemistry%20measurements/DTAread.m>
%--------------------------------------------------------------------------
% INPUTS:
% filename -- the absolute/full path for the .dta file you want to read.
% savelocation -- the absolute/full path for the desired save folder.
%
% OUTPUTS:
% The output is a standardized structure named "DTA_read_output".
% that contains the following information/variables:
%   filename -- name of the file read.
%   testType -- identifier for the type of eChem test performed.
%   testDate -- date of the test.
%	testTime -- time of the test.
%   notes    -- notes entered into the notes field.
%   ocpcurve -- data from the pre-test open circiut potential measurement
%               or stand-alone OCP measurement.
%   cvcurve  -- cyclic voltammetry data.
%   eis      -- electrochemical impedance spectroscopy data.
%   settings -- additional file settings information (from CV files only).
%--------------------------------------------------------------------------
% EXAMPLE INPUTS:
%   filename = 'S:\Code Repository\Deku_NeuroEng_EchemAnalysis_MATLAB\Test_Data_Files\20241204_D3_50mv_01.DTA';
%   savelocation = 'S:\Code Repository\Deku_NeuroEng_EchemAnalysis_MATLAB\Test_File_Outputs';
%   foldername = uigetdir('Pick base folder location');
%   filename = sprintf(%s%s, filename, 20230210_Au_CV_H.DTA);
%   savelocation = mkdir filename Deku_Echem_Analysis_Outputs;
% ------------------------------------------------------------------------
%{
% UPDATE LOG
%
% Update 2025-June-10 (RAF)
%  - moved file name labels from DTA_summaries function to this function.
%  - [to-do] use UI to ask for filename conventions each run.
%
% Update 2025-May-16 Rebecca Frederick
%  - cleaned up comments, created separate Update Log comment section.
%
% Update: Rebecca Frederick 2025-APR-24
%  - changed outputs and save files to use .dta file name instead of
%    generic name "DTA_read_output". Needed to allow 'looping' through
%    multiple .dta files within a folder(s).
% 
% Update: Rebecca Frederick 2024-FEB-19
%  - replaced some variable names.
%  - added code to change Gamry labels EISPOT and CORPOT to EIS and OCP
%    in output structure and data.
%  - added code to send structure DTA_read_output to workspace and save in
%    Test_File_Outputs folder.
% 
%}
% ------------------------------------------------------------------------
%                         READ .DTA FILES
% ------------------------------------------------------------------------
%Set default deliminator for input values
delim = '\t';

%Establish data output structure
DTA_read_output = struct('filename', [], 'testType', [], 'testDate', [], 'testTime', [], 'notes', [], 'ocpcurve', [], 'cvcurve', [], 'eis', [], 'settings', []);
    
%Parse out the filename string
t = regexp(filename, filesep, 'split');
DTA_read_output.filename = t{end};

% USER EDIT FILE NAME CONVENTION BELOW !!!
labels_temp = split(DTA_read_output.filename,'_');  % labels separated by underscores
labels_count = length(labels_temp);
date = labels_temp{1};  % format = YYYYMMDD
wafer = labels_temp{2};  % format = project-specific
device = labels_temp{3};  % format = project-specific
animal = labels_temp{4};  % format = project-specific
electrode = labels_temp{5};  % format = E00 or E000
test = labels_temp{6};  % format = A (i.e. A,B,...,Z,ZA,ZB,...)
if labels_count>7
    other = labels_temp{7};  % format = project-specific
    for lbl = 7:labels_count-1
        other2 = labels_temp{lbl+1};
        other = join([other,'_',other2],1);  % format = project-specific
    end
elseif labels_count==7
    other = labels_temp{7};  % format = project-specific
else
    other = ' ';
end
DTA_read_output.fileLabels = struct('date',date,'wafer',wafer,'device',device,'animal',animal,'electrode',electrode,'test',test,'other',other);

% ------------------------------------------------------------------------
%Open the file for binary read access
fid=fopen(filename,'r');

%Read out and discard the first line
fgetl(fid);

%Retrieve the test type from second column in .DTA file header
curLine=fgetl(fid);
t=regexp(curLine,delim,'split');
testtype = t{2}
%DTA_read_output.testType = t{2};
    % 'CV' = Cyclic Voltammetry
    % 'EISPOT' = Electrochemical Impedance Spectroscopy
    % 'CORPOT' = Open Circuit Potential Measurement

%Put "testtype" into structure "testType",
%replace 'EISPOT' and 'CORPOT' labels from file with 'EIS' and 'OCP'
if length(testtype)==2  %if string for test type is 2 characters (CV)
    if testtype=='CV'     %check that the characters are actually "CV"
        DTA_read_output.testType = 'CV'; %set testType as 'CV'
    else % do nothing
    end
elseif length(testtype)==6  %if string for test type is 6 characters (EISPOT and CORPOT)
    if testtype=='CORPOT'  %if the testtype is CORPOT
        DTA_read_output.testType = 'OCP';  %set testType as 'OCP'
    elseif testtype=='EISPOT'  %if the testtype is EISPOT
        DTA_read_output.testType = 'EIS';  %set testType as 'EIS'
    else % do nothing
    end
else    %if testtype is some other value (not CV, EISPOT, or CORPOT)
    DTA_read_output.testType = testtype; %pass value to testType for error
end

try %to control input filetypes before they happen
    validStrings = {'CV','EIS','OCP'}; 
    DTA_read_output.testType = validatestring(DTA_read_output.testType,validStrings);
catch ME
    %bad file type... not CV, EIS, or OCP
    DTA_read_output.testType='ERROR';
    return;
end

%Read through all lines until the end of file flag is set
testNum = 1;
while ~feof(fid)
    %Read a single line
    curLine=fgetl(fid);
    
    %Parse out the tab-delimited column tokens
    t=regexp(curLine,delim,'split');
    
    %Process the line by switching between first-colum cases
    switch t{1}
        
        %Test date
        case 'DATE'
            DTA_read_output.testDate = t{3};
            
        %Test time of day
        case 'TIME'
            DTA_read_output.testTime = t{3};
            
        %Test notes
        case 'NOTES'
            if ~strcmp(t{4}, '&Notes...')
                DTA_read_output.notes = t{4};
            else
                DTA_read_output.notes = [];
            end
            
        %The marker for the preroutine eChem data and independent OCP runs
        case 'OCPCURVE'
            %Read the data block
            [data, fid] = readBlock(fid, delim, testNum);
            %Copy the data to output structure
            DTA_read_output.ocpcurve.time = data(:,2); % Time values
            DTA_read_output.ocpcurve.Vf = data(:,3);   % Measured cell V vs. Ref
            DTA_read_output.ocpcurve.Vach = data(:,5); % V measured using the A/D input
            
        %Marker for the start of an EIS datablock
        case 'ZCURVE'
            %Read the data block
            [data, fid] = readBlock(fid, delim, testNum);
            %Copy the data to output structure
            DTA_read_output.eis.time = data(:,2);  % Time
            DTA_read_output.eis.freq = data(:,3);  % Frequency
            % Complex notation:
            DTA_read_output.eis.Zreal = data(:,4); % Z real
            DTA_read_output.eis.Zimag = data(:,5); % Z imaginary
            % Polar notation:
            DTA_read_output.eis.Zmod = data(:,7);  % Z modulus
            DTA_read_output.eis.Zph = data(:,8);   % Phase
            %The first column doesn't (by itself) contain unique 
            %identifying data... check a little further
        
        case 'FREQINIT' %starting value, max frequency 
            DTA_read_output.eis.fstart = t{3};
            
        case 'FREQFINAL' %end value, min frequncy 
            DTA_read_output.eis.ffinal = t{3};
            
        case 'PTSPERDEC' %EIS points per decade
            DTA_read_output.eis.ppd = t{3};
            
        case 'SCANRATE'  %CV scan rate
            DTA_read_output.settings.scanrate = t{3};
            
        case 'STEPSIZE'  %CV voltage step size
            DTA_read_output.settings.stepsize = t{3};
            
        otherwise
            %Slice off the first 5 characters and check the tag
            if numel(t{1})>=5
                r = t{1}(1:5);
            end
            
            if strcmp(r, 'CURVE')              
            %Run additional function to read the data block:
                [data, fid] = readBlock(fid, delim, testNum);                
                %Copy the data to output structure
                %Loses first row (vs copy from echem analyst)
                %for all curves after curve #1
                if strcmp(DTA_read_output.testType, 'CV')
                    DTA_read_output.cvcurve(testNum).time = data(:,2);
                    DTA_read_output.cvcurve(testNum).Vf = data(:,3);
                    DTA_read_output.cvcurve(testNum).Im = data(:,4);
                    % ^^^ puts each CV curve/cycle into separate row and
                    % time, Vf, Im into separate columns within
                    % DTA_read_output.cvcurve ^^^
                else 
                    DTA_read_output.ocpcurve.time = data(:,2);
                    DTA_read_output.ocpcurve.Vf = data(:,3);
                    DTA_read_output.ocpcurve.Vach = data(:,5);
                end
                %Update the testNum pointer
                testNum = testNum + 1;

            end
    end
end
%--------------------------------------------------------------------------
%
%Close the file
fclose(fid);
%
%--------------------------------------------------------------------------
%                               OUTPUT / SAVE DATA
%--------------------------------------------------------------------------
%Send DTA_read_output Structure to Workspace
%Format: assignin('base', variable_name, variable);
assignin('caller', 'DTA_read_output', DTA_read_output); 
% ^ old line, keeps variable name
% [to-do] use .dta filename for structure name
% make savename for each file:
savefilename = sprintf('%s%s','DTA_',DTA_read_output.filename(1:end-4));
savefilepath = sprintf('%s%s%s%s',savelocation,'\',savefilename,'.mat');
save(savefilepath,'DTA_read_output');
end
%}
%--------------------------------------------------------------------------
%                               readBlock Function
%--------------------------------------------------------------------------
function [data, fid] = readBlock(fid, delim, testNum)
%Read out the whole block of text
%Trash two lines
fgetl(fid);
%don't trash 1 line when on subsequent curves
if testNum==1
fgetl(fid);
end

%Flag to continue to read lines
bGo = true;
data = [];
while bGo && ~feof(fid)
    
    %Read in purported first dataline
    t2=regexp(fgetl(fid),delim,'split');
 
    %If the first column is empty, we're in a data block
    if strcmp(t2{1}, '')
        %Fix for avoiding conversion of an empty string to a number
        %Tact the current line tokens onto the end of the datablock
        if isempty(str2num(t2{end}))
            data=[data; cellfun(@str2num,t2(2:end-1), 'ErrorHandler',@errorfun,'UniformOutput', false)];
        else
            data=[data; cellfun(@str2num,t2(2:end),'ErrorHandler',@errorfun, 'UniformOutput', false)];
        end
        
    else
        %revert to last line
        %Exit the while loop
        bGo = false;
    end
end
end
%--------------------------------------------------------------------------
%                               errorfun Function
%--------------------------------------------------------------------------
function result = errorfun(S, varargin)
   warning(S.identifier, S.message);
   result = 0;
end
%--------------------------------------------------------------------------
%                                  END FILE
%--------------------------------------------------------------------------