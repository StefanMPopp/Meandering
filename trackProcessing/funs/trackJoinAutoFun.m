function joined = trackJoinAutoFun(clean, sThresh, tThresh)
% Checks which track fragment beginnings are w/in the threshold values of
% the ends of other track fragments. If there is exactly 1 neighbor w/in
% the thresholds, the second track assumes the ID of the first track. If
% there is a chain of fragments, all frags >1 assume the ID of frag 1.
% Inputs: data, spatial threshold (± these px around beg/end are joined),
%         temporal threshold
wBar = waitbar(0,'Auto Joining 1/4');
if iscell(clean)
    clean = cell2mat(clean);
elseif istable(clean)
    tabl = 1;
    varNames = clean.Properties.VariableNames;
    clean = table2array(clean);
end
clean = sortrows(clean, [4,3]); % Sort by t & ID
clean(:,3) = clean(:,3)./(tThresh/sThresh); % Enables time to be included in 1 ismember function w/ space

waitbar(0.25,wBar,'Auto Joining 1/4: Picking begEnd')
% Picks out 1st & last point in every track fragment (ID)
trBeg = clean([1; find(diff(clean(:,4)))+1],1:4); % Track begin points
trEnd = clean([find(diff(clean(:,4))); size(clean,1)],1:4); % Track end points

waitbar(0.5,wBar,'Auto Joining 1/4: Finding neighbors')
% Find spatiotemporal neighbors
[~,iBegInEnd] = ismembertol(trEnd(:,1:3), [trBeg(:,1:2) trBeg(:,3)],...
    sThresh,'ByRows',1,'DataScale', 1, 'OutputAllIndices',1);
for i = 1:numel(iBegInEnd) % Eliminate tracks which start before the end
    iBegInEnd{i}(iBegInEnd{i}<=i,:) = [];
end
% matchesInEnd = cellfun(@(a) a~=0, iBegInEnd, 'Un', 0); % 1 where there are matches (cell)
% iEndInBeg = find(cellfun(@(z) z(1,1), matchesInEnd)); % Indexes of Ends which have Beg neighbors

waitbar(0.75,wBar,'Auto Joining 1/4: Dropping ambiguous')
% Delete where there are >1 Ends to a Beg
iBegInEndList = cell2mat(iBegInEnd);
[~, dup] = unique(iBegInEndList(:,1));
dupI = setdiff(1:size(iBegInEndList, 1), dup)';
dupInds = iBegInEndList(dupI);
dupInds = dupInds(dupInds>0);
for t = 1:size(iBegInEnd,1)
    iBegInEnd{t,1}(ismember(iBegInEnd{t,1},dupInds),1) = 0;
    waitbar(t/size(iBegInEnd,1),wBar,['Auto Joining 2/4: Id''ing ambiguous in ' num2str(numel(iBegInEnd)) ' pts.'])
end
waitbar(0.3,wBar,'Auto Joining 3/4: Dropping ambiguous')
% Delete where there are >1 Begs to an End
begPerEnd = cellfun(@(a) size(a,1), iBegInEnd);
iBegInEnd(begPerEnd > 1,1) = {0};

waitbar(0.5,wBar,'Auto Joining 3/4: Making dict')
% Make dictionary of Beg on left & corresponding End on right
dict = zeros(1,2); % Seed for adding list
for tr = 1:size(iBegInEnd,1)
    dictCurr = cell2mat(iBegInEnd(tr,1));
    dictCurr(dictCurr==0,:) = [];
    if ~isempty(dictCurr)
        dict = [dict; dictCurr, repmat(tr, size(dictCurr))];
    end
end
dict(1,:) = []; % Deletes seed from above

waitbar(1,wBar,'Auto Joining 3/4: Making dict')
% Assign all later IDs to the first ID (chaining IDs together)
for i = 1:size(dict,1)
    for j = 1:size(dict,1)
        if dict(i,1) == dict(j,2)
            dict(i,1) = dict(j,1);
        end
    end
end

waitbar(0,wBar,'Auto Joining 3/4: Assigning')
% Assign IDs from dict to tracks in joined (vectorize if possible!)
joinedC = trackByIDFun(clean);
IDs = unique(clean(:,4));
for d = 1:size(dict,1)
    idxChange = IDs == trEnd(dict(d,2),4);
    joinedC{idxChange,1}(:,4) = trBeg(dict(d,1),4);
    waitbar(d/size(dict,1),wBar,'Auto Joining 3/4: Assigning')
end
waitbar(1,wBar,'cell2mat 4/4')
joined = cell2mat(joinedC);
joined(:,3) = joined(:,3).*(tThresh/sThresh); % Reverts action from above
if istable(clean)
    joined = array2table(joined,'variableNames',varNames);
end
close(wBar)

if exist('tabl','var')
    joined = array2table(joined,'variablenames',varNames);
end
disp([num2str(length(dict)) ' joined'])