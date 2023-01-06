function [idx] = chen(database, record)
    % Chen detector

    fileName = database + "/" + record + "m.mat";
    load(fileName);
    entireSig = val;  % val comes from load(...)

    % Take the signal from the first channel
    sig = entireSig(1, :);
    
    % Or take the average of signals from all channels
%     numLeads = size(entireSig, 1);
%     sigLen = size(entireSig, 2);
%     avgSig = zeros(1, sigLen);
%     for i=1:numLeads
%         avgSig = avgSig + entireSig(i, :);
%     end
%     sig = avgSig / numLeads;
%     clear avgSig;

    if (database == "mitdb")
        Fs = 360;
    else
        Fs = 250;
    end
    threshold = 0.6 * max(sig(1:5*Fs));  % 60% of max value from first 5 seconds of the recording

    % we check 130 samples at a given time. while the QRS is of width only 
    % maybe let's say 200ms, i.e. 0.2*Fs = 72 or 50 samples, we check for
    % it in a bigger window, so we can potentially avoid detection of 2 
    % QRS' when there is only one.
    %
    % Note after being graded by professor: this is not the best approach, i.e.
    % we shouldn't look at 130 samples, because of different sampling frequencies.
    % We should look inside a window that depends on sampling frequency (iirc).
    % This is probably the reason why we get poor Se for LTST.
    %
    WINDOW_SIZE = 130;
    M = 5;
    GAMMA = 0.15;
    ALPHA = (0.1 + 0.01) / 2;  % median value


    % === Preprocessing ===
    filtSig = chenFiltering(sig, M, Fs);
%     filtSig = moraesFiltering(entireSig);
    

    % === Decision making ===
    i = 1;
    idx = [];
    while i < length(filtSig) - WINDOW_SIZE
        currWindow = filtSig(i:i+WINDOW_SIZE);
        [peak, peakIdx] = max(currWindow);
        peakIdx = i + peakIdx;

        % Original
%         if peak > threshold
%             idx = [idx peakIdx];
%             threshold = ALPHA * GAMMA * peak + (1 - ALPHA) * threshold;
%         end

        % If this is a QRS complex, it shouldn't be too close, i.e. it
        % should be 200ms away - idea taken from Pan and Tompkins
        if peak > threshold
            if(isempty(idx) || (~isempty(idx) && peakIdx - idx(end) >= 0.2*Fs))
                idx = [idx peakIdx];
                threshold = ALPHA * GAMMA * peak + (1 - ALPHA) * threshold;
            end
        end

        i = i + WINDOW_SIZE + 1;
    end
end


function [filtSig] = chenFiltering(sig, M, Fs)
    % Filter the signal using method described in Chen's paper

    % === Linear high pass filtering ===

    % 1. Construct y1 by filtering the signal with an M-point moving 
    % average filter, with M = 5, or 7
    b1 = 1/M * ones(1, M);
    y1 = filter(b1, 1, sig);

    % 2. Construct y2 by delaying the original signal by (M+1)/2
    delay = (M+1) / 2;
    y2 = [zeros(1, delay) sig(1:end-delay)];

    % 3. Subtract y1 from y2 to get the signal to be further processed
    filtSig = y2 - y1;


    % === Nonlinear low pass filtering ===

    % 1. Square point-by-point
    filtSig = filtSig.^2;

    % 2. Perform moving window summation on the current signal, with a
    % window size of 150ms
    filtSig = movsum(filtSig, 0.15*Fs);
end




% Attempt at using Moraes' filtering procedure, but to no avail
function [filtSig] = moraesFiltering(entireSig)
    % Filter the signal using slightly modified method described in Moraes'
    % paper

    numLeads = size(entireSig, 1); % number of leads/channels; TODO modify so the channels aren't hard coded
    sigLen = size(entireSig, 2); % signal length

    % === Filter definitions ===

    a = 1;  % all filters are FIR filters, so all ak = 0
    b1 = [1/4 1/2 1/4];  % coefficients of low pass filter
    b2 = [1 -2*cos((60*pi) / 125) 1];  % coefficients of notch filter
    b3 = [1 0 0 0 0 0 -1];  % coefficients of derivative filter

    
    % === Filter cascades ===

    % Filter signals from all channels separately, then add their abs
    % values
    sigSum = zeros(1, sigLen);
    for i=1:numLeads
        fsig1 = filter(b1, a, entireSig(i, :));
        fsig2 = filter(b2, a, fsig1);
        fsig3 = filter(b3, a, fsig2);
        sigSum = sigSum + abs(fsig3);
    end

    filtSig = sigSum / numLeads; % divide by numLeads to lower the amplitudes


    % === Modification ===

    % Use M point moving average filter on point-by-point squared signal
    % i.e Moraes' "energy" filter
    M = 40;
    bm = 1/M * ones(1, M);
    filtSig = filtSig.^2;
    filtSig = filter(bm, a, filtSig);
end