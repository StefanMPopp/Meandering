function transDict = trackTransDict(params)
% Makes the transformation matrix for TR xy

% Create raw concat points
[x,y] = meshgrid(1:1:3840, 1:1:2160);
matSize = size(x(:),1);
xy = [x(:) y(:)];
t = [(1:matSize)' (1:matSize)'];
trNE = [xy t ones(matSize,1)    (1:matSize)'];
trNW = [xy t ones(matSize,1).*2 ((1:matSize)+matSize)'];
trSE = [xy t ones(matSize,1).*3 ((1:matSize)+matSize*2)'];
trSW = [xy t ones(matSize,1).*4 ((1:matSize)+matSize*3)'];

% Run through stitch function
stitch = trackStitchDict(trNE, trNW, trSE, trSW, params);
% Get stitch parts which were one of the input vids
stitchNE = stitch(stitch(:,5)==1,:);
stitchNW = stitch(stitch(:,5)==2,:);
stitchSE = stitch(stitch(:,5)==3,:);
stitchSW = stitch(stitch(:,5)==4,:);
% Make dict where 1:2 is raw input & 3:4 is stitch-transformed output
transDictNE = [trNE(ismember(trNE(:,6),stitchNE(:,6)),1:2) stitchNE(:,1:2)];
transDictNW = [trNW(ismember(trNW(:,6),stitchNW(:,6)),1:2) stitchNW(:,1:2)];
transDictSE = [trSE(ismember(trSE(:,6),stitchSE(:,6)),1:2) stitchSE(:,1:2)];
transDictSW = [trSW(ismember(trSW(:,6),stitchSW(:,6)),1:2) stitchSW(:,1:2)];

transDict = {transDictNE;transDictNW;transDictSE;transDictSW};
