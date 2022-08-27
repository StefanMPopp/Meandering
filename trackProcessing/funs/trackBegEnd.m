function [varargout] = trackBegEnd(joined, dispLength, varargin)
% Picks out dispLength fixes before/after the end/beginning of a frag for plotting
% Inputs: joined as array, dispLength in frames
%         optional: 'cell' to make the output cells by ID
%                   'verbose' to disp when it's done
% Output: [x,y,t,ID,IDlastDigit] list of all points belonging to those frags
%         if 1 output specified: list of [beginnings;ends] (vertcat)
%         if 2 outputs: out1 = list of beginnings, out2 = list of ends
%         if 3 outputs: sizes = list of track lengths of orignal tracks [points]

if any(strcmp(varargin,'cell')) && nargout == 1
    error('trackBegEndFun: Can''t have 3 inputs (=cell) & just 1 output (=begEnd concatenated).')
end

if ~iscell(joined)
    % Sorting joined by time to always make min(t) first row of every ID cell
    [jCell, sizes] = trackByIDFun(joined);
    hundred = sizes > dispLength-1; % Tracks longer than display length
else
    jCell = joined;
    sizes = cellfun(@(t) size(t,1), jCell);
    hundred = sizes > dispLength-1;
end

% ToDo: replace cellfun w/ using sizes+, sizes-
trBeg = jCell; % Copying
trBeg(hundred,1) = cellfun(@(v) v(1:dispLength,:),jCell(hundred,1),'Un',0);
trEnd = jCell;
trEnd(hundred,1) = cellfun(@(v) v(end-dispLength+1:end,:),jCell(hundred,1),'Un',0);
if nargin == 2
    trBeg = cell2mat(trBeg);
    trEnd = cell2mat(trEnd);
end

if nargout == 1
    begEnd = unique([trBeg; trEnd],'rows');
    varargout{1} = begEnd;
elseif nargout == 2
    varargout{1} = trBeg;
    varargout{2} = trEnd;
elseif nargout == 3
    varargout{1} = trBeg;
    varargout{2} = trEnd;
    varargout{3} = sizes;
end
if any(strcmp(varargin,'verbose'))
    disp('trackBegEndFun done')
end