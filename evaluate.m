% INSTRUCTION 1: This step is only required in Windows
% In Windows, this script requires the following files from the WFDB
% precompiled binary package available at the following address:
% https://archive.physionet.org/physiotools/binaries/windows/wfdb-10.6.1b2-mingw64.zip
% Put the wfdb2mat.exe, wrann.exe, bxb.exe, sumstats.exe, and *.dll
% (i.e. libcurl-4.dll and wfdb-10.6.dll) files into the current directory.
% Also place wfdb2mat.exe and *.dll into ltstdb/ and mitdb/.


% INSTRUCTION 2:
% Download the records (only *.dat, *.hea, and *.atr files are required) from Physionet
% either for records of the LTST DB:
% https://physionet.org/static/published-projects/ltstdb/long-term-st-database-1.0.0.zip
% or for records of the MIT-BIH DB: (ignore files that start with x_):
% https://physionet.org/static/published-projects/mitdb/mit-bih-arrhythmia-database-1.0.0.zip
% You can also use ltstdb.sh and mitdb.sh scripts, available in ltstdb/ and
% mitdb/. If you are on Windows, run it with Git Bash, as it will not work 
% in Windows' CMD or Powershell.


% INSTRUCTION 3:
% For LTST DB: Uncomment the DATABASE variable, and one of the two RECORDS variables
DATABASE = "ltstdb";
RECORDS = ...
    ["s20011" "s20021" "s20031" "s20041" "s20051" "s20061" "s20071" "s20081" "s20091" "s20101" ...
     "s20111" "s20121" "s20131" "s20141" "s20151" "s20161" "s20171" "s20181" "s20191" "s20201" ...
     "s20211" "s20221" "s20231" "s20241" "s20251" "s20261" "s20271" "s20272" "s20273" "s20274" ...
     "s20281" "s20291" "s20301" "s20311" "s20321" "s20331" "s20341" "s20351" "s20361" "s20371" ...
     "s20381" "s20391" "s20401" "s20411" "s20421" "s20431" "s20441" "s20451" "s20461" "s20471" ...
     "s20481" "s20491" "s20501" "s20511" "s20521" "s20531" "s20541" "s20551" "s20561" "s20571" ...
     "s20581" "s20591" "s20601" "s20611" "s20621" "s20631" "s20641" "s20651" "s30661" "s30671" ...
     "s30681" "s30691" "s30701" "s30711" "s30721" "s30731" "s30732" "s30741" "s30742" "s30751" ...
     "s30752" "s30761" "s30771" "s30781" "s30791" "s30801"];

% First 10 records - for testing purposes
% RECORDS = ...
%     ["s20011" "s20021" "s20031" "s20041" "s20051" "s20061" "s20071" "s20081" "s20091" "s20101"];

% For MIT-BIH DB: Uncomment the DATABASE variable and the RECORDS variable
% DATABASE = "mitdb";
% RECORDS = ...
%     ["100" "101" "102" "103" "104" "105" "106" "107" "108" "109" ...
%      "111" "112" "113" "114" "115" "116" "117" "118" "119" "121" ...
%      "122" "123" "124" "200" "201" "202" "203" "205" "207" "208" ...
%      "209" "210" "212" "213" "214" "215" "217" "219" "220" "221" ...
%      "222" "223" "228" "230" "231" "232" "233" "234"];


% INSTRUCTION 4:
% Run this script to evaluate the QRS detector on all given records.

% First remove corresponding eval1.txt, eval2.txt, and results.txt files
% from the previous run(s).
eval1 = sprintf("%s-eval1.txt", DATABASE);
eval2 = sprintf("%s-eval2.txt", DATABASE);
results = sprintf("%s-results.txt", DATABASE);

if (isfile(eval1))
    delete(eval1); 
end
if (isfile(eval2)) 
    delete(eval2); 
end
if (isfile(results)) 
    delete(results); 
end


startTime = cputime();
i = 1;
for record = RECORDS
    % If the Matlab file for this record does not exist (even though it should, double check)
    if (~isfile(sprintf('%s/%sm.mat', DATABASE, record)))
        % Convert the record into Matlab format using wfdb2mat
        fprintf("Converting record %s to MATLAB format ...", record);
        system(sprintf("cd %s & wfdb2mat -r %s", DATABASE, record));
    end

    % Delete the .asc and .qrs files from the previous run, just in case the detector
    % fails to overwrite the .asc file or if wrann fails to convert it for some reason.
    df = sprintf('%s/%s.asc', DATABASE, record);
    if (isfile(df))
        delete(df); 
    end
    df = sprintf('%s/%s.qrs', DATABASE, record);
    if (isfile(df))
        delete(df);
    end

    % Detect fiducial points and obtain a .asc file with the fiducial
    % points inside.
    detector(DATABASE, record);

    % Convert the created .asc file to a WFDB compatible format using
    % wrann. Write the result 
    system(sprintf('wrann -r %s/%s -a qrs < %s/%s.asc', DATABASE, record, DATABASE, record));

    % Evaluate the detector .qrs annotation against reference .atr annotations
    % and add the resulting statistics to eval1.txt and eval2.txt files.
    % Optionally, the -f 0 option forces bxb not to skip the first 5 minutes of the
    % record, although this will report a warning that can be disregarded.
    cmd = sprintf('bxb -r %s/%s -a atr qrs -l %s %s -f 0', DATABASE, record, eval1, eval2);
    system(cmd);

    fprintf("Conversions and comparison complete for record %s (%02d/%d)\n\n", record, i, length(RECORDS));
    i = i + 1;
end

% After the run, calculate the aggregated statistics, save the results into results.txt
system(sprintf("sumstats %s %s > %s", eval1, eval2, results));

% Print the results from results.txt. Note: do not use the Gross or Average
% results in the bottom two lines, you have to manually calculate Se and +P
% according to the instructions given in General notes (regarding assignments)
% available on the web classroom.
type(results)
fprintf("\nTotal processing time: %f\n", cputime() - startTime);