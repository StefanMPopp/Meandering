function v = trackSpeed(in)
% Calculates speed in terms of input dimensions.
% Input: Currently only table.
% Output: speed.

xyDist = diff([in.x in.y],1); % x & y dists between points for pythogarean below
dt = [NaN; diff(in.t)]; % #of frames between points
s = [NaN; sqrt(sum(xyDist.^2, 2))]; % Euclidean distance between points
v = s./dt; % speed