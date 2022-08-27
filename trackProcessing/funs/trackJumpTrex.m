function jump = trackJumpTrex(jumpIn, threshDist, threshSpeed, threshTime)
% Splits tracks at unlikely steps by assigning higher IDs to them
% jump = trackJumpTrex(jumpIn, threshDist, threshSpeed, threshTime)
% Inputs: matrix of points, max dist [px], max speed [px/f], max time [f]
% Output: matrix of points

if istable(jumpIn)
    varNames = jumpIn.Properties.VariableNames;
    jumpIn = table2array(jumpIn);
    tabl = 1;
end

jump = sortrows(jumpIn, [4 3]); % Sort by ID & then time
% Get dt, ds, dv, IDchange
xyDist = [NaN NaN; diff(jump(:,1:2),1)]; % x & y dists between points for pythagorean below
dist = sqrt(sum(xyDist.^2, 2)); % Euclidean distance between points
dt = [1; diff(jump(:,3))]; % #of frames between points
v = dist./dt;
IDchange = logical([0; diff(jump(:,4))]);

% Jumping is where there's no ID change & any of the thresholds surpassed
% (note on v: (v>threshSpeed & dist>8) becuase some wobble is super fast. Only splitting
% jumps >8px (=ant size, 90mm/s) lets your threshSpeed be less conservative)
jInd = [1; find(~IDchange & (dist>threshDist | v>threshSpeed | dt>threshTime)); length(v)+1];

% For every jPoint till end, increase ID
for j = 1:size(jInd,1)-1
    jump(jInd(j):jInd(j+1)-1,4) = jump(jInd(j):jInd(j+1)-1,4)+j;
end

if exist('tabl','var')
    jump = array2table(jump,'variablenames',varNames);
end
disp(['jumpSplit ' num2str(j-1) ' tracks'])
