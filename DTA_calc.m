function [DTA_process_calcvals] = DTA_calc(DTA_read_output,testType,eis_val,cv_val,ocp_val)
%--------------------------------------------------------------------------
% Function Description:
%    Standalone functions for processing CV, EIS, and OCP data.
%    Each operation is selected from a switch function.
%
%--------------------------------------------------------------------------
% All processing exists as individual cases within the main switch 
% operation; case(s) chosen based on type of measurement (CV, EIS, or OCP).
%--------------------------------------------------------------------------
% INPUTS:
%   DTA_read_output -- structure from DTA_read.m function
%   testType -- dataBlock.testType ID/value from structure
%   val -- file/measurement specific values
%
% OUTPUTS: 
%   [OCP] ocpm -- mean value from last 10% of data points in curve.
%   [EIS] closestzmod -- impedance magnitude at selected frequencies.
%   [EIS] ??? -- phase value at selected frequencies.
%   [EIS] ??? -- real freq. values from raw data closest to selected freq.
%   [CV] xcscC -- cathodic charge storage capacity.
%   [CV] Qc -- total cathodic charge.
%   [CV] xcscA -- anodic charge storage capacity.
%   [CV] Qa -- total anodic charge.
%   [CV] xcscH -- HMRI method, total charge divided by 2 divided by GSA.
%   [CV] Qh -- HMRI method, total charge.
% ------------------------------------------------------------------------
%{
% UPDATE LOG
% 
% Update: Rebecca Frederick 2024-FEB-19
%   - updated names of EISPOT to EIS and CORPOT to OCP to match DTA_read.m
%   - added in-line comments
%   - [to-do] determine format for dataBlock and val inputs !!!
%   - [to-do] make sure DTA_process_output is passed to final output
%     correctly; if looping through several .DTA files, may overwrite 
%     values on each loop.
% 
% Update: Rebecca Frederick 2025-APR-24
%   - Changed from previous app linked inputs to use 
%     outputs from DTA_read.m as inputs
%   - Changed format of outputs to append to each file in batch processing
% 
% Update 2025-05-16 by Rebecca Frederick
%   - Changed DTA_process function name to DTA_calc
%   - Added DTA_summaries function to run after DTA_calc
%   - Created separate Update Log comment section
%   - Moved variables eis_val, cv_val, ocp_val to DTA_batch_process
%     as user input request, added all to function inputs.
%   - Moved testType to DTA_batch_process, added to function inputs.
%   - [to-do] clean up comments and remove un-used lines.
% 
% Update 2025-05-19 by Rebecca Frederick
%   - Fixed CSC calculation to use user-input curve# 
%     (was using 2nd to last curve).
%   - Fixed CSC calculation units to output mC/cm^2.
%}
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Define val for each different case (EIS, CV, or OCP) [Moved 2025-05-16]
%eis_val = 1000; % 1 kHz
%cv_val = {72.25,3,'Time'}; % {1}= GSA in µm^2, {2}= Cycle no. for CSC, {3}= Integration Method ('Time'(default) or 'Area')
%ocp_val = 10; % Percent of total measurement time to avg OCP value over (@end of test)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%testType = DTA_read_output.testType; [Moved 2025-05-16]
switch testType
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
    case 'OCP'
        val = ocp_val;
        rawocp = DTA_read_output.ocpcurve.Vf;
        q = numel(rawocp); %how many ocp values
        % avg. from last 10% of ocp data points in time:
        ocpmean =  mean(cell2mat(rawocp(round((1-(val/100))*q):q))); 
        DTA_process_calcvals = {'Avg_OCP',ocpmean};
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Output |Z| and Phase from specific frequency values in EIS data:
    case 'EIS'
        val = eis_val;
        tmp = abs([DTA_read_output.eis.freq{:}]'-val);  %set temp values for freq.
        [m idx] = min(tmp); %index of closest value; 
        % NOTE: if idx @ start or end, cannot extrapolate well
        % if value is within 1.0Hz of requested frequency value:
        if m<5 || idx==1 || idx==size(tmp) %how many Hz off from target value
            closestfreq = DTA_read_output.eis.freq{idx};  %find real frequency value
            closestzmod = DTA_read_output.eis.Zmod{idx};  %in ohm
            DTA_process_calcvals = {'Frequency',closestfreq;'|Z|',closestzmod};
        % if no frequency values are within 1.0Hz of requested freq. value:
        else
            DTA_process_calcvals = {'error finding |Z|'};
        % [to-do] alternate way of calculating impedance:
        %   1. remove absolute value from tmp calculation.
        %   2. ignore all values below freq. of interest (negative values).
        %   3. use min value or first/lowest value for closest freq & zmod.
        %{
        % alternate way of calculating impedance:
        % if frequency is more than 1Hz off,
        % find value from other direction.
        % if difference is negative,
        % find smallest positive differnce.
            if DTA_read_output.eis.freq{idx}-val<0
               [m idx2] = max([DTA_read_output.eis.freq{idx-1:idx+1}]);
            else 
               [m idx2] = min([DTA_read_output.eis.freq{idx-1:idx+1}]);
            end
            idx2 = idx + idx2-2; 
            x = [DTA_read_output.eis.freq{[idx, idx2]}];
            y = [DTA_read_output.eis.Zmod{[idx, idx2]}];
        % draw a polyfit line given x and y points, in log log scale
            p=polyfit(log10(x), log10(y),1);
        % and then calculate |Z| at requested value
            closestzmod = 10^(polyval(p,log10(val)));
        %}
        end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
    % Output CSCc, CSCa, CSCh for CV data:
    case 'CV'  %% values when copied from analyst are %.4f precision, %.6f in matlab. rounding error?
        val = cv_val;
        numCurves = numel(DTA_read_output.cvcurve); %read number of curves in DTA file
        SA = val{1}; %GEOMETRIC SURFACE AREA value in µm^2 from user input
        SA = SA*(1e-8); % Convert GSA from µm^2 to cm^2
        R = str2num(DTA_read_output.settings.stepsize);  % R = Voltage Step
        SR = str2num(DTA_read_output.settings.scanrate);  % SR = CV Scan Rate
        V = []; I = [];  %setup empty arrays
        if numCurves<=2  %if only 1 or 2 curves, bad cv likely. skip
            DTA_process_calcvals = {'error in CV curves'};
        else
        % Find overall slope/tilt of CV curves
            curveselect = val{2}; %Curve number from user input
            %curveselect = numCurves-1; % uses 2nd to last curve/cycle
            %Copy user selected curve raw data:
            V(:,1) = cell2mat(DTA_read_output.cvcurve(curveselect).Vf);
            I(:,1) = cell2mat(DTA_read_output.cvcurve(curveselect).Im);
            p = polyfit(V,I,1);
            cvslope = p(1);
        % Use Selected CV Cycle Number for CSC Calculation:
            xV = cell2mat(DTA_read_output.cvcurve(curveselect).Vf); 
            xIm = cell2mat(DTA_read_output.cvcurve(curveselect).Im);
            %add a 0 to the end,brings values in line with integration Excel 
            xV(end+1)=0;
            xIm(end+1)=0;
        % Charge Storage Capacity Calculation:
          %{
          % Charge(i)=
          % ((current(i)+current(i-1))/2)*(Resolution(V)/SRate(V/s))*1000*currentcorrection
          % TotalCharge(i) = running total sum of charge
          % ChargeDensity(i) = totalcharge(i)/ area
          % Charge Density corrected with abs
          % cathodal integral values =
          % integer(((1-signofcharge(i)))/2)*corrected charge density(i)
          % CSCc= sum cathodal
          % charge C = cscc * area *1e6
          %}
          % anodal integrals = ((1+sign(charge(i))/2)*correctedchargedensity
            for x=2:length(xV)  % G,H,I,J are just labels for stage increment
                xG(x) = +((xIm(x-1)+xIm(x))/2)*(R/SR)*1000*1; % q (mC)
                xH(x) = +sum(xG(1:x)); % sum of current an all previous q
                xI(x) = xH(x)/SA; % q density, from q sum
                xJ(x) = abs(xG(x))/SA; % q density, current q only
            end
            %integrate cathodic(neg) and anodic(pos) regions of curve to get charge
            for x=2:length(xV)
                xintcat(x) = round(((1-sign(xG(x))))/2)*xJ(x); % cathodic Q
                xintan(x) = +((1+sign(xG(x)))/2)*xJ(x);        % anodic Q
            end
            % Method 1: Time Integral
            % Default method to use in all cases
            if strcmp(val{3}, 'Time')       
               % EIC METHOD, time
               xcscC = sum(xintcat);     % mC per cm^2
               xcscA = sum(xintan);      % mC per cm^2
               Qc = xcscC*SA*1e6;        % nC
               Qa = xcscA*SA*1e6;        % nC
               % HMRI METHOD, time
               xcscH = sum(xJ(1:end))/2; % mC per cm^2
               Qh = xcscH*SA*1e6;        % nC
            % Method 2: IV Curve Area Integral
            % Special use case: only sum charge between/inside oxidation and reduction curves
            elseif strcmp(val{3}, 'Area')   
                % EIC METHOD, area
                xcscC = sum(xintcat((1+length(xV)/2):length(xV)))-sum(xintcat(1:(length(xV)/2))); % mC/cm^2
                xcscA = sum(xintan(1:(length(xV)/2)))-sum(xintan((1+length(xV)/2):length(xV))); % mC/cm^2
                Qc = xcscC*SA*1e6;      % nC
                Qa = xcscA*SA*1e6;      % nC
                % HMRI METHOD, area
                xcscH= (xcxcC+xcscA)/2; % mC/cm^2
                Qh = xcscH*SA*1e6;      % nC
            end
            % send to output
            DTA_process_calcvals = {'CSCc',xcscC;'CSCa',xcscA;'CSCh',xcscH;'Qc',Qc;'Qa',Qa;'Qh',Qh;'CVslope',cvslope};
        end
    
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
    otherwise
        DTA_process_calcvals = 'error';
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
end

%% TROUBLESHOOTING 
% xV  = [[-0.8:0.01:0.6],[0.59:-0.01:-0.79]];
% xI = [[-0.5:0.01:0.9] [0.39:-0.01:-0.99]];
%
