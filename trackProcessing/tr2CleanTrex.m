% 1) Identify noise areas & brushing them for 2) deletion of noise by
% brush-removing them in plots focused on individual noise areas

addpath(genpath('trackProcessing'))
if ~exist('stitch','var')
    filename = uigetfile('*.txt');
    stitch = readtable(filename); % if needed (see line below)
    colTrial = extractBetween(filename, '_', '_');
    vidName = [extractBefore(filename,'_') '_' colTrial{:} '_'];
end
load([vidName 'procParams']);
% logMeta = dir('log_*');
% logName = logMeta.name;
varNames = stitch.Properties.VariableNames;

thrDist = 50; % px
thrSpeed = 4; % px/f
thrTime = 300; % f
params.threshDist = thrDist;
params.threshSpeed = thrSpeed;
params.threshTime = thrTime;

% trackSimChecker(stitch) % Instead of splitting them up, just delete them all?
%stitch(ismember([stitch.x stitch.y stitch.t],brushedData,'rows'),:) = [];
% stitchSplit = trackSplitAuto(stitch, 3); % Synchronous pts: split if >3px apart
% cleanJump = trackJumpTrex(stitch, thrDist, thrSpeed, thrTime); % Splitting unlikely steps
cleanIn = stitch;

%% Get noise positions w/ brush data
close all
clear brushInds n % if running for 2nd time
nrSlices = 20;
tLo = 0;

% Creates plot of time slices through stitch to identify noise spots
nDat = cleanIn(1,:);
for i = 1:nrSlices
    tLo = tLo+450000/nrSlices; tHi = tLo+500;
    nDat = [nDat; cleanIn(cleanIn.t>tLo & cleanIn.t<tHi,:)];
end
nDat(1:3:end,:) = []; 
figure('units','normalized','outerposition',[0 0 1 1])
h = scatter3(nDat.x,nDat.y,nDat.t,1,nDat.t);
colormap lines
rotate3d on
title 'Hit z to brush noise points at 1 spot'

% Allows brushing & saving of noise spots programmatically
i = 1;
key = 13;
brushInds = [];
while key ~= 27
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
            brushInds(:,i) = get(h,'BrushData')';
            title('Saved. Hit z to brush next or Esc to end.')
        end
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
brushInds = logical(brushInds);

st = table2array(cleanIn); % For next section
i = 1; % Counter for next section. Ticks w/ every execution of it

%% Remove noise 1 by 1
if exist('n','var') % Saves all pts removed in last iteration as noise
    noiseC{i-1,1} = nRaw(~ismember(nRaw,n,'rows'),:);
end
if i>size(brushInds,2); error('You''re done!')
else; disp([num2str(i) ' of ' num2str(size(brushInds,2))])
end

br = nDat(brushInds(:,i),:); % What was brushed in section above
x1 = min(br.x)-10; x2 = max(br.x)+10;
y1 = min(br.y)-10; y2 = max(br.y)+10;

n = st(st(:,1)>x1 & st(:,1)<x2 & st(:,2)>y1 & st(:,2)<y2,:);
scatter3(n(:,1),n(:,2),n(:,3),1)
title 'Brush & remove all noise, close plot, run section again.'
linkdata on
nRaw = n; % All points to which Removed points are compared
i = i+1;

%% Nest 1
nX = 4750; % Rough position of nest entrance (get from some plot)
nY = 1400;
halfWindow = 200;
nest = cleanIn(cleanIn.x>nX-halfWindow & cleanIn.x<nX+halfWindow & cleanIn.y>nY-halfWindow & cleanIn.y<nY+halfWindow,:);
scatter(nest.x(1:2:end),nest.y(1:2:end),1)
title('Draw a polygon around nest, FIRST run next section, THEN close plot')
nestPoly = drawpolygon;
%% Nest 2
nestX = nestPoly.Position(:,1);
nestY = nestPoly.Position(:,2);
cleanIn(inpolygon(cleanIn.x,cleanIn.y,nestX,nestY),:) = [];
nestXY = mean(nestPoly.Position,1);

%% Delete from stitch
noise = array2table(cell2mat(noiseC),'variablenames',varNames);
cleanIn(ismember(cleanIn,noise,'rows'),:) = []; % Deletes noise
close all

%% Get Wall params
wallDat = cleanIn(cleanIn.t<400000,:);
scatter(wallDat.x,wallDat.y,1)
title('Get c\_i of xmin xmax ymin ymax')

%% Save
% Nest & wall params
params.nestXY = nestXY;
wall = [cursor_info(4).Position(1),...
        cursor_info(3).Position(1),...
        cursor_info(2).Position(2),...
        cursor_info(1).Position(2)]; % N S E W
params.wallXY = wall; % For excluding where ants were close to walls
save([vidName 'procParams'],'params','vidName')

% Saving .txt
tStamp = num2str(round(now-737911,4),'%07.3f'); tStamp(4) = [];
writetable(cleanIn, [vidName, tStamp, '_clean.txt'])
close all
disp('Saved. Move on to Join!')
open tr3Join
clearvars -except clean vidName params
