function gapOut = excludeGaps(gapIn,rule)
% Handles holes (=NaNs) in the track from interpol or wall exclusion
% Inputs: wallIn: input table, must not be by ID at this point
%         rule: after1st, split, keep
% Output: Tracks, if 'split', id dict correlating each new id w/ its parent
% ToDo: convert split to table input w/o trackByID

if strcmp(rule,'after1st') % Track cut off w/ first NaN    
    ids = unique(gapIn.id);
    for tr = 1:length(ids)
        currTr = gapIn(gapIn.id == ids(tr),:);
        nanfreePart{tr,1} = currTr(1:find(isnan(currTr.x),1),:);
        if isempty(nanfreePart{tr,1}) % No gap points (= part of whole tracks output)
            nanfreePart{tr,1} = currTr;
        end
    end
    gapOut = vertcat(nanfreePart{:});
    
elseif strcmp(rule,'split') % Track split up @ NaN parts
	nanStarts = [find(~isnan(gapIn.x(1:end-1)) & isnan(gapIn.x(2:end)));...
                     size(gapIn,1)-1]+1;
	maxID = max(gapIn.id);
    for tr = 1:length(nanStarts)-1 % Changing IDs
        gapIn.id(nanStarts(tr):nanStarts(tr+1)) = gapIn.id(nanStarts(tr):nanStarts(tr+1))+maxID+tr;
    end
    gapOut = gapIn;
    gapOut(isnan(gapOut.x),:) = []; % Deleting holes
else % Keep
    gapOut = gapIn;
end
