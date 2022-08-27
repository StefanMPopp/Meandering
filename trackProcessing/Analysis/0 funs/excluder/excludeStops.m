function stopsDat = excludeStops(stopsDat,rule)
% Removes stop periods above 'rule' length
% Inputs: input table with stops, min duration of stop to be counted [s]
% Output: table where x&y of slow periods have been replaced w/ NaNs

stopIdx = stopsDat.v<2; % 2 mm/s is generally a good cutoff
f = find(diff([0;stopIdx;0]==1)); % Idxes of stop <-> move changes
stopDict = table;
stopDict.startInd = f(1:2:end-1);  % Start indices
stopDict.nrOfPts = f(2:2:end)-stopDict.startInd;  % #of points in each stop period
stopDict(stopDict.nrOfPts<rule,:) = [];
for i = 1:height(stopDict)
    stopsDat{stopDict.startInd(i):stopDict.startInd(i)+stopDict.nrOfPts(i)-1,1:2} = NaN;
end
