function spDat = excludeJumpSplit(spDat,rule)
% Jump splits tracks at insanely high speeds
spInd = find(spDat.v>rule);
ids = spDat.id(spInd);
maxID = max(spDat.id);
for i = 1:length(spInd)
    currTrEnd = find(spDat.id==ids(i),1,'last'); % Index of last point of track to be split
    spDat.id(spInd(i):currTrEnd) = maxID+i; % Assigns following part of track highest ID
end