function stitch = trackStitchFun(NEraw, NWraw, SEraw, SWraw, params)
% Stitches tracks of 4 videos together by applying lens distortion,
% flipping, shifting, rotating & cropping* tracks from cameras.
% * including increasing IDs of track parts which have left the frame after
% cropping.
% Inputs: 4 raw.txt, crops, rotations, overlap (shifts, zooms possible in future)
%           lensParams.mat must be on path. You get it from cameraCalib.m.
% Output: one stitch file

if istable(NEraw)
    varNames = NEraw.Properties.VariableNames;
    NEraw = table2array(NEraw);
    NWraw = table2array(NWraw);
    SEraw = table2array(SEraw);
    SWraw = table2array(SWraw);
end
% Unpack parameters
NEtheta = params.NEtheta;
NWtheta = params.NWtheta;
SEtheta = params.SEtheta;
SWtheta = params.SWtheta;
cropXpx = params.cropXpx;
cropYpx = params.cropYpx;
overlap = params.overlap;
zoomNEX = params.zoomNEX;
zoomNEY = params.zoomNEY;
zoomNW = params.zoomNW;
zoomSE = params.zoomSE;
zoomSW = params.zoomSW;
shiftNEX = params.shiftNEX;
shiftNEY = params.shiftNEY;
shiftNWX = params.shiftNWX;
shiftNWY = params.shiftNWY;
shiftSEX = params.shiftSEX;
shiftSEY = params.shiftSEY;
shiftSWX = params.shiftSWX;
shiftSWY = params.shiftSWY;

% Rotate S (bc camera orientation)
disp('1/8: Rotating S videos 180°')
NEflip = NEraw;
NWflip = NWraw;
SEflip = [1920 + (1920 - SEraw(:,1)), 1080 + (1080 - SEraw(:,2)), SEraw(:,3:end)];
SWflip = [1920 + (1920 - SWraw(:,1)), 1080 + (1080 - SWraw(:,2)), SWraw(:,3:end)];

% Transform
disp('2/8: Transforming')
NEflip = [NEflip(:,1:2), zeros(size(NEflip,1),1); 1 1 0; 3840 2160 0]; % add z col for transform &
NWflip = [NWflip(:,1:2), zeros(size(NWflip,1),1); 1 1 0; 3840 2160 0]; % ...2 points in corners...
SEflip = [SEflip(:,1:2), zeros(size(SEflip,1),1); 1 1 0; 3840 2160 0]; % ...for rescaling
SWflip = [SWflip(:,1:2), zeros(size(SWflip,1),1); 1 1 0; 3840 2160 0];

rot = diag([1 1 1]); % rotation matrix
trans = [1 1 1]; % translation vector
load('lensParams.mat','params') % gets camera 'params' from trackProcessing/funs. Replace that for new lens w/ cameraCalib
% Do the transformation
NElens = worldToImage(params, rot, trans, NEflip);
NWlens = worldToImage(params, rot, trans, NWflip);
SElens = worldToImage(params, rot, trans, SEflip);
SWlens = worldToImage(params, rot, trans, SWflip);
clear NEflip NWflip SEflip SWflip
% The output of the transformation is normalized. The below rescales it
NElens(:,1) = NElens(:,1)./3278.3;
NElens(:,2) = NElens(:,2)./3275.5;
NWlens(:,1) = NWlens(:,1)./3278.3;
NWlens(:,2) = NWlens(:,2)./3275.5;
SElens(:,1) = SElens(:,1)./3278.3;
SElens(:,2) = SElens(:,2)./3275.5;
SWlens(:,1) = SWlens(:,1)./3278.3;
SWlens(:,2) = SWlens(:,2)./3275.5;

NElens = [NElens(1:end-2,1:2), NEraw(:,3:end)]; % Add t, ID from raw & delete z
NWlens = [NWlens(1:end-2,1:2), NWraw(:,3:end)];
SElens = [SElens(1:end-2,1:2), SEraw(:,3:end)];
SWlens = [SWlens(1:end-2,1:2), SWraw(:,3:end)];
clear NEraw NWraw SEraw SWraw

% Rotate
disp('3/8: Rotating')
NEtform = affine2d([cosd(NEtheta) -sind(NEtheta) 0; sind(NEtheta) cosd(NEtheta) 0; 0 0 1]);
NWtform = affine2d([cosd(NWtheta) -sind(NWtheta) 0; sind(NWtheta) cosd(NWtheta) 0; 0 0 1]);
SEtform = affine2d([cosd(SEtheta) -sind(SEtheta) 0; sind(SEtheta) cosd(SEtheta) 0; 0 0 1]);
SWtform = affine2d([cosd(SWtheta) -sind(SWtheta) 0; sind(SWtheta) cosd(SWtheta) 0; 0 0 1]);
NErot = NElens; NWrot = NWlens; SErot = SElens; SWrot = SWlens;
[NErot(:,1),NErot(:,2)] = transformPointsForward(NEtform, NElens(:,1), NElens(:,2));
[NWrot(:,1),NWrot(:,2)] = transformPointsForward(NWtform, NWlens(:,1), NWlens(:,2));
[SErot(:,1),SErot(:,2)] = transformPointsForward(SEtform, SElens(:,1), SElens(:,2));
[SWrot(:,1),SWrot(:,2)] = transformPointsForward(SWtform, SWlens(:,1), SWlens(:,2));
clear NElens NWlens SElens SWlens NEtform NWtform SEtform SWtform

% Zoom
disp('4/8: Zooming')
NEzoom = [NErot(:,1).*zoomNEX, NErot(:,2).*zoomNEY, NErot(:,3:end)];
NWzoom = [NWrot(:,1:2).*zoomNW, NWrot(:,3:end)];
SEzoom = [SErot(:,1:2).*zoomSE, SErot(:,3:end)];
SWzoom = [SWrot(:,1:2).*zoomSW, SWrot(:,3:end)];
clear NErot NWrot SErot SWrot

% Shift
disp('5/8: Shifting')
NEshift = NEzoom;
NWshift = NWzoom;
SEshift = SEzoom;
SWshift = SWzoom;
NEshift(:,1) = NEzoom(:,1)+shiftNEX;
NEshift(:,2) = NEzoom(:,2)+shiftNEY;
NWshift(:,1) = NWzoom(:,1)+shiftNWX;
NWshift(:,2) = NWzoom(:,2)+shiftNWY;
SEshift(:,1) = SEzoom(:,1)+shiftSEX;
SEshift(:,2) = SEzoom(:,2)+shiftSEY;
SWshift(:,1) = SWzoom(:,1)+shiftSWX;
SWshift(:,2) = SWzoom(:,2)+shiftSWY;
clear NEzoom NWzoom SEzoom SWzoom

X1 = cropXpx - overlap; % Right end of overlap
X2 = cropXpx + overlap; % Left end of overlap
Y1 = cropYpx + overlap; % Top end of overlap
Y2 = cropYpx - overlap; % Bottom end of overlap

% Give track parts which will be cut up by following cropping different IDs
disp('6/8: Changing IDs for zipping')
% Increasing ID for 3 videos to not coincide/overlap
try
    SWshift(:,4) = SWshift(:,4) + max(SEshift(:,4))+1;
catch
    warning('No SE?')
end
try
    NWshift(:,4) = NWshift(:,4) + max(SWshift(:,4))+1;
catch
    warning('No SW?')
end
try
    NEshift(:,4) = NEshift(:,4) + max(NWshift(:,4))+1;
catch
    warning('No NW?')
end

NEcropPre = NEshift;
NWcropPre = NWshift;
SEcropPre = SEshift;
SWcropPre = SWshift;

% Crop
disp('7/8: Cropping')
NEcrop = NEcropPre(NEcropPre(:,1) < X2 & NEcropPre(:,2) < Y1,:);
NWcrop = NWcropPre(NWcropPre(:,1) < X2 & NWcropPre(:,2) > Y2,:);
SEcrop = SEcropPre(SEcropPre(:,1) > X1 & SEcropPre(:,2) < Y1,:);
SWcrop = SWcropPre(SWcropPre(:,1) > X1 & SWcropPre(:,2) > Y2,:);
clear NEcropPre NWcropPre SEcropPre SWcropPre

% Combine
disp('8/8: Combining')
stitch = [NEcrop; NWcrop; SEcrop; SWcrop];
clear NEcrop NWcrop SEcrop SWcrop

% Make t start at 1
stitch(:,3) = stitch(:,3) - min(stitch(:,3)) +1;

% Make IDs go from 1,2,3,...
[~,~,trackNr] = unique(stitch(:,4));
stitch(:,4) = trackNr;
stitch = array2table(stitch, 'variableNames',varNames);
