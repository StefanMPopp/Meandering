function cross = crossFun(ants)
% Calculates crossings between any 2 tracks (including self-crossings)
% Input: all ants
% Output: Table of all open & closing cross points (x,y,t,id)

% ToDo: inds of crosses to be integrated into close:cross analysis

% Add dx, dx to input data for caculations below
ants.dx = [diff(ants.x);NaN];
ants.dy = [diff(ants.y);NaN];

% Make blocks of ±equal points
qrx = quantileranks(ants.x,5); % x direction, 5 blocks
xm = [0;min(ants.x(qrx==2));min(ants.x(qrx==3));... % midline between blocks
        min(ants.x(qrx==4));min(ants.x(qrx==5))];
xl = xm-1.5; % low border
xh = xm+1.5; % high border
qry = quantileranks(ants.y,2); % y direction
yl = min(ants.y(qry==2))-1.5;
yh = min(ants.y(qry==2))+1.5;

% Indices of points by block
rC = {               ants.x<xh(2) & ants.y<yh; % lower blocks
      ants.x>xl(2) & ants.x<xh(3) & ants.y<yh;
      ants.x>xl(3) & ants.x<xh(4) & ants.y<yh;
      ants.x>xl(4) & ants.x<xh(5) & ants.y<yh;
      ants.x>xl(5) &                ants.y<yh;
                     ants.x<xh(2) & ants.y>yl; % upper blocks
      ants.x>xl(2) & ants.x<xh(3) & ants.y>yl;
      ants.x>xl(3) & ants.x<xh(4) & ants.y>yl;
      ants.x>xl(4) & ants.x<xh(5) & ants.y>yl;
      ants.x>xl(5) &                ants.y>yl};

openCloseC = cell(size(rC));
for r = 1:numel(rC)
    [track,tInd] = sortrows(ants(rC{r},:),'x'); % Sort by x
    trSz = size(track,1);
    x = track.x;
    y = track.y;
    dx = track.dx;
    dy = track.dy;

    % Calculates crossing vectors
    crossInds = cell(size(dx));
    startInd = 1;
    for j = 2:trSz-1
        while track.x(startInd) < track.x(j)-2.1
            startInd = startInd+1;
        end
        sliceInds = startInd:j-1;
        den = dx(sliceInds).*dy(j)-dy(sliceInds).*dx(j); % Precompute the denominator
        ua = (dx(j).*(y(sliceInds)-y(j))-dy(j).*(x(sliceInds)-x(j)))./den;
        ub = (dx(sliceInds).*(y(sliceInds)-y(j))-dy(sliceInds).*(x(sliceInds)-x(j)))./den;
        closeIndsAll = find(ua>0 & ub>0 & ua<1 & ub<1)+startInd-1; % If 0 > ua&ub < 1: intersection
        closeIndsAll(closeIndsAll==1,:) = [];
        crossInds{j,1} = [closeIndsAll; j]; 
    end
    crossInds(cellfun(@(n) size(n,1)<2, crossInds)) = []; % Removes empty cells
    
    % Metrics (inds)
    for i = 1:size(crossInds,1)
        crossInds{i,1}(:,2) = track.t(crossInds{i,1});
    end
    crossInds = cellfun(@(n) sortrows(n,2), crossInds, 'un',0); % sort inds by t
    crossInds = cell2mat(cellfun(@(n) [n(1:end-1,1) n(2:end,1)], crossInds,'un',0)); % making col1 open, col2 close
    openInd = crossInds(:,1);
    closeInd = crossInds(:,2);
%     track = table2array(track); remove after testing
    openCloseC{r,1} = [track{openInd,1:4} track{closeInd,1:4}];
end
cross = array2table(unique(vertcat(openCloseC{:}),'rows'),...
    'variablenames',{'openX' 'openY' 'openT' 'openID',...
    'closeX' 'closeY' 'closeT' 'closeID'});
cross.dt = cross.closeT - cross.openT;
cross.self = cross.openID == cross.closeID;