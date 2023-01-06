%{ 
=============================
=== Moraes detector notes ===
=============================

- During testing they left out 4 records from MITBIH (108, 200, 201, 203)
- They altered the records "to fit the signal characteristics of the ECG
monitor in which the detector would be applied" - main thing they did was
change the sampling frequency from 360Hz to 250Hz. For LTSTDB records, this
is irrelevant, for MITBIHDB it might be a good idea to try with/without
resampling. We can use the MATLAB function "resamp", or WFDB program
"xform" (look at first vaje for this).

- Detector has two stages:
    signal conditioner stage (filtering) and 
    two detector stages (main and secondary)
- x1(n) and x2(n) - the sampled signals from the two channels


=== Signal conditioner (filtering) stage ===

Step 1. Apply three filters on both channels
Step 2. Take absolute value of both channels
Step 3. Add both channels together

1st filter is a low pass filter: y(n) = 1/4x(n) + 1/2x(n-1) + 1/4x(n-2)
2nd filter is a notch filter: y(n) = x(n) - 2cos(60*pi/125)x(n-1) + x(n-2)
3rd filter is a derivative filter: y(n) = x(n) - x(n-6)


=== Detector stages ===

QRS complex width is stated to be 180ms (for 250Hz sampling frequency, i.e.
250 smp/s, 180ms equates to 0.18s * 250smp/s = 45 samples)

1. Main detector
    - Two types of thresholds: BT (baseline) and DT (decision). BT is
    mostly there to help update DT, which is actually used for comparisons.
    - Crossing means crossing ABOVE the threshold, not crossing above OR 
    below.
    
    - We start event analysis after DT is crossed. After that initial
    crossing, we count how many new crossings there have been. We stop if
    180ms has passed without any new crossings, or if we count > 4.
    - If there are > 4 crossings, the event is noise, and update BT and DT
    according to equations (4) and (5)
    - If there are 2 to 4 crossings, the event is a QRS complex, update BT
    and DT based on (8) and (9)
    - If there is only 1 (meaning we just cross over DT and don't dip back
    down), then we go to the secondary detector.
    - If there were no additional crossings, we do nothing, and we update
    BT and DT based on (6) and (7).

    - The article (unfortunately) doesn't state what to initialize BT and
    DT with, but an idea might be 30/40/50% of the max value from the
    first 5 seconds of the recording, or maybe the first second of the
    recording, or something like that.

    - DT and BT update formulas are given in the paper. Maximum and minimum
    values for BT and DT are 1200 and 100 respectively.

2. Secondary detector
    - As stated, used when there is only one crossing of DT (in a window of
    180ms or 45 samples, for 250Hz samp. freq.)

    - First step is to filter the signal used by the main detector one more
    time, with the following filter:
    y(n) = 1/20 * sum{i=0 to 19} x^2(n-i)
    The obtained signal is what they call the "energy signal".

    - The energy signal is compared to the energy threshold (ET) to
    evaluate what this part is considered as. An event for the secondary
    detector is considered to be crossing ABOVE ET, and then crossing BELOW
    ET. Quote:
    "When there is a crossing at the detection threshold (ET) an event is 
    considered to have happened only after the (secondary) detector returns
    to a level below the threshold."
    

    - At each detected event, we calculate the width/size of the RR
    interval (I assume taking the maximum of the amplitude present in the
    event to be the right R), the width and amplitude of the event.

    - If the size of the RR interval is larger than 200ms, the width of the
    event is between 16 and 500ms, and the amplitude is between 10 and 600%
    of the amplitude mean from the last 8 detected QRS complexes, then this
    is classified as a QRS complex by the secondary detector. If not, then
    we disregard it.

    - Besides the equations for updating ET, when 1 second goes by without
    the detection of one QRS complex, the amplitude mean of the last 8 QRS
    complexes must also be adjusted too. This adjustment is done with the 
    analysis of the amplitude value of the last EVENT(!). If it is higher 
    than the current mean, the mean value is increased 25%; if it is lower,
    it is reduced by 25%.

%}

function [idx] = moraes(database, record, toPlot)
    % Return the fiducial points of the signal

    fileName = database + "/" + record + "m.mat";

    % Load and initialize constants
    load(fileName);
    sig = val;
    numLeads = size(sig, 1); % number of leads/channels
    sigLen = size(sig, 2); % signal length
    if (database == "mitbihdb")
        Fs = 360;
    else
        Fs = 250;  % ltstdb
    end
    BT = 0.75 * max(sig(1, 1:5*Fs)); DT = BT; ET = BT; % thresholds
    idx = [];

    % Filter definitions
    a = 1;  % all filters are FIR filters, so all ak = 0
    b1 = [1/4 1/2 1/4];  % coefficients of low pass filter
    b2 = [1 -2*cos((60*pi) / 125) 1];  % coefficients of notch filter
    b3 = [1 0 0 0 0 0 -1];  % coefficients of derivative filter
    be = 1/20 * ones(1, 20);  % coefficients for the energy filter used by secondary detector


    % === SIGNAL FILTERING STAGE ===

    % Filter signals from all channels separately, then add their abs
    % values
    sigSum = zeros(1, sigLen);
    for i=1:numLeads
        fsig1 = filter(b1, a, sig(i, :));
        fsig2 = filter(b2, a, fsig1);
        fsig3 = filter(b3, a, fsig2);
        sigSum = sigSum + abs(fsig3);
    end

    sigFilt = sigSum / numLeads;
%     sigFilt = sigSum;
    sigEnergy = filter(be, a, sigFilt.^2);  % the energy signal used by the secondary detector
    clear sigSum;
%     fprintf("Signal filtered!\n");


    sigFilt = sigFilt(1:5*Fs);



    if (toPlot)
        smp = 5*Fs;
        f = figure;
        f.Position = [400 350 1100 500];
        for i=1:numLeads
            subplot(numLeads+1, 1, i);
            plot(sig(i, 1:smp));  % plot channel i signal
            title("Channel " + i + " signal");
        end

        subplot(numLeads+1, 1, numLeads+1);
        plot(sigFilt(1:smp));
        title("Filtered signal");

        f = figure;
        f.Position = [400 350 1100 500];
        plot(sigEnergy(1:smp));
        title("Energy signal");
    end

    % peaks - returns the amplitudes (y values)
    % locs - indices of the peaks (x values)
    % widths - the width of each detected peak
    % proms - prominences, I think it's unimportant
    % findpeaks(..., "MinPeakDistance", value) -> could be useful!
%     [peaks, locs, widths, proms] = findpeaks(signalFiltered);


    % === DETECTOR STAGES ===

%     [peaks, locs] = findpeaks(sigFilt);
%     [peaksEnergy, locsEnergy] = findpeaks(sigEnergy);
    
%     plot(sigFilt);
%     hold on;
%     yline(DT);
%     hold off;
    i = 1;
    fprintf("DT before loop: %f\n", DT);
%     while i < sigLen
    while i < length(sigFilt)
        if sigFilt(i) > DT
            % Start counting crossings above current DT from now, in the
            % next 180ms, i.e 0.18*Fs samples
            currWindow = sigFilt(i:(i+round(0.18*Fs)));
            [qrsPeak, qrsPeakLoc]= max(currWindow);  % supposedly

            numCrossings = 0;
            above = false;
            for j=1:length(currWindow)
                if ~above && sigFilt(i-1+j) > DT
                    numCrossings = numCrossings + 1;
                    above = true;
                elseif above && sigFilt(i-1+j) <= DT
                    above = false;
                end
            end

            if numCrossings > 4
                % noise! use (4) and (5)
                BT = 1.5 * BT;
                DT = max(BT, 0.5 * qrsPeak);  % here, max(currWindow) ~ QRS peak from paper (?)
            elseif numCrossings >= 2
                % >= 2 and <= 4 -> QRS complex! use (8) and (9)
                idx = [idx i+qrsPeakLoc];
                BT = 0.75 * BT + 0.25 * qrsPeak;
                DT = max(0.5 * qrsPeak, BT);
            elseif numCrossings == 1
                % secondary detector
                a = 1;
            else
                % nothing - just use (6) and (7)
                BT = 0.5 * BT;
                DT = BT;
            end

            fprintf("number of crossings: %d, DT after: %f\n", numCrossings, DT);
            DT = min(max(100, DT), 1200);  % restrict DT to be between 100 and 1200
            i = i + round(0.18*Fs) + 1;
        else
            i = i + 1;  % maybe we can move forward more! no?
        end
    end


