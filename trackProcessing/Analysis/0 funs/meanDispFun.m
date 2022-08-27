function meanDispOut = meanDispFun(nsdIn)
% Calculates relative net squared displacement: sum of (displacements)^2
% from start at all points, divided by the length of the track [m] ->
% mm2/1000mm

% Input: must be table w/ id & disp (from start of track)
% Output: table of [id msd]

ids = unique(nsdIn.id);
meanDispOutM = zeros(length(ids),2);
for id = 1:length(ids)
    curr = nsdIn(nsdIn.id==ids(id),:);
    meanDispOutM(id,:) = [ids(id) sum(curr.disp)];
end
meanDispOut = array2table(meanDispOutM, 'variablenames',{'id' 'mDisp'});