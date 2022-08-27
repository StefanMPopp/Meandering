function wallOut = excludeWalls(wallIn,rule)
% Excludes parts of the track based on whether the ant was wall following.
% Either just the points near walls, the track part after the first
% wall-point, or whole tracks if any point was near a wall.
% points, tracks, after1st

% Inputs: wallIn: input table, must not be by ID at this point
%         rule: 'points', 'tracks', 'after1st' (see comments below)
% Output: table not by ID of all tracks w/o wall following

varNames = wallIn.Properties.VariableNames;
wallColumnNr = strcmp(varNames, 'wall');

if strcmp(rule,'no') % No exclusion
    wallOut = wallIn;
    
elseif strcmp(rule,'points') % All points near wall excluded (x turned to NaN)
    wallOut = wallIn;
    wallOut.x(wallIn.wall == 1) = NaN;
    
elseif strcmp(rule,'tracks') % Whole tracks excluded if 1 point of that close
    matC = trackByIDFun(wallin);
    wallfreeTracksIdx = logical(cell2mat(cellfun(@(n) sum(n(:,wallColumnNr))==0,matC,'un',0)));
    wallOut = array2table(cell2mat(matC(wallfreeTracksIdx,:)),'VariableNames',varNames);
    
elseif strcmp(rule,'after1st') % Part of track after 1st close point excluded
    ids = unique(wallIn.id);
    for tr = 1:length(ids)
        currTr = wallIn(wallIn.id == ids(tr),:);
        wallfreeParts{tr,1} = currTr(1:find(currTr.wall==1,1),:);
        if isempty(wallfreeParts{tr,1}) % No wall points (= part of whole tracks output)
            wallfreeParts{tr,1} = currTr;
        end
    end
    wallOut = vertcat(wallfreeParts{:});
end
