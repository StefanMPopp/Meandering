function [metrics,metricsMeta] = trackMetrics(metricsIn, params, inFormat)
% Calculates different metrics from the points and adds them as columns.
% Inputs: (cell of) smoothed tracks
%         params for pixel/mm & frames/second
%         opt: output format cellsByID in tab if 'cell', else
%                            all tracks in one cat table
% Output: cell of tracks w/ metrics added as columns (see below)
%         matrix of concatenated cell of above
% See Almeida et al. 2010 & Miller et al. 2011 for reviews.
%{
Columns are:
1 x in mm now
2 y in mm now
3 t still in s
4 ID
5 s (step-length, = inter-point distance [mm])
6 dFrames (#of frames between points)
7 v (speed between points [mm/s])
8 a (acceleration [mm*s^2]
9 disp (displacement = euclidean distance from start of track until then)
10 theta (angle in space)
11 alpha (turning angle between last 3 points, r=(-), l=(+))
12 Sin (sine of alpha)
13 Cos (cos of alpha)
14 adist (angular distance = turning angle/distance, aka curvature [°/mm]) 
15 wall (1 where the ant was near a wall (or tape), 2B excluded in summary)
16 startDisp (start displacment)
17 endDisp (end displacement)
%}

varNames = {'x','y','t','id','dFrames','s','v','a','disp','theta','alpha','sin','cos','adist','wall','nestDisp','tandem'};
% Converting input into array
if iscell(metricsIn)
    metricsIn = vertcat(metricsIn{:});
    if istable(metricsIn)
        metricsIn = table2array(metricsIn);
    end
elseif istable(metricsIn)
    metricsIn = table2array(metricsIn);
end
% Converting [px] & [frames] to [mm] & [s]
if ~exist('inFormat','var') % Track in [px]: convert x,y to [mm] & t to [s]
    pxpermm = params.pxpermm;
    fps = params.fps;
else % 'inFormat' exists: Don't convert to SI units
    pxpermm = 1; fps = 1;
end

% wallXY and nestXY given in params? If yes, convert to [mm]
if isfield(params,'nestXY')
    nestXY = params.nestXY./params.pxpermm; 
    doNest = 1; else; doNest = 0;
end
if isfield(params,'wallXY')
    wallXY = params.wallXY./params.pxpermm; % They are always in [px]
    doWall = 1; else; doWall = 0;
end

ids = unique(metricsIn(:,4));
metrics = cell(size(ids)); % Preallocating
    
for tr = 1:length(ids)
    track = metricsIn(metricsIn(:,4)==ids(tr),:);
    SI = single([track(:,1:2)./pxpermm track(:,3)./fps track(:,4)]);

    xyDist = diff(SI(:,1:2),1); % x & y dists between points for pythogarean below
    dt = [NaN; diff(SI(:,3))]; % #of frames between points
    s = [NaN; sqrt(sum(xyDist.^2, 2))]; % Euclidean distance between points
    v = s./dt; % speed
    a = [NaN; diff(v)]./dt; % acceleration
    dispPre = SI(:,1:2)-SI(1,1:2); % x & y displacements in separate columns
    disp = sqrt(sum(dispPre.^2, 2)); % displacement from first point
    theta = [NaN; atan2d(xyDist(:,1),xyDist(:,2))]; % angle in space
    alpha = [rad2deg(angdiff(deg2rad(theta))); NaN]; % turning angle (r=(-), l=(+))
    alpha(v==0) = 0; % Same heading when standing still
    Sin = sin(deg2rad(alpha)); % sine of turning angle
    Cos = cos(deg2rad(alpha)); % cosine of turning angle
    adist = alpha./s; % angular distance (= curvature)
    wall = false(size(s)); % where the ant was near a wall (or tape), to be excluded in summary
    if doWall == 1
        wall(SI(:,1)<wallXY(1) | SI(:,1)>wallXY(2) | SI(:,2)<wallXY(3) | SI(:,2)>wallXY(4)) = 1;
    end
    nestDisp = zeros(size(s));
    if doNest == 1
        nestDispPre = SI(:,1:2)-nestXY; % x & y displacements in separate columns|SHOULD BE pxpermm but breaks when ant xy=[mm]
        nestDisp = sqrt(sum(nestDispPre.^2, 2)); % displacement from nest
    end
    if exist('params.tandem','var') && ismember(track(1,4),params.tandem)
        tandem = ones(size(s));
    else
        tandem = zeros(size(s));
    end
    metrics(tr,:) = {[SI(:,1:4), single([dt s v a disp, theta alpha Sin Cos, adist wall nestDisp tandem])]};
end
metricsMat = vertcat(metrics{:});
metrics = array2table(metricsMat,'VariableNames',varNames);

description = {'x position' 'y position' 'time since start of experiment' 'track ID' 'frames to previous point' 'step length',...
    'speed' 'acceleration' 'displacement from track start' 'step angle in space (0=right,down=-)' 'turn angle' 'sin(turn angle)',...
    'cos(turn angle)' 'angular distance' 'near wall' 'displacement of point from nest' 'tandem run?'};
units = {'mm' 'mm' 's' '1' '1' 'mm' 'mm/s' 'mm*s^-2' 'mm' 'degree' 'degree' '1' '1' 'degree/mm' 'logic' 'mm' '1'};
metricsMeta = cell2table(...
    [varNames' description' units'],'variablenames',{'name','description','units'});
