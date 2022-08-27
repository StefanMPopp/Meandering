function [tracksOut, sizes] = trackByIDFun(tracks, varargin)
% Split by ID w/o arrayfun
% Input: Mat of tracks, optional: anything to add sizes as last column
% Outputs: Cell array where every cell is a track, sorted by t
%          Sizes: #of points per track
if istable(tracks) % Diff doesn't work on tables
    tabl = 1;
    varNames = tracks.Properties.VariableNames;
    if ~isempty(varargin) % last column added
        varNames{1,end+1} = 'sz';
    end
    tracks = table2array(tracks);
else
%     if size(tracks,2) ~= 4; error('If input is array, must be 4 cols wide'); end
%     varNames = {'x' 'y' 't' 'id'};
end
if iscell(tracks)
    tracks = cell2mat(tracks);
end

tracks = sortrows(tracks, [4,3]);
sizes = diff([0; find(diff(tracks(:,4))); size(tracks,1)]); % track lengths
if isempty(varargin)
    tracksOut = mat2cell(tracks, sizes); % Splits into cell
    if exist('tabl','var')
        tracksOut = cellfun(@(n) array2table(n,'variablenames',varNames),tracksOut,'un',0);
    end
else
    sizesRep = repelem(sizes,sizes); % repeats lengths length times, for cat
    tracksOut = mat2cell([tracks sizesRep], sizes); % sizes are last column
    if exist('tabl','var')
        tracksOut = cellfun(@(n) array2table(n,'variablenames',varNames),tracksOut,'un',0);
    end
end