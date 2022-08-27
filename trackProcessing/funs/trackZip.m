function zipped = trackZip(joined, params)
% Zips (blends) tracks which begin at a seam with those tracks representing
% the same ant in another camera (thus ending near the other seam).
% Rationale:
% 1. Pick tracks which begin/end at a seam
% 2. Match beg of one (a) cam w/ end of other (b) cam & vice versa
% 3. Throw out those that are engulfed, too short, or diverge too much
% 4. Interpolate those parts which temporally overlap w/ the matching track
% 5. Blend those parts by moving the pts from a closer to thier b tracks
%    (linear interpol), similar to train track bifucation(?)

% Inputs: matrix of tracks which are joined in the respective overlap,
%         params from stitching of that exp, XorY: 1 if
%         left-right (N-S, on x-axis) stitching, anything else if top-down stitch.
% Outputs: zipped

% Zipping general prep
params.threshUnseen = 400;

for camPair = 1:4 % X east, X west, Y North, Y South
    switch camPair
        case 1 % NW w/ SW
            XorY = 1; % X
            seam = params.cropXpx; % N/S middle of the seam
            A = joined(joined(:,5) == 1,:); % NW
            B = joined(joined(:,5) == 3,:); % SW
        case 2 % NE w/ SE
            XorY = 1; % X
            seam = params.cropXpx;
            A = joined(joined(:,5) == 2,:); % NE
            B = joined(joined(:,5) == 4,:); % SE
        case 3 % NW w/ NE
            XorY = 2; % Y
            seam = params.cropYpx;
            A = joined(joined(:,5) == 1,:); % NW
            B = joined(joined(:,5) == 2,:); % NE
        case 4 % SW w/ SE
            XorY = 2; % Y
            seam = params.cropYpx;
            A = joined(joined(:,5) == 3,:); % SW
            B = joined(joined(:,5) == 4,:); % SE
    end
    % Picks beg & end tracks @ seams (replace: ByID, check 1st/last pts)
    [aBeg1,aEnd1] = trackBegEnd(A,1); % all beg & end pts
    [bBeg1,bEnd1] = trackBegEnd(B,1);
    aBegIDs = aBeg1(aBeg1(:,XorY)>seam,:); % @ seams until midpoint of overl
    aEndIDs = aEnd1(aEnd1(:,XorY)>seam,:);
    bBegIDs = bBeg1(bBeg1(:,XorY)<seam,:);
    bEndIDs = bEnd1(bEnd1(:,XorY)<seam,:);
    aBeg = A(ismember(A(:,4),aBegIDs),:); % whole tracks
    aEnd = A(ismember(A(:,4),aEndIDs),:);
    bBeg = B(ismember(B(:,4),bBegIDs),:);
    bEnd = B(ismember(B(:,4),bEndIDs),:);
    aBegC = trackByIDFun(aBeg); % every cell = track
    aEndC = trackByIDFun(aEnd);
    bBegC = trackByIDFun(bBeg);
    bEndC = trackByIDFun(bEnd);

    % Make cell dict of columns: beg pts, end matching it, distance offset
    for begOrEnd = 1:2 % 1st goes through beg @ right seam, 2nd through end
        % Dict of a on left, pot. b matches on right (only non-engulfed)
        if begOrEnd == 1 % makes beg or end current
            aTimes = cell2mat(cellfun(@(n) [n(1,3) n(end,3)], aBegC,'un',0)); % [beg time, end time]
            bTimes = cell2mat(cellfun(@(n) [n(1,3) n(end,3)], bEndC,'un',0));
            dict = [aBegC cell(size(aBegC,1),1)];
            for i = 1:size(aBegC,1) % a       |beg-------end
                                    % b beg-----end|
                                    % time----|seam|--------->
                dict{i,2} = bEndC(all(bTimes < aTimes(i,:),2) & bTimes(:,2) > aTimes(i,1), 1);
            end
            dict(cellfun('isempty',dict(:,2)),:) = []; % removes where no pot matches found
            % Take SD (distance to point of pot match of same time...
            % for overlapping times for each pot match & only keep the pot match w/ lowest SD
            for a = 1:size(dict,1)
                SD = ones(1,size(dict{a,2},1)).*100;
                for b = 1:size(dict{a,2},1)
                    matchT = intersect(dict{a,1}(:,3), dict{a,2}{b,1}(:,3));
                    if size(matchT,1) > 200 % too short are noise or would awkwardly be connected
                        aMatchT = dict{a,1}(ismember(dict{a,1}(:,3),matchT),:);
                        bMatchT = dict{a,2}{b,1}(ismember(dict{a,2}{b,1}(:,3),matchT),:);
                        dist = sqrt((aMatchT(:,1)-bMatchT(:,1)).^2 + (aMatchT(:,2)-bMatchT(:,2)).^2);
                        SD(b) = std(dist);
                    end
                end
                dict{a,2} = dict{a,2}{SD==min(SD),1};
                if min(SD)>10 % arbitrary, not cutting too many
                    dict(a,:) = {[] []};
                end
            end
            dict(cellfun('isempty',dict(:,1)) ,:) = []; % Deletes
            
            % Prepping Interpolation
            aInterPre = cell(size(dict,1),1);
            bInterPre = cell(size(dict,1),1);
            for i = 1:size(dict,1)
                aWhole = dict{i,1};
                bWhole = dict{i,2};
                % Keeping from begPt to endPt ± 1 pt => only overlapping
                aInterPre{i,1} = aWhole(1:find(aWhole(:,3)>bWhole(end,3),1),:);
                bInterPre{i,1} = bWhole(  find(bWhole(:,3)<aWhole(1,3),1,'last'):end,:);
            end
        else
            aTimes = cell2mat(cellfun(@(n) [n(1,3) n(end,3)], aEndC,'un',0)); % [beg time, end time]
            bTimes = cell2mat(cellfun(@(n) [n(1,3) n(end,3)], bBegC,'un',0));
            dict = [aEndC cell(size(aEndC,1),1)];
            for i = 1:size(aEndC,1) % see above for explanation
                dict{i,2} = bBegC(all(bTimes > aTimes(i,:),2) & bTimes(:,1) < aTimes(i,2), 1);
            end
            dict(cellfun('isempty',dict(:,2)),:) = []; % removes where no pot matches found
            % Take SD for overlapping times for each pot match
            for a = 1:size(dict,1)
                SD = ones(1,size(dict{a,2},1)).*100;
                for b = 1:size(dict{a,2},1)
                    matchT = intersect(dict{a,1}(:,3), dict{a,2}{b,1}(:,3));
                    if size(matchT,1) > 200 % too short are noise or would awkwardly be connected
                        aMatchT = dict{a,1}(ismember(dict{a,1}(:,3),matchT),:);
                        bMatchT = dict{a,2}{b,1}(ismember(dict{a,2}{b,1}(:,3),matchT),:);
                        dist = sqrt((aMatchT(:,1)-bMatchT(:,1)).^2 + (aMatchT(:,2)-bMatchT(:,2)).^2);
                        SD(b) = std(dist);
                    end
                end
                dict{a,2} = dict{a,2}{SD==min(SD),1};
                if min(SD)>11 % arbitrary, not cutting too many
                    dict(a,:) = {[] []};
                end
            end
            dict(cellfun('isempty',dict(:,1)),:) = []; % Deletes
            
            % Prepping Interpolation
            aInterPre = cell(size(dict,1),1);
            bInterPre = cell(size(dict,1),1);
            for i = 1:size(dict,1)
                aWhole = dict{i,1};
                bWhole = dict{i,2};
                % Keeping from begPt to endPt ± 1 pt => only overlapping
                aInterPre{i,1} = aWhole(  find(aWhole(:,3)<bWhole(1,3),1,'last'):end,:);
                bInterPre{i,1} = bWhole(1:find(bWhole(:,3)>aWhole(end,3),1),:);
            end
        end
        % Interpolate function
        dictInter = [trackInterpolate(aInterPre,params) trackInterpolate(bInterPre,params)];
        % Getting overlapping times only bc pts at beg/end maybe interpol'd
        dictTimeMatch = cell(size(dictInter,1),1);
        for i = 1:size(dictInter,1)
            dictTimeMatch{i,1} = dictInter{i,1}(ismember(dictInter{i,1}(:,3),dictInter{i,2}(:,3)),:);
            dictTimeMatch{i,2} = dictInter{i,2}(ismember(dictInter{i,2}(:,3),dictInter{i,1}(:,3)),:);
        end
        % We need to sort again to avoid weird scattering of some tracks
        dictBlend = cellfun(@(n) sortrows(n,3), dictTimeMatch, 'un',0);
        
        % Blending: 'bending' beg tracks towards end neighbors
        dictBent = dictBlend(:,1);
        for i = 1:size(dictBlend,1)
            dt = dictBlend{i,1}(end,3) - dictBlend{i,1}(1,3); % length of track in fr
            if begOrEnd == 1
                rt = 1-(dictBlend{i,1}(:,3) - dictBlend{i,1}(1,3))./dt; % Relative time: fraction of how close to beg
            else
                rt = 1-(dictBlend{i,1}(end,3) - dictBlend{i,1}(:,3))./dt;
            end
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
        joined = [joined; dictBentMat(:,1:4) repmat(5,size(dictBentMat,1),1)]; % 5 in col5 bc. not one cam anymore
    end
    joined = trackSplitAuto(joined,params.threshSplit); % In case one b was assigned to >1 a.
                                                            % ToDo: fix in above a/b checking instead
end
zipped = joined;
