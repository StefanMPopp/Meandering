function split = trackSplitAuto(joined,threshSplit)
% Finds where multiple points of a t have the same ID
% If those points are < threshSplit away from each other: average their x&y
% else,
%   the pt/pts farther away from the previous track pt are assigned new IDs
% If >2 pts at same t, runs iteratively over those until no sim pts are lft

if istable(joined)
    varNames = joined.Properties.VariableNames;
    joined = table2array(joined);
end

if length(unique(joined(:,3:4),'rows')) < length(joined)
    wBar = waitbar(0,'Picking simultaneous points','Name','Split Auto');
    splitIn = sortrows(joined,[4 3]);
    szs = diff([0; find(diff(splitIn(:,3))); size(splitIn,1)]); % all simult in...
    inCell = mat2cell(splitIn, szs);                            % ...same cell.
    spCell = inCell; % To be manipulated
    simIdx = szs>1; % cells where there are simultaneous points
    simSum = num2str(sum(simIdx)); % just for waitbar below
    waitbar(0,wBar,'Calculating distances','Name',['Split Auto ',simSum])
    simSimDist(simIdx,1) = cellfun(@(n) pdist(n(:,1:2))', spCell(simIdx,1),'un',0);

    % Averaging close points (large ants or blurry image)
    % idxes of avgCell where all of simSimDist<threshSplit
    waitbar(0,wBar,'Identifying close points','Name',['Split Auto ',simSum])
    avgIdx = cellfun(@(n) ~isempty(n) & all(n<threshSplit), simSimDist);
    % averaging the xy, adding t+ID (+rest)
    waitbar(0,wBar,'Averaging close points','Name',['Split Auto ',simSum])
    spCell(avgIdx,1) = cellfun(@(n) [mean(n(:,1:2)) n(1,3:end)],spCell(avgIdx,1),'un',0);

    % Splitting the rest: get distances of simult pts to previous pt, only the
    % closest stays (part of the main track), others assigned hihger ID
    splitInd = find(cellfun(@(n) size(n,1)>1,spCell));
    k = 1; % 'while' counter for individual ID assignment
    while ~isempty(splitInd)
        waitbar(0,wBar,['Split 0 of ' num2str(size(splitInd,1))],'Name','Split Auto');
        spCellSz = size(spCell,1);
        for i = 1:size(splitInd,1)
            dists = pdist([spCell{splitInd(i)-1,1}(1,1:2); spCell{splitInd(i),1}(:,1:2)]);
            [~,keepIdx] = min(dists(1:size(spCell{splitInd(i),1},1)-1)); % min of comparisons w/ prev pt
            spCell{end+1,1} = spCell{splitInd(i),1};
            spCell{end,1}(keepIdx,:) = [];
            spCell{end,1}(:,4) = max(joined(:,4)) + i+k; % Assigning higer ID
            spCell{splitInd(i),1} = spCell{splitInd(i),1}(keepIdx,:);
            waitbar(i/size(splitInd,1),wBar,['Split ' num2str(i) ' of ' num2str(size(splitInd,1))],'Name','Split Auto')
        end
        splitInd = find(cellfun(@(n) size(n,1)>1,spCell(spCellSz+1:end,1)))+spCellSz;
        k = k+1+i;
    end
    waitbar(1,wBar,'Finalizing Splitting','Name','Split Auto')
    split = cell2mat(spCell);
    close(wBar)
else
    split = sortrows(joined,[4 3]);
    disp('No simultaneous points detected')
end

if istable(joined)
    split = array2table(split,'variablenames',varNames);
end
