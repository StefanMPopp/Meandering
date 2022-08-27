%% Load data, split & join
% Zipping: also getting nestXY (a priori rough nest area required)
% Last step: splitting tracks into
%           'full': start&end near nest & go away from nest,
%           'open': start near & went away from nest, ending away from nest
%           'background': long tracks not start/ending @ nest (for HRM)
% Select file to work on.
addpath(genpath('trackProcessing'))
[filename,filepath] = uigetfile('*.txt');
if isempty(filename)
    error('No worries, just run the first section again when you feel ready.')
end
addpath(filepath);
colTrial = extractBetween(filename, '_', '_');
if exist('vidName','var') && ~strcmp(extractBetween(vidName,'_','_'),colTrial{:})
    clearvars joined % Switching input data
end
vidName = [extractBefore(filename,'_') '_' colTrial{:} '_'];
disp('Loading Data.')
if ~exist('joined','var') % Don't load the same .txt if it's already in the Workspace
    joinedTab = readtable(filename);
    varNames = joinedTab.Properties.VariableNames;
    joined = table2array(joinedTab);
end

load([vidName 'procParams']);
% logMeta = dir('log_*');
% logName = logMeta.name;
% logJoinPre = load(logName);
% logPoints = 0;
% funFactsStruct = load('funFacts.mat'); funFacts = funFactsStruct.funFacts;
% level = ceil(logJoinPre(end,1)/3600);

crXn = params.cropXpx-params.overlap; % north overlap margin of X
crXs = params.cropXpx+params.overlap; % south
crYw = params.cropYpx-params.overlap; % west
crYe = params.cropYpx+params.overlap; % east
threshSplit = 3.75; % For splitting points which have same t & ID (<that [px]: merging)
params.threshSplit = threshSplit; % To pass to SplitAuto in zipFun

% Preps plotting
if ispc; pSz = 8; else; pSz = 16; end % plot point size
segmentViews = [-92,20; -92,20; -92,20; -92,20;...
                 -1,20;  -1,20;  -1,20;  -1,20;...
                  9, 9; repmat([-92,20],6,1);
                  0, 90];
% Colors
% colorScheme = % make some selector, maybe as extra script?
trCol = [lines(7); 0 1 0; 1 0 1; 0 0 0; .8 .8 .8];
trColSz = jet(11);
trColSz(5,2:3) = trColSz(5,2:3)-.2;
trColSz(6:7,:) = trColSz(6:7,:)-.1;
trColSz(8,1:2) = trColSz(8,1:2)-.2;

segmentList = {'1xNE','2xNW','3xSE','4xSW','5yNE','6yNW','7ySE','8ySW',...
    '9zip','1k','2k','3k','4k','5k','6k','all','Special'};

if ~exist('segment','var') % Takes .txt name as default segment
    segmentIn = extractBefore(extractAfter(filename,'_j'),'.txt');
    segment = find(strcmp(segmentList,segmentIn));
end
tLimsDef = {'0','100'}; % First 100k frames
tLow = 0; % Initializing
tUp = 450;
lineLength = 2000; % how many frames are displayed? [curr only in 'all']
nestR = 18; % nest radius [px]
disp('Data loaded. Run next section.')

%% Plots
if ~exist('segmentList','var'); error('Run the 1st section first!'); end
% Ask which segment to work on
[segment,segmOk] = listdlg('ListString', segmentList,...
    'SelectionMode', 'Single', 'PromptString', 'Select segment to work on',...
    'Initialvalue',segment,'Name','Segment Selector','ListSize',[150,230]);
if segmOk == 0
    error('Go again')
end
% Selecting camera/zipping/all
if segment < 5
    beIn = joined(joined(:,5)==segment,:);
elseif segment < 9
    beIn = joined(joined(:,5)==segment-4,:);
elseif segment == 9 % Zipping
    zipType = questdlg('1st time zip or got cursor data?','Zip Type','1st','got c_d','1st');
    if strcmp(zipType,'1st')
        % Getting rough nest coords (where most tracks begin), ks: 900 max px
        [b1,~] = trackBegEnd(joined,1);
        [dens,xy] = ksdensity(b1(b1(:,1)>4000 & b1(:,1)<5500 &...
            b1(:,2)>1000 & b1(:,2)<3000,1:2)); % Rough nest position
        [~,topNestInd] = maxk(dens,4);
        nestXY = mean(xy(topNestInd,:)); % 1st iteration (rough 1st estimation)
        b1 = b1(b1(:,1)>nestXY(1)-200 & b1(:,1)<nestXY(1)+200 &...
            b1(:,2)>nestXY(2)-200 & b1(:,2)<nestXY(2)+200,1:2); % Zoomed in
        [dens,xy] = ksdensity(b1); % 2nd estimation, now pretty precise
        [~,topNestInd] = maxk(dens,4);
        params.nestXY = mean(xy(topNestInd,:));
        save([vidName 'procParams'],'params','vidName')
        % Splitting simultaneous, zipping X, then Y.
        jSplit = trackSplitAuto(joined,threshSplit);
        jJump = trackJumpTrex(jSplit,500,100,1000); % For the long jumps
        jZip = trackZipWrapFun(jJump,params);
%         jZip = trackZipWrapFun(jSplit,params); % If you want to skip jump
        joined = trackJoinAutoFun(jZip,10,2); % ant length & 2 frames for joining the zip seams
%         logPoints = logPoints + 100; % 16:20m for milestone
    elseif strcmp(zipType,'got c_d')
        % get cursor_infos from 'all' plot
        % Splitting simultaneous, zipping X, then Y.
%         jSplit = trackSplitAuto(joined(:,1:5),threshSplit);
%         jJump = cell2mat(trackJump(jSplit,200,20)); % For the long jumps
        zipped = trackZipCtr(joined, cursor_info, params); % center diagonal
        joined = zipped;
%         logPoints = logPoints + 100; % 16:20m for milestone
        clear cursor_info
    end
    msgbox('Zipping done. Run last section to save!')
    
elseif segment == 17 % Split or jumpSplit or auto join or del shortest
    [specialAction,spActOk] = listdlg('ListString', {'split simult' 'jump split' 'autoJoin' 'del shortest'},...
            'PromptString', 'Select special action(s)',...
            'Initialvalue',1,'Name','Special Action Selector','ListSize',[150,60]);
    if spActOk == 0
        error('Go again')
    end
    if any(specialAction == 1) % Split simultaneous
        joined = trackSplitAuto(joined,threshSplit); % threshSplit: wobble/same ant (merging instead of splitting)
    end
    if any(specialAction == 2) % Jump split
        if ~exist('threshJumpDef','var')||isempty(threshJumpDef)
            threshJumpDef = {'1000','8','10000','1'}; % jump thresh params
        end
        threshJump = inputdlg({'Jump Length Thresh [px]','Speed Thresh [px/f]',...
        'Time Thresh [f]'},'Jump Thresholds',[1,30],threshJumpDef);
        threshJumpDef = threshJump; % Replaces default
        threshJdist = str2double(threshJump{1}); threshJspeed = str2double(threshJump{2});
        threshJtime = str2double(threshJump{3});   
        joined = trackJumpTrex(joined, threshJdist, threshJspeed, threshJtime); % threshs dist [px], px/f, or f
    end
    if any(specialAction == 3) % auto Join
        if ~exist('joinAutoDef','var')||isempty(joinAutoDef)
            joinAutoDef = {'256','512','1'}; % jump thresh params
        end
        joinAutoAns = inputdlg({'s range','t range','#of iterations'},'joinAuto dims',[1,10],joinAutoDef);
        joinAutos = str2double(joinAutoAns{1}); joinAutot = str2double(joinAutoAns{2});
        joinAutoi = str2double(joinAutoAns{3});
        for i = [1 2:2:joinAutoi]
            joined = trackJoinAutoFun(joined, joinAutos/i, joinAutot/i);
            disp([num2str(i) ' of ' num2str(joinAutoi) ' joinAuto done'])
        end
    end
    if any(specialAction == 4) % Delete shortest
        threshDelShortStr = inputdlg({'Delete Shortest Thresh'},'del threshold',[1,30],{'1'});
        threshDelShort = str2double(threshDelShortStr{1});
        joinedC = trackByIDFun(joined);
        jLongC = joinedC(cellfun(@(n) size(n,1)>threshDelShort, joinedC),:); % Deletes shortest
        joined = vertcat(jLongC{:});
        disp(['Deleted ' num2str(length(joinedC)-length(jLongC)) ' tracks.'])
    end
    msgbox('Special action done, save & join again!')
else
    beIn = sortrows(joined,[4 3]);
    sizes = diff([0; find(diff(beIn(:,4))); size(beIn,1)]);
    beIn(:,5) = repelem(sizes,sizes);
end
if segment ~= 9 && segment < 17 % Plotting, not zipping or splitting/finishing
    [b300,E300] = trackBegEnd(beIn(:,1:5),lineLength,'cell');
    b300NACell = cellfun(@(n) [n(1,1:2) NaN n(1,4:5);n;n(end,1:2) NaN n(1,4:5)], b300, 'Un',0);
    E300NACell = cellfun(@(n) [n(1,1:2) NaN n(1,4:5);n;n(end,1:2) NaN n(1,4:5)], E300, 'Un',0);
    % ToDo: add NaN after 2x max display length to avoid directly connected
    % start & end portions of tracks
    bE200NA = trackLastDigitFun([cell2mat(b300NACell);cell2mat(E300NACell)]);
    b1 = cell2mat(cellfun(@(n) n(1,:), b300,'un',0));
    E1 = cell2mat(cellfun(@(n) n(end,:), E300,'un',0));
    bE1 = trackLastDigitFun([b1; E1]);
end
% =========== end getting begEnd data/zip/split =============

% =========== Cropping points ==================
% Which part of the selected cam/area to plot (overl or slices)
if segment < 5 % X overl
    bE1O = bE1(bE1(:,1)>crXn-100 & bE1(:,1)<crXs+100,:); % begs in X overl to not brush some oob
    bE1O((bE1O(:,1)>crXn-2 & bE1O(:,1)<crXn+2) |...
         (bE1O(:,1)>crXs-2 & bE1O(:,1)<crXs+2) |...
         (bE1O(:,2)>crYw-2 & bE1O(:,2)<crYw+2) |...
         (bE1O(:,2)>crYe-2 & bE1O(:,2)<crYe+2),:) = []; % To not connect tracks @ seams
    beLines = bE200NA(ismember(bE200NA(:,4),bE1O(:,4)),:); % beg/end 200 in overl
    beLines(beLines(:,1)<crXn-100 | beLines(:,1)>crXs+100,1:2) = NaN;
    plotData = bE1O; % What brushing will pick up
elseif segment < 9 % Y overl
    if segment > 6 % Y south
        if isempty(tLimsDef); tLimsDef = {'0','100'}; end
        tLims = inputdlg({['Total #of points: ' num2str(size(bE1,1)) newline newline 't lower end (min 0)'],'t upper end (max 450)'},'Z-dim size',[1,30],tLimsDef);
        tLimsDef = tLims;
        tLow = str2num(tLims{1});
        tUp  = str2num(tLims{2}); if tUp>450; tUp = 450; end
    end
    bE1O = bE1(bE1(:,2)>crYw-100 & bE1(:,2)<crYe+100 &...
        bE1(:,3)>tLow*1000 & bE1(:,3)<tUp*1000,:); % begs in X overl
    bE1O((bE1O(:,1)>crXn-2 & bE1O(:,1)<crXn+2) |...
         (bE1O(:,1)>crXs-2 & bE1O(:,1)<crXs+2) |...
         (bE1O(:,2)>crYw-2 & bE1O(:,2)<crYw+2) |...
         (bE1O(:,2)>crYe-2 & bE1O(:,2)<crYe+2),:) = []; % To not connect tracks @ seams
    beLines = bE200NA(ismember(bE200NA(:,4),bE1O(:,4)),:); % beg/end 200 in overl
%     bE1O(ismember(bE1O(:,4),seamers(:,4)),6) = 11;
%     beLines(ismember(beLines(:,4),seamers(:,4)),6) = 11;
    beLines(beLines(:,2)<crYw-100 | beLines(:,2)>crYe+100,1:2) = NaN;
    plotData = bE1O; % The only data the brushing will pick up
elseif segment ~= 9 && segment < 17 % Slices or all
    if isempty(tLimsDef); tLimsDef = {'0','150'}; end
    tLims = inputdlg({['Total #of points: ' num2str(size(bE1,1)) newline ' t lower end (x1000)'],'t upper end (x1000)'},'Z-dim size',[1,30],tLimsDef);
    tLimsDef = tLims;
    tLow = str2num(tLims{1});
    tUp  = str2num(tLims{2}); if tUp>450; tUp = 450; end
    if segment == 16 % all
        bE1O = bE1(bE1(:,3)>tLow*1000 & bE1(:,3)<tUp*1000,:); % Cutting
    else % slices
        bE1O = bE1(bE1(:,1)<(segment-9)*1000 & bE1(:,1)>(segment-10)*1000 &...
            bE1(:,3)>tLow*1000 & bE1(:,3)<tUp*1000,:); % Cutting
    end
    beLinesPre = bE200NA(ismember(bE200NA(:,4),bE1O(:,4)),:); % Copying above action
    beLinesPre(beLinesPre(:,3)<tLow*1000 | beLinesPre(:,3)>tUp*1000,:) = [];
    if segment < 16 % 1k-6k: clipping the segments
        beLines = beLinesPre(beLinesPre(:,1)<(segment-9)*1000 & beLinesPre(:,1)>(segment-10)*1000,:);
    else % >=16: all, so no x restrictions
        beLines = beLinesPre;
    end
    beLines(:,5) = log10(beLines(:,5));
    beLines(:,6) = round((beLines(:,5)-min(beLines(:,5)))/(max(beLines(:,5))-min(beLines(:,5)))...
                            .*(size(trColSz,1)-1))+1; % normalized length. +1 to avoid 0 idxing
    plotData = bE1O;
end

% ==============================MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
% ========== Plotting ==========MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
if segment ~= 9 && segment <17 % Not zipping/finishing
    fig = figure('name',segmentList{segment},'units','normalized','outerposition',[0 0 1 1]);
    if segment < 9 % Before zipping
        hold on
        for co = 1:size(trCol,1)
            currbE = beLines(beLines(:,end)==co-1,:);
            line(currbE(:,1),currbE(:,2),currbE(:,3),'color',trCol(co,:),'LineWidth',1)
        end
        h = scatter3(bE1O(:,1),bE1O(:,2),bE1O(:,3),pSz,bE1O(:,6));
        hold off
        colormap(trCol)
    elseif segment > 9 % after zipping
        hold on
        for co = 1:size(trColSz,1)
            currbE = beLines(beLines(:,end)==co,:);
            line(currbE(:,1),currbE(:,2),currbE(:,3),'color',trColSz(co,:),'LineWidth',1)
        end
        line(currbE(:,1),currbE(:,2),currbE(:,3),'color',trColSz(co,:),'LineWidth',1.5)
        h = scatter3(bE1O(:,1),bE1O(:,2),bE1O(:,3),pSz,bE1O(:,5));
        hold off
        colormap(jet); colorbar
        set(gca,'colorscale','log')
        set(gca,'Color', [.95,.95,.95]) % Light grey background
    end
    
    title(['z -> brush beg/end points -> desel. brush -> x: join, '...
        'c: delete track, v: delete points. '...
        'Backspace to erase last assignment, Esc: close & save.'])
    view(segmentViews(segment,:))
    % =================== end Plotting ==============================
    
    % Getting IDs from brushed plot interactively w/ keypresses
    i = 1;
    key = 13;
    brushInds = [];
    delInds = [];
    delPtInds = [];
    while key ~= 27 % Until Esc is pressed
        if key ~= 122 % skip this if z was pressed after z (already got some brushed)
            pause % Allows to press a key for action
            key = double(get(gcf,'CurrentCharacter'));
        end
        if key == 122 % z for activating brush
            brush on
            title('Brush pts, deselect brush function & hit x to save') % must deselect brush now
            pause % Allows to brush now
            key = double(get(gcf,'CurrentCharacter')); % to allow saving key
            if key == 120 % x for saving
                if sum(get(h, 'BrushData'))==0 % Warning messages: none brushed
                    msgbox('Brush tracks first, or hit Esc to exit.','None clicked', 'warn')
                    pause
                end
                brushInds(:,i) = get(h, 'BrushData')';
                title('Saved. Hit z to brush next or Esc to end.')
            elseif key == 99 % c to delete tracks from raw data
                delInds(:,i) = get(h,'BrushData')';
                title([num2str(sum(delInds(:,i))) ' tracks deleted'])
            elseif key == 118 % v to delete indiv. points from raw data
                delPtInds(:,i) = get(h,'BrushData')';
                title([num2str(sum(delPtInds(:,i))) ' points deleted'])
            elseif key == 27 % Esc to close plot w/o saving potential current
                close all
            end
%             delete(findall(gcf,'type','annotation')) % Textbox is slow -> xlabel?
%             annotation('textbox',[.01 .9 .3 .1],'String',...
%                     {['Total saved: ' num2str(size(brushInds,2))]...
%                      ['Total deleted: ' num2str(sum(sum(delInds>0)))]},...
%                      'LineStyle','none')
            zlabel(['Total saved: ' num2str(size(brushInds,2))])
            xlabel(['Total deleted: ' num2str(sum(sum(delInds>0)))])
        elseif key == 120 % Pressed z, z, x. Still saving 
            if sum(get(h, 'BrushData'))>0
                brushInds(:,i) = get(h, 'BrushData')';
                title('Saved. Hit z to brush next or Esc to end.')
            else
                msgbox('Brush tracks first, or hit Esc to exit.','None clicked', 'warn')
                pause
            end
        elseif key == 8 % Return to delete last assignment
            try brushInds(:,i-1) = [];
                i = i-1; catch
            end
            msgStr.Interpreter = 'tex'; msgStr.WindowStyle = 'modal';
            msg = msgbox({'\fontsize{12} Last assignment undone.'},'Undoing',msgStr);
            pause(1); try close(msg); catch; end
        elseif key == 27 % Esc to close plot
            close all
        end
        i = i+1;
    end

    % Assigning later IDs to first brushed one
    disp(['Joining segment ' segmentList{segment} ', ' num2str(tLow) '-' num2str(tUp)])
%     if level>0
%         disp(funFacts{level,1}{randi(size(funFacts{level,1},1)),1}) % Display a rnd fun fact
%     else; disp('Once you passed the training you will see messages & later fun facts here!')
%     end
    if ~isempty(brushInds)
        brushInds(:,sum(brushInds)==0) = [];
        wBar = waitbar(0,'Joining');
        brushInds = logical(brushInds);
        idDict = [0 0];
        for tr = 1:size(brushInds,2)
            waitbar(tr/size(brushInds,2),wBar,'Joining')
            idsCurr = unique(plotData(brushInds(:,tr),4));
            if any(ismember(idsCurr,idDict(:,1))) % Chained assignments of multiple brushes to one track
                chainLink = unique(idDict(ismember(idDict(:,1),idsCurr),2));
                idDict = [idDict; idsCurr repmat(chainLink(1),size(idsCurr,1),1)];
            else % Just one brush per track
                idDict = [idDict; idsCurr repmat(idsCurr(1),size(idsCurr,1),1)];
            end
        end
        for tr = 1:size(idDict,1)
            waitbar(tr/size(idDict,1),wBar,'Joining')
            joined(joined(:,4)==idDict(tr,1),4) = idDict(tr,2);
        end
        close(wBar)
    else
        disp('Nothing joined')
    end

    % Deleting brushed tracks to be deleted
    delInds = logical(sum(delInds,2)); % get brush gives double 1/0 cols
    delID = plotData(delInds,4); % t & ID uniquely identify points
    joined(ismember(joined(:,4),delID,'rows'),:) = [];
    
    % Deleting brushed points to be deleted
    delPtInds = logical(sum(delPtInds,2));
    joined(ismember(joined(:,3:4),plotData(delPtInds,3:4),'rows'),:) = [];

    if segment == size(segmentList,2)
        scatter(bE200NA(:,1),bE200NA(:,2),1,bE200NA(:,5))
        set(gca,'ColorScale','log')
        colorbar
        colormap(jet)
%         exportgraphics(gca,[vidname 'jAll.png'])
        close all
    end
%     logPoints = logPoints + size(brushInds,2)+1 + round(sum(sum(delInds)>0)); % 1 for loading
else % If zipping, splitting, or finishing
%     logPoints = logPoints + 30; % 5min for task switching cost
end

%% Save
% % Quantity control: log of how many you connected
% logPoints = logPoints+3; % For saving & uploading
% logJoin = logJoinPre;
% logJoin(end+1,:) = [logJoinPre(end,1)+logPoints round(now-737911)];
% disp(['You have earned ' num2str(logPoints) ' points today!' newline...
%         'Level ' num2str(level) '. Points to next level: ' num2str((level+1)*3600-logJoin(end,1))])
% writematrix(logJoin, logName,'Delimiter',' ')
% Data
joinedTab = array2table(joined,'variablenames',varNames);
tStamp = num2str(round(now-737911,4),'%07.3f'); tStamp(4) = [];
writetable(joinedTab, [vidName,tStamp,'_j', segmentList{segment}, '.txt']);
if segment == 18
    writematrix(finalBackground, [vidName,'background.txt']);
    writematrix(finalNest2Nest, [vidName,'nest2nest.txt']);
    writematrix(finalPartialTracks, [vidName,'partialTracks.txt']);
end
disp('Saved. Continue with running sections 1 & 2.')
clearvars -except joined* segment tUp tLow vidName params varNames
