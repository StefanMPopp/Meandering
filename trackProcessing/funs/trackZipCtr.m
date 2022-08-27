function zipped = trackZipCtr(joined, cursor_info, params)
% Zips the tracks running diagonally across the center (from x to y & vv)
% plot in here & automatically get cursor_info?

if mod(size(cursor_info,2),2)==1; error('Uneven #of tracks. Only click in pairs!'); end

joined = sortrows(joined,[4 3]);

% Getting track ids from cursor infos
ids = zeros(size(cursor_info,2),1);
for i = 1:size(cursor_info,2)
    indX = find(joined(:,1) == cursor_info(i).Position(1,1));
    indY = find(joined(:,2) == cursor_info(i).Position(1,2));
    indZ = find(joined(:,3) == cursor_info(i).Position(1,3));
    ind = intersect(intersect(indX,indY),indZ);
    ids(i,1) = joined(ind,4);
end

% Dictionary cell of begs & ends
dict = cell(size(ids,1),2);
for i = 1:2:size(ids,1)
    dict{i,1} = joined(joined(:,4)==ids(i),:);
    dict{i,2} = joined(joined(:,4)==ids(i+1),:);
    if dict{i,1}(1,3) < dict{i,2}(1,3) % makes col 1 all begs
        dict(i,:) = dict(i,[2 1]);
    end
end
dict(cellfun('isempty',dict(:,1)),:) = [];

% Keeping from begPt to endPt ± 1 pt => only overlapping
for i = 1:size(dict,1)
    aWhole = dict{i,1};
    bWhole = dict{i,2};
    dictTmatch{i,1} = aWhole(1:find(aWhole(:,3)>bWhole(end,3),1),:);
    dictTmatch{i,2} = bWhole(  find(bWhole(:,3)<aWhole(1,3),1,'last'):end,:);
end

% Interpolating missing points
params.threshUnseen = 1000; % interpol any gaps w/in the overlap
aInterPre = trackInterpolate(dictTmatch(:,1),params,'quiet');
bInterPre = trackInterpolate(dictTmatch(:,2),params,'quiet');

for i = 1:length(aInterPre) % Doing it again to cut interpolations at start/end of overlaps
    % Keeping from begPt to endPt ± 1 pt => only overlapping
    [~,aInterIdx,bInterIdx] = intersect(aInterPre{i,1}(:,3),bInterPre{i,1}(:,3));
    aInter{i,1} = aInterPre{i,1}(aInterIdx,:);
    bInter{i,1} = bInterPre{i,1}(bInterIdx,:);
end

dictInter = [aInter bInter];

% We need to sort again to avoid weird scattering of some tracks
dictBlend = cellfun(@(n) sortrows(n,3), dictInter, 'un',0);

% Blending: 'bending' beg tracks towards end neighbors
dictBent = dictBlend(:,1);
for i = 1:size(dictBlend,1)
    dt = dictBlend{i,1}(end,3) - dictBlend{i,1}(1,3); % length of track in fr
    rt = 1-(dictBlend{i,1}(:,3) - dictBlend{i,1}(1,3))./dt; % Relative time: fraction of how close to beg
    dxy = dictBlend{i,2}(:,1:2) - dictBlend{i,1}(:,1:2); % x&y dists between points
    dictBent{i,1}(:,1:2) = dictBlend{i,1}(:,1:2) + rt.*dxy; % Replaces original w/ blended points
end

% Replace corresponding track parts in joined
dictBlendMat = cell2mat(dictBlend);
dictBentMat = cell2mat(dictBent);
joined(ismember(joined(:,1:3),[dictBlendMat(:,1:3); dictBlendMat(:,5:7)],'rows'),:) = [];
dictBentMat(:,4) = dictBlendMat(:,8); % Assigning 'b' IDs to bent
for i = 1:size(dictBlend,1) % Assigning IDs of 'b' tracks to 'a' tracks
    joined(joined(:,4)==dictBlend{i,1}(1,4),4) = dictBlend{i,2}(1,4);
end
% Add bent track part to joined
if size(joined,2) > 4
    joined = [joined; dictBentMat(:,1:4) repmat(5,size(dictBentMat,1),1)]; % 5 in col5 bc. not one cam anymore
else
    joined = [joined; dictBentMat(:,1:4)]; % Joined doesn't have the cam info
end
zipped = sortrows(joined, [4,3]);
