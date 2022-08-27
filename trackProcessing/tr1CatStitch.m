%% Enter some parameters & plot sync
% Prepares individual .txt files from tracker for stitching:
% Makes IDs of different cameras different & corrects t
% Inputs: name of trial, path where raw .txt files are, sync times from
% syncInfo sheet
% Outputs: concatenated raw files: 1 for each camera

% Download raw .txt files (whole folder) from GDrive Raw_indiv into your Matlab file path
% Pull folder into your MATLAB path, extract, delete the zip folder
% Add extracted folder to path, just like your trackProcessing
% Run sections.

addpath(genpath('trackProcessing'))
% Install Computer Vision toolbox (for lens) if not already installed.
if isempty(which('cameraCalibrator'))
  warning('Please install the Computer Vision Toolbox.');
end

shiftCalib = 'No.';
if exist('params','var') && isfield(params,'nameExp') && isfield(params,'nameCol') && isfield(params,'nameTrial')
    default = {params.nameExp; params.nameCol; params.nameTrial; '2.235'; '25'};...
else; default = {'HRM'; 'T'; '1'; '2.235'; '25'};
end % Sets the default input of following dialog box in case you did it already
inputMeta = inputdlg({'Experiment Name', 'Colonly Name', 'Trial Name', 'Pixel/mm', 'fps'},...
    'EnterTrialName',[1 30], default);
params.nameExp = inputMeta{1,1};
params.nameCol = inputMeta{2,1};
params.nameTrial = inputMeta{3,1};
vidName = [params.nameExp '_' params.nameCol params.nameTrial '_'];
params.nameVid = vidName;
tracksBaseDir = uigetdir('/media/stefan/','Open tracks folder');
filedir = [tracksBaseDir '/' vidName 'rawIndiv'];
addpath(genpath(filedir))
params.filedir = filedir;
params.framesChunkList = readtable([filedir '/' vidName 'framesList.txt']);
params.pxpermm = str2double(inputMeta{4,1});
params.fps = str2double(inputMeta{5,1});
% For trackInterpolFun: 
params.threshUnseen = 22; % pts > that apart [px] not interpolated.
params.threshStop = 0.08; % 2 pts have øv<that [px/f] → pts between them are interpol@ed @ the mean location
params.stopWindow = 10; % Only periods of at least this length are seen as stops
% For trackSmoothFun:
params.smoothWindowSize = 10; % half-window size of LOESS: higher=smoother.
params.threshWobble = 1.5; % diameter [px] of optic wobble on a still ant (1x1)

% Stitch parameters
params.NEtheta = 0; % Rotation angle
params.NWtheta = 0.2;
params.SEtheta = -1.2;
params.SWtheta = -1.2;
params.cropXpx = 2600; % Where N&S meet
params.cropYpx = 2000; % Where E&W meet
params.overlap = 100; % How many px each pair overlaps (higher # = more redundancy)
params.zoomNEX = 1.02;
params.zoomNEY = 1.03;
params.zoomNW = 1.01;
params.zoomSE = 1;
params.zoomSW = 1.01;
params.shiftNEX = 50; % How many X px each camera frame is shifted to right
params.shiftNEY = 30; %          Y
params.shiftNWX = 10;
params.shiftNWY = 1794;
params.shiftSEX = 2220;
params.shiftSEY = -10;
params.shiftSWX = 2260;
params.shiftSWY = 1730;

% Run the self-written function to load all .txt & concatenate them
[NErawPre, NWrawPre, SErawPre, SWrawPre] = trackCatFunTrex(params);
SWrawPre.x = SWrawPre.x*38.4; SWrawPre.y = SWrawPre.y*38.4; % Scales SW (remove if gets fixed in trex)
% Plot a temp. slice of the area where all 4 overlap to fine-tune syncing
NEraw = NErawPre;
NWraw = NWrawPre;
SEraw = SErawPre;
SWraw = SWrawPre;
syncPlot = trackSyncPlotter(NEraw, NWraw, SEraw, SWraw, params);

%% Changes times in tracks. Check in plot. If not perfect, save c-i again
NWraw.t = NWraw.t + (cursor_info(4).Position(3) - cursor_info(3).Position(3));
SEraw.t = SEraw.t + (cursor_info(4).Position(3) - cursor_info(2).Position(3));
SWraw.t = SWraw.t + (cursor_info(4).Position(3) - cursor_info(1).Position(3));
params.syncNW = cursor_info(4).Position(3) - cursor_info(3).Position(3);
params.syncSE = cursor_info(4).Position(3) - cursor_info(2).Position(3);
params.syncSW = cursor_info(4).Position(3) - cursor_info(1).Position(3);
% Redoing w/ stored sync info
% NWraw(:,3) = NWrawPre(:,3) + params.syncNW;
% SEraw(:,3) = SErawPre(:,3) + params.syncSE;
% SWraw(:,3) = SWrawPre(:,3) + params.syncSW;
clear cursor_info

trackSyncPlotter(NEraw, NWraw, SEraw, SWraw, params);

save([vidName 'procParams'],'params','vidName')


%% Save raw concat, stitch, & save stitch
if exist('cursor_info','var') % Means that sync was adjusted a 2nd time
    NWraw(:,3) = NWraw(:,3) + (cursor_info(4).Position(3) - cursor_info(3).Position(3));
    SEraw(:,3) = SEraw(:,3) + (cursor_info(4).Position(3) - cursor_info(2).Position(3));
    SWraw(:,3) = SWraw(:,3) + (cursor_info(4).Position(3) - cursor_info(1).Position(3));
end

dirname = [tracksBaseDir '/' vidName 'rawConcat'];
mkdir(dirname)
writetable(NEraw, [dirname '/NEraw.txt']); % Copy of raw joined track file.
writetable(NWraw, [dirname '/NWraw.txt']); % Upload to GDrive.
writetable(SEraw, [dirname '/SEraw.txt']);
writetable(SWraw, [dirname '/SWraw.txt']);

% Stitching
% Stitches 4 videos together. Details in trackStitchFun.
% Inputs: 4 raw.txt, crops, rotations, overlap, shifts, zooms
% Output: one stitch file

% load('HRM_T1_procParams') % This block for bugfixing only
% NEraw = readtable([vidName 'NEraw.txt']);
% NWraw = readtable([vidName 'NWraw.txt']);
% SEraw = readtable([vidName 'SEraw.txt']);
% SWraw = readtable([vidName 'SWraw.txt']);

% Adding column to distinguish between cameras
NEraw.cam = ones(height(NEraw),1);
NWraw.cam = ones(height(NWraw),1)*2;
SEraw.cam = ones(height(SEraw),1)*3;
SWraw.cam = ones(height(SWraw),1)*4;

% Must be before splitting of tracks @ seams (in stitchFun)
% & after zipping, else they will
% be joined again by this function. Noise a problem?
jNE = NEraw;
jNW = NWraw;
jSE = SEraw;
jSW = SWraw;
jList = [40 100; 20 50; 10 25; 5 12];
for i = 1:4
    jNE = trackJoinAutoFun(NEraw,jList(i,1),jList(i,2));
    jNW = trackJoinAutoFun(NWraw,jList(i,1),jList(i,2));
    jSE = trackJoinAutoFun(SEraw,jList(i,1),jList(i,2));
    jSW = trackJoinAutoFun(SWraw,jList(i,1),jList(i,2));
end
% Run custom stitch function
stitch = trackStitchFun(jNE, jNW, jSE, jSW, params);

% Does the shift have to be changed?
cropXpx = params.cropXpx;
cropYpx = params.cropYpx;
overlap = params.overlap;
s = stitch(stitch.t<200000 & stitch.t>70000 &...
    stitch.x<cropXpx+400 & stitch.y<cropYpx+500,:);
figure
scatter3(s.x,s.y,s.t,1,s.cam)
zlim([min(s.t), min(s.t)+10000])
colormap jet
title('Does the shift have to be adjusted? Y: yes. Any other key: no.')
pause
key = double(get(gcf,'CurrentCharacter'));
close all

if shiftCalib == 121
    % Calibrate stitch params shift by clicking in plots
    % Adjust calibration parameters SW to SE
    % Run a plot, if very off consistently into 1 direction, change shift
    % values above by the amount the focal camera is off
    s = stitch((stitch(:,1)>cropXpx-overlap & stitch(:,1)<cropXpx+overlap) |...
        (stitch(:,2)>cropYpx-overlap & stitch(:,2)<cropYpx+overlap) &...
        stitch(:,3)>100000&stitch(:,3)<200000,:);
    scatter3(s(:,1),s(:,2),s(:,3),1,s(:,5))
    error('There. I stopped the code for you to adjust the shift params.')
    %{
    % SW to SE
    s = stitch(stitch(:,3)<200000 & stitch(:,3)>190000,:);
    s = s(s(:,1)>cropXpx-overlap,:);
    s = s(s(:,2)<cropYpx+overlap & s(:,2)>cropYpx-overlap,:);
    figure
    scatter3(s(:,1),s(:,2),s(:,3),1,s(:,5))
    zlim([min(s(:,3)), min(s(:,3))+5000])
    colormap(jet)
    title('Click on \color{red}SW \color{black}first, save as cursor\_infoSW, close plot & do next')

    % NE to NW&SE
    s = stitch(stitch(:,3)<200000 & stitch(:,3)>70000,:);
    s = s(s(:,1)<cropXpx+400,:);
    s = s(s(:,2)<cropYpx+500,:);
    figure
    scatter3(s(:,1),s(:,2),s(:,3),1,s(:,5))
    zlim([min(s(:,3)), min(s(:,3))+10000])
    colormap(jet)
    title('Click on \color{blue}NE \color{black}first, to Yellow, save, close, hit key')
    
    % NW to SW
    s = stitch(stitch(:,3)<200000 & stitch(:,3)>50000,:);
    s = s(s(:,1)>cropXpx-overlap & s(:,1)<cropXpx+overlap,:);
    s = s(s(:,2)>cropYpx-overlap,:);
    figure
    scatter3(s(:,1),s(:,2),s(:,3),1,s(:,5))
    zlim([min(s(:,3)), min(s(:,3))+5000])
    colormap(jet)
    title('Click on \color{cyan}NW \color{black}first, then Red, save, close, do next')
    
    pause

    % Adjusting w/ cursor_infos
    dxSW = cursor_infoSW(1).Position(1)-cursor_infoSW(2).Position(1);
    dySW = cursor_infoSW(1).Position(2)-cursor_infoSW(2).Position(2);
    params.shiftSWX = params.shiftSWX + dxSW;
    params.shiftSWY = params.shiftSWY + dySW;
    dxNW = cursor_infoNW(1).Position(1)-cursor_infoNW(2).Position(1);
    dyNW = cursor_infoNW(1).Position(2)-cursor_infoNW(2).Position(2);
    params.shiftNWX = params.shiftNWX + dxNW;
    params.shiftNWY = params.shiftNWY + dyNW;
    dxNE = cursor_infoNE(1).Position(1)-cursor_infoNE(2).Position(1);
    dyNE = cursor_infoNE(1).Position(2)-cursor_infoNE(2).Position(2);
    params.shiftNEX = params.shiftNEX + dxNE;
    params.shiftNEY = params.shiftNEY + dyNE;
    stitch = trackStitchFun(NEraw, NWraw, SEraw, SWraw, params);

    save([vidName 'procParams'],'params','vidName')
    %}
end

% Save
disp('Saving stitch')
tStamp = num2str(round(now-737911,4),'%07.3f'); tStamp(4) = [];
writetable(stitch, strcat('/home/stefan/Documents/MATLAB/', vidName, num2str(tStamp), '_stitch.txt'));
clearvars -except stitch vidName
open('tr2CleanTrex')
