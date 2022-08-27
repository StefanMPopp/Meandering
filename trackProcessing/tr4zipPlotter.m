% Start with having tr3Join loaded, run sections 1, X (or Y), split, 1, X,... 
% Lets you plot complete tracks in the overlap areas between cameras &
% adjust anything (here, splitting is described but jAdjust etc also possb)
if  ~exist('tLimsDef','var') || isempty(tLimsDef); tLimsDef = {'0','150'}; end
tLims = inputdlg({'t lower end (min 0)','t upper end (max 450)'},'Z-dim size',[1,30],tLimsDef);
tLimsDef = tLims;
tLow = str2num(tLims{1}); tUp  = str2num(tLims{2}); if tUp>450; tUp = 450; end
        
zipj = joined;
xIdx = joined(:,1)>params.cropXpx-params.overlap-50 & joined(:,1)<params.cropXpx+params.overlap+50 &...
    joined(:,3)>tLow*1000 & joined(:,3)<tUp*1000;
yIdxN = joined(:,2)>params.cropYpx-params.overlap-50 & joined(:,2)<params.cropYpx+params.overlap+50 &...
    joined(:,1)<3000 &...
    joined(:,3)>tLow*1000 & joined(:,3)<tUp*1000;
yIdxS = joined(:,2)>params.cropYpx-params.overlap-50 & joined(:,2)<params.cropYpx+params.overlap+50 &...
    joined(:,1)>2999&...
    joined(:,3)>tLow*1000 & joined(:,3)<tUp*1000;

%% X
zipj(~xIdx,1) = NaN;
zipC = trackByIDFun(zipj);
zipC(cellfun(@(n) all(isnan(n(:,1))),zipC),:) = [];
fig = figure('units','normalized','outerposition',[0 0 1 1]);
hold on
for id = 1:length(zipC)
    plot3(zipC{id}(:,1),zipC{id}(:,2),zipC{id}(:,3))
end
hold off
rotate3d on
title('Click on lower points of straight lines, get cursor data, run Split section')

%% Y N
zipj(~yIdxN,1) = NaN;
zipC = trackByIDFun(zipj);
zipC(cellfun(@(n) all(isnan(n(:,1))),zipC),:) = [];
figure('units','normalized','outerposition',[0 0 1 1]);
hold on
for id = 1:length(zipC)
    plot3(zipC{id}(:,1),zipC{id}(:,2),zipC{id}(:,3))
end
hold off
rotate3d on
title('Click on lower points of straight lines, get cursor data, run Split section')

%% Y S
zipj(~yIdxS,1) = NaN;
zipC = trackByIDFun(zipj);
zipC(cellfun(@(n) all(isnan(n(:,1))),zipC),:) = [];
figure('units','normalized','outerposition',[0 0 1 1]);
hold on
for id = 1:length(zipC)
    plot3(zipC{id}(:,1),zipC{id}(:,2),zipC{id}(:,3))
end
hold off
rotate3d on
title('Click on lower points of straight lines, get cursor data, run Split section')

%% Split with cursor_infos
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
segment = 17; % For saving in tr3Joined

%% Delete with cursor_infos
id = zeros(size(cursor_info,2),1); % Get ID
maxID = max(joined(:,4));
for i = 1:size(cursor_info,2)
    indX = find(joined(:,1) == cursor_info(i).Position(1,1));
    indY = find(joined(:,2) == cursor_info(i).Position(1,2));
    indZ = find(joined(:,3) == cursor_info(i).Position(1,3));
    ind = intersect(intersect(indX,indY),indZ);
    id = joined(ind,4);
    joined(joined(:,4)==id,:) = [];
end; clear indX indY indZ i ind cursor_info
joined = sortrows(joined, [4,3]);
segment = 17; % For saving in tr3Joined
