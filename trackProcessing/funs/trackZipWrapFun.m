function joinedZip = trackZipWrapFun(joined,params)
% Joins fragments due to tracker errors, & zips (blends) tracks which are
% moving between cameras by 'bending' one overlapping part toward the other
% Inputs: joined & split matrix of tracks, params,
%         XorY: 1 = X (N to S), 2 = Y (E to W)
% Output: joinedZip (zipped...)

zipped = trackZip(joined, params);

% Deleting tracks which begin & end at same seam
% X seam
[beg1,End1] = trackBegEnd(zipped(:,1:4),1);
X1 = params.cropXpx-params.overlap;
X2 = params.cropXpx+params.overlap;
for b = 1:size(beg1,1) % Finds which tracks begin or end at seams
    bX1(b,1) = ismembertol(beg1(b,1),X1+1,1,'DataScale',1,'ByRows',1);
    eX1(b,1) = ismembertol(End1(b,1),X1+1,1,'DataScale',1,'ByRows',1);
    bX2(b,1) = ismembertol(beg1(b,1),X2-1,1,'DataScale',1,'ByRows',1);
    eX2(b,1) = ismembertol(End1(b,1),X2-1,1,'DataScale',1,'ByRows',1);
end
beIDX1 = beg1(bX1+eX1 == 2,4); % b&E at same seam = 'half loop'
beIDX2 = beg1(bX2+eX2 == 2,4);
% Picking which half loops stay within the seams (=likely zipping remnant)
for b = 1:size(beIDX1) % Makes cell of IDs of those staying w/in
    zipX1del{b,1} = zipped(zipped(:,4)==beIDX1(b,1),1:4);
    if any(zipX1del{b,1}(:,1)>X2)
        zipX1del{b,1} = zeros(1,4);
    end
end
for b = 1:size(beIDX2)
    zipX2del{b,1} = zipped(zipped(:,4)==beIDX2(b,1),1:4);
    if any(zipX2del{b,1}(:,1)<X1)
        zipX2del{b,1} = zeros(1,4);
    end
end
if exist('zipX1del','var') || exist('zipX2del','var')
    disp([num2str(size(zipX1del,1)) '@ same seam'])
    zipDel = [cell2mat(zipX1del); cell2mat(zipX2del)];
    delIDs = unique(zipDel(:,4));
    zipped(ismember(zipped(:,4),delIDs),:) = [];
end
% Y seam
[beg1,End1] = trackBegEnd(zipped(:,1:4),1);
Y1 = params.cropYpx-params.overlap;
Y2 = params.cropYpx+params.overlap;
for b = 1:size(beg1,1) % Finds which tracks begin or end at seams
    bY1(b,1) = ismembertol(beg1(b,2),Y1+1,1,'DataScale',1,'ByRows',1);
    eY1(b,1) = ismembertol(End1(b,2),Y1+1,1,'DataScale',1,'ByRows',1);
    bY2(b,1) = ismembertol(beg1(b,2),Y2-1,1,'DataScale',1,'ByRows',1);
    eY2(b,1) = ismembertol(End1(b,2),Y2-1,1,'DataScale',1,'ByRows',1);
end
beIDY1 = beg1(bY1+eY1 == 2,4);
beIDY2 = beg1(bY2+eY2 == 2,4);
% Picking which half loops stay within the seams (=likely zipping remnant)
zipY1del{1,1} = NaN(1,4);
for b = 1:size(beIDY1)
    zipY1del{b,1} = zipped(zipped(:,4)==beIDY1(b,1),1:4);
    if any(zipY1del{b,1}(:,2)>Y2)
        zipY1del{b,1} = zeros(1,4);
    end
end
zipY2del{1,1} = NaN(1,4);
for b = 1:size(beIDY2)
    zipY2del{b,1} = zipped(zipped(:,4)==beIDY2(b,1),1:4);
    if any(zipY2del{b,1}(:,2)<Y1)
        zipY2del{b,1} = zeros(1,4);
    end
end
zipDel = [cell2mat(zipY1del); cell2mat(zipY2del)];
delIDs = unique(zipDel(:,4));
zipped(ismember(zipped(:,4),delIDs),:) = [];

joinedZip = zipped;
