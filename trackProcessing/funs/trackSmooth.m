function smoothedC = trackSmooth(smoothIn, params)
% Does the LOWESS smoothing on every track ['smooth' function is slow]

% Averages very slow & jagged movements (= wobble when ant is still)
% Does neighbor averaging of all points of the slow episode 100 times
% Input: cell of track fragments w/o gaps, LOWESS window size
% Then does the smoothing over all points
% Output: cell of smoothed track(fragment)s
windowSize = params.smoothWindowSize;

if ~iscell(smoothIn)
    if any(isnan(smoothIn(:,1)))
        error('Input must be cell of track(fragment)s without NaNs')
    else
        smoothIn = trackByIDFun(smoothIn);
    end
end
if istable(smoothIn{1,1})
    tab = 1;
    varNames = smoothIn{1,1}.Properties.VariableNames;
    smoothIn = cellfun(@(n) table2array(n), smoothIn, 'un',0);
else
    tab = 0;
end

smoothedC = cell(size(smoothIn)); % Preallocation
wBar = waitbar(0,['Smoothing track 1/' num2str(size(smoothIn,1))]);
for tr = 1:size(smoothIn,1)
    waitbar(tr/size(smoothIn,1),wBar,['Smoothing track ' num2str(tr) '/' num2str(size(smoothIn,1))]);
    track = smoothIn{tr,1}(:,1:4);
    if size(track,1)>windowSize % lowess doesn't work on smaller frags
        % LOWESS smoothing over track fragment
        smX = smooth(track(:,3), track(:,1), windowSize, 'loess'); % x vs t
        smY = smooth(track(:,3), track(:,2), windowSize, 'loess'); % y vs t
        smoothedC{tr,1} = [smX smY track(:,3:4)];

    elseif size(track,1)>1 % moving average w/o preset window
        smX = smooth(track(:,3), track(:,1)); % x vs t
        smY = smooth(track(:,3), track(:,2)); % y vs t
        smoothedC{tr,1} = [smX smY track(:,3:4)];
    else % single point (would lead to outlier if 'smoothed')
        smoothedC{tr,1} = track(:,1:4);
    end
end
if tab == 1
    smoothedC = cellfun(@(n) array2table(n,'variablenames',{'x','y','t','id'}), smoothedC, 'un',0);
end
close(wBar)
    