# EchemAnalysis_MATLAB
Code base for processing and analysis of electrochemical measurement data using MATLAB. <br/>
For use with Gamry potentiostats and Gamry Framework software (.dta file types). <br/>
Last Updated: &nbsp; 2025-MAY-14 by Rebecca Frederick

**********************************************************************************************************
**********************************************************************************************************
## FILE DESCRIPTIONS

### Main File: "_main_DTA_batch_process.m"
- Reads all Gamry .dta files within a folder. 
- Runs "DTA_read" function to create & save an organized MATLAB data structure for each .dta file. 
- Runs "DTA_calc" function to append the structure with calculated values depending on measurement type. 
- Runs "DTA_summaries" function to add .csv and .mat files with all |Z|, CSC, and OCP values labeled with date, test ID, wafer ID, device ID, electrode ID, and animal ID. 

### Functions & Run Order:
1. DTA_read.m [Output File Format](#individual-file-mat-structures-raw-data--calculated-values)
2. DTA_calc.m [Output File Format](#structure-level-added-by-dta_calcm-function)
3. DTA_summaries.m [Output File Format](#summary-csv-files)
4. DTA_plots.m (*In Progress*) [Output File Format](#plots)

**********************************************************************************************************
**********************************************************************************************************
## USER INSTRUCTIONS

1. Open "Deku_NeuroEng_EchemAnalysis_MATLAB" Folder in your MATLAB Directory. <br/>
~ ~ OR ~ ~ <br/>
Open MATLAB to your default directory. <br/>
Add the "EchemAnalysis_MATLAB" Folder and Subfolders to your MATLAB directory.
2. Open the main data analysis file "DTA_batch_process.m"
3. **Run _main_DTA_batch_process.m**
4. At the first prompt, **select the folder that contains your .dta raw data files**.
   If your files are in subfolders, the analysis will not run on any files in
   those subfolders, it will only run on files in the main folder you selected.
5. At the second prompt, **select the folder where you want to save all output files**.
   Recommended: Create a folder within your raw data folder named "MainFolder_Analysis".
6. Wait for MATLAB to finish processing your files.
7. At the third prompt, **enter your desired values for calculations**:
   - Frequency (in Hz) for pulling impedance magnitude data. <br/>
     Default is 1 kHz.
   - Electrode Geometric Surface Area (GSA, in um^2). <br/>
     Default is 2000 um^2. 
   - CV curve number (as whole integer) to use for Charge Storage Capacity calculations. <br/>
     Default is curve #3. 
   - Percentage (as whole integer) of data to use for calculating average open circuit potential (OCP) value. <br/>
     Default is last 10% of total measurement time. 
8. Wait for MATLAB to finish processing your files.
9. **Check that the output files are saved** in your selected folder and 
   contain the data, summaries, and plots (*in progress*) you selected in the user prompts.
10. **Repeat for any additional folders** of .dta files you would like to process.

**********************************************************************************************************
**********************************************************************************************************
## OUTPUT FILE DESCRIPTIONS

### Individual File (.mat) Structures (Raw Data & Calculated Values):

- The output will be .mat files with the same filenames as each of the .dta files <br/>
  in the folder(s) you selected for processing.
- Each .mat file contains a structure variable called "DTA_read_output"
- Each structure contains the same information in the same format:

| Structure Level                   | Data Type  | Description |
| :-------------------------------- | :--------  | :----------------------------------------------------- |
| DTA_read_output.filename          | character	 | name of original .dta file |
| DTA_read_output.testType	        | character	 | 'EIS' or 'CV' or 'OCP' |
| DTA_read_output.testDate	        | character	 | date from original .dta file |
| DTA_read_output.testTime	        | character	 | time from original .dta file |
| DTA_read_output.notes	            | array	     | text notes (if any) from original .dta file |
| DTA_read_output.ocpcurve <br/> cols=time,voltage	                | array	     | OCP raw data <br/> empty if .dta file is not an OCP measurement |
| DTA_read_output.cvcurve <br/> cols=time,Vf,Im; <br/> rows=curve#  | array		   | CV raw data for all curves <br/> empty if .dta file is not a CV measurement |
| DTA_read_output.eis	              |	structure	 | EIS raw data <br/> empty if .dta file is not an EIS measurement |
| &nbsp;&nbsp;...eis.fstart	        | character	 | starting frequency value for measurement |
| &nbsp;&nbsp;...eis.ffinal         | character	 | ending frequency value for measurement |
| &nbsp;&nbsp;...eis.ppd            | character	 | number of data points per decade |
| &nbsp;&nbsp;...eis.time	          | cell	 	   | time values for each data point |
| &nbsp;&nbsp;...eis.freq	          | cell		   | frequency values for each data point |
| &nbsp;&nbsp;...eis.Zreal		      | cell		   | real portion of impedance values for each data point |
| &nbsp;&nbsp;...eis.Zimag		      | cell		   | imaginary portion of impedance values for each data point |
| &nbsp;&nbsp;...eis.Zmod	        	| cell		   | impedance modulus values for each data point |
| &nbsp;&nbsp;...eis.Zph	        	| cell		   | impedance phase values for each data point |
| DTA_read_output.settings	        | array		   | stores settings from CVs needed for CSC |
| &nbsp;&nbsp;...settings.scanrate	| character	 | scan rate of CV measurement, in mV/sec. |
| &nbsp;&nbsp;...settings.stepsize	| character	 | step size for each voltage step, in mV, default is 10mV. |

### Structure Level Added by "DTA_calc.m" Function:

| Structure Level                   | Data Type  | Description |
| :-------------------------------- | :--------  | :----------------------------------------------------- |
| DTA_read_output.Calculated	      | cell array | stores values calculated by DTA_process.m |
| &nbsp;&nbsp; If OCP...			      | 1x2 cell   | {1,1} 'Avg_OCP'	&nbsp; {1,2} number in V | |
| &nbsp;&nbsp; If EIS...			      | 2x2 cell	 | {1,1} 'Freq' 	&nbsp; {1,2} number in Hz <br/> {2,1} '&#124;Z&#124;'  &nbsp; &nbsp; &nbsp; {2,2} number in ohm |
| &nbsp;&nbsp; If CV...			        | 7x2 cell	 | {1,1} 'CSCc' &nbsp; &nbsp; {1,2} number in mC/cm^2 <br/> {2,1} 'CSCa' &nbsp; &nbsp;  {2,2} number in mC/cm^2 <br/> {3,1} 'CSCh' &nbsp; &nbsp; {3,2} number in mC/cm^2 <br/> {4,1} 'Qc' &nbsp; &nbsp; &nbsp; &nbsp; {4,2} number in nC <br/> {5,1} 'Qa' &nbsp; &nbsp; &nbsp; &nbsp; {5,2} number in nC <br/> {6,1} 'Qh' &nbsp; &nbsp; &nbsp; &nbsp; {6,2} number in nC <br/> {7,1} 'CVslope' {7,2} number in A/V |

### Summary (.csv) Files:
#### CV Data Summary
Columns = Date, Test ID, Wafer ID, Device ID, Electrode ID, Animal ID, Scan Rate (mV/s), CSCc (mC/cm^2), CSCa (mC/cm^2), CSCh (mC/cm^2)
#### EIS Data Summary
Columns = Date, Test ID, Wafer ID, Device ID, Electrode ID, Animal ID, Frequency (Hz), Impedance (ohm)
#### OCP Data Summary
Columns = Date, Test ID, Wafer ID, Device ID, Electrode ID, Animal ID, OCP (V)

### Plots:
*In Progress*

**********************************************************************************************************
**********************************************************************************************************
**END OF READ ME**
**********************************************************************************************************
**********************************************************************************************************
