# Chen detector

This repository contains the implementation of [Chen's QRS detector](https://ieeexplore.ieee.org/document/1291223) in MATLAB. 

The code was implemented on Windows, so note that the code from `evaluate.m` might have to be changed slightly, if you want to run on Linux. If you are on Windows, the necessary WFDB programs i.e. `wfdb2mat`, `bxb`, `sumstats` and `wrann`, alongside `libcurl-4.dll` and `wfdb-10.6.dll` have to be downloaded and placed in the following folders:
- *.dll in root, `ltstdb`, and `mitdb`
- `bxb.exe`, `sumstats.exe` and `wrann.exe` in root
- `wfdb2mat.exe` in `ltstdb` and `mitdb`.

The programs/binaries can be downloaded from [PhysioNet's archive](https://archive.physionet.org/physiotools/binaries/windows/) (download `wfdb-10.6.1b2-mingw64.zip`).


# Records

The records for LTST and MITBIH can be downloaded manually from PhysioNet, or using one of the `.sh` scripts inside `ltstdb` and `mitdb`. If you are on Windows, run them with Git Bash. On Linux, I think they should work so long as `curl` is installed.


# Repo structure

`chen.m` contains the implementation of Chen's QRS detector.

`detector.m` is a wrapper function for Chen's detector, which, after detection, writes the detected fiducial points to a .asc file.

`evaluate.m` is a script that evaluates the performance of Chen's detector on all records from either LTST or MITBIH database.

`moraes.m` contains a (failed) attempt at implementing [Moraes' QRS detector](https://ieeexplore.ieee.org/document/1166743). 

The folders with suffix `-original` contain results of original Chen's detector (taking signal from first channel, basic QRS detection - look at `chen.m` for reference).

The folders with suffix `-ch1Sig` contain results of Chen's detector, when we take the signal from first channel, and use Pan-Tompkins' idea for QRS detection. The folders with suffix `-avgSig` contains results when we take the average signal from both channel, and again use Pan-Tompkins' idea.
