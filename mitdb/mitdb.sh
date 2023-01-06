# NOTE: RUN WITH GIT BASH

# Uncomment one of the following server lines to select the server
# See the list of available mirors at:  http://physionet.mit.edu/mirrors/
SERVER=http://www.physionet.org/physiobank/database/mitdb/
# SERVER=http://lbcsi.fri.uni-lj.si/ltstdb/mitdb/
# SERVER=http://physionet.cps.unizar.es/physiobank/database/mitdb/

# The MIT-BIH Arrhythmia Database contains 48 half-hour excerpts of two-channel ambulatory ECG recordings
RECORDS="
100 101 102 103 104 105 106 107 108 109
111 112 113 114 115 116 117 118 119 121
122 123 124 200 201 202 203 205 207 208
209 210 212 213 214 215 217 219 220 221
222 223 228 230 231 232 233 234"

for r in $RECORDS
do
	if [ -e $r"m.mat" ]
	then
		echo -e $r"m.mat exists, hence all files were downloaded and converted.\n"
	else
		echo "Downloading .hea file for record $r ..."
		curl $SERVER$r".hea" -o $r".hea"
		echo -e "\n"
		
		echo "Downloading .atr file for record $r ..."
		curl $SERVER$r".atr" -o $r".atr"
		echo -e "\n"
		
		echo "Downloading .dat file for record $r ..."
		curl $SERVER$r".dat" -o $r".dat"
		echo -e "\n"
		
		echo "Converting record $r to MATLAB format ..."
		./wfdb2mat -r $r
	fi
	echo -e "--------------------------------------------------"
done
