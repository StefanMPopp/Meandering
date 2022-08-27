% Splits tracks in 2 at cursor_infos

% Import
addpath(genpath('trackProcessing'))
if ~exist('joined','var')
    filename = uigetfile('*.txt');
    joinedMat = readtable(filename); % if needed (see line below)
    varNames = joinedMat.Properties.VariableNames;
    joined = table2array(joinedMat);
    colTrial = extractBetween(filename, '_', '_');
    vidName = [extractBefore(filename,'_') '_' colTrial{:} '_'];
end
if istable(joined)
    varNames = joined.Properties.VariableNames;
    joined = table2array(joined);
end
load([vidName 'procParams']);
joined = trackLastDigitFun(joined);

currSl = 1;

%% Plot Slices & get cursor_info
% Split joined into manageable slices
slt = [1:45000:225000 225000:25000:450000];
jSlt = joined(joined(:,3)>slt(currSl) & joined(:,3)<slt(currSl+1),:);
jC = trackByIDFun(jSlt);
currSl = currSl+1;

% Plot
for i = 1:length(jC)
    currTr = jC{i};
    hold on
    plot3(currTr(:,1),currTr(:,2),currTr(:,3))
    hold off
end
title('Get cursor\_infos after which a track must be broken.')

%% Split tracks w/ ci
% Works with any cursor_info on joined
id = zeros(size(cursor_info,2),1); % Get ID
maxID = max(joined(:,4));
for i = 1:size(cursor_info,2)
    indX = find(joined(:,1) == cursor_info(i).Position(1,1));
    indY = find(joined(:,2) == cursor_info(i).Position(1,2));
    indZ = find(joined(:,3) == cursor_info(i).Position(1,3));
    ind = intersect(intersect(indX,indY),indZ);
    id = joined(ind,4);
    currTrEnd = find(joined(:,4)==id,1,'last'); % Index of track to be split
    joined(ind+1:currTrEnd,4) = maxID+i; % Assigns following part of track highest ID
end; clear indX indY indZ i ind cursor_info
joined = sortrows(joined, [4,3]);

%% Plotting too fast tracks
% Getting jumps from joined (matrix)
jump = sortrows(joined, [4 3]); % Sort by ID & then time
xyDist = [NaN NaN; diff(jump(:,1:2),1)]; % x & y dists between points for pythagorean below
dist = sqrt(sum(xyDist.^2, 2)); % Euclidean distance between points
dt = [1; diff(jump(:,3))]; % #of frames between points
v = dist./dt;
IDchange = logical([0; diff(jump(:,4))]);
jInd = find(~IDchange & v>12);
if isempty(jInd)
    disp('No jumps detected')
end

% === Plotting loop === %
jDict = zeros(1,size(jInd,1));
key = 13;
for i = 1:length(jInd) % Until Esc is pressed
    jTr = joined(jInd(i)-600:jInd(i)+600,:);
    jTr(jTr(:,4)~=jTr(601,4),:) = NaN;
    plot3(jTr(:,1),jTr(:,2),jTr(:,3))
    hold on
    scatter3(joined(jInd(i),1),joined(jInd(i),2),joined(jInd(i),3))
    hold off
    title('hit z for cutting, x for skipping')
    xlabel([num2str(i) ' of ' num2str(length(jInd))])
    ylabel(['v = ' num2str(v(jInd(i)))])
    pause
    key = double(get(gcf,'CurrentCharacter')); % to allow saving key
    if key == 122 % z for cutting
        jDict(i) = jInd(i);
    end
    if key == 120 % x for skipping
        jDict(i) = 0;
    end
    if key == 27
        close all
        break
    end
end
close all
jDict(jDict==0) = []; % Deleting placeholders for skipped tracks

% === Splitting what was selected in plots === %
if ~isempty(jDict) % Some must be cut
    maxID = max(joined(:,4));
    for i = 1:length(jDict)
        ind = jDict(i);
        id = joined(ind,4);
        currTrEnd = find(joined(:,4)==id,1,'last'); % Index of track to be split
        joined(ind:currTrEnd,4) = maxID+i;
    end
end
joined = sortrows(joined,[4 3]);

%% Delete track parts w/ brushing
i = 1;
%% Delete jump parts w/ brushing
jTr = joined(jInd(i)-500:jInd(i)+500,:);
jTr(jTr(:,4)~=jTr(501,4),:) = NaN;
plot3(jTr(:,1),jTr(:,2),jTr(:,3))
hold on
scatter3(joined(jInd(i),1),joined(jInd(i),2),joined(jInd(i),3))
hold off
xlabel([num2str(i) ' of ' num2str(numel(jInd))])
title('Save brushData, then close plot & run section again')
i = i+1;

%% Deleting w/ brushedData from above
bd = [brushedData;
%     brushedData1;
%     brushedData2;
%     brushedData3;
%     brushedData4;
%     brushedData5;
%     brushedData6;
%     brushedData7;
%     brushedData8;
%     brushedData9
%     brushedData10
%     brushedData11
    ];
joined(ismember(joined(:,1:3), bd, 'rows'),:) = [];
clear brushedData*

%% Deleting or skipping whole tracks loop
jDict = zeros(size(jInd));
ids = unique(joined(jInd ,4));
key = 13;
for id = 1:length(ids) % Until Esc is pressed
    jTr = joined(joined(:,4)==ids(id),:);
    plot3(jTr(:,1),jTr(:,2),jTr(:,3))
    title('hit z for del, x for skipping')
    xlabel([num2str(id) ' of ' num2str(length(ids))])
    ylabel(['v = ' num2str(v(jInd(id)))])
    pause
    key = double(get(gcf,'CurrentCharacter')); % to allow saving key
    if key == 122 % z for deleting
        jDict(id) = ids(id);
    end
    if key == 120 % x for skipping
        jDict(id) = 0;
    end
    if key == 27
        close all
        break
    end
end
close all
joined(ismember(joined(:,4),jDict),:) = []; % Deleting whole tracks

%% Save
if ~istable(joined); joined = array2table(joined(:,1:5),'variablenames',varNames);end
tStamp = num2str(round(now-737911,4),'%07.3f'); tStamp(4) = [];
writetable(joined, [vidName,tStamp,'_jSplit.txt'],'Delimiter',' ');
clearvars -except joined* vidName params varNames
