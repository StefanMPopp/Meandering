function interpol8ed = trackInterpolate(interIn, params, quiet)
% 1) Calculates distance & time between points
% 2) fills gaps where ant was not tracked w/ linearly averaged locations,
%    as long as she didn't move more than threshold px in that time.
% 3) finds episodes of very slow movement (on scale of optic wobble)
% 4) calculates how far an ant moves between the last point of the
%    preceding and first point of the following, faster, episodes.
% 5) "Still" def when this distance is smaller than the threshStop distance
%    (~ ant size?).
% Inputs: matrix after manual joining but before smoothing,
%         params for thresh unseen (=NaN) & stop (=wobble)
%         optional: quiet for suppressing progress bar
% Output: Cell of tracks w/ interpolations & list of %s of how many
%         points of a moving ant were interpolated

% See Almeida et al. 2010 & Miller et al. 2011 for reviews.
%{
Columns are:
1 x in px
2 y in px
3 t in frames
4 ID
5 s (step-length, = inter-point distance [px])
6 dFrames (#of frames between points)
%}

threshUnseen = params.threshUnseen; % pts > that apart [px] not interpolated.
% stopRule = 'Keep'; % Whether to smooth stop periods or replace them w/ NaN.
% stopWindow = params.stopWindow; % Window over which a stop period is defined
% stHalfLo = floor(stopWindow/2);
% stHalfHi = ceil(stopWindow/2);
% threshWobble = params.threshWobble; % Distance of optical wobble

if ~exist('quiet','var')
    wBar = waitbar(0,'Interpol8ing 0% Initializing: Splitting to cell...');
end
if ~iscell(interIn)
    [jC, sizes] = trackByIDFun(interIn(:,1:4)); % Splits into cell
else
    jC = interIn;
    sizes = cellfun(@(n) size(n,1), interIn);
end
jC(sizes < 3,:) = []; % Deletes shortest frags (would lead to errors)


interpol8ed = cell(size(jC,1),1); % Preallocating
for tr = 1:size(jC,1)
    currTr = jC{tr};
    currTr(:,3) = round(currTr(:,3)); % For some weird reason mat2cell adds precision...
    dFrames = [NaN; diff(currTr(:,3),1)]; % #of frames between points
    if dFrames(2)>1 % gap between first & second point (can't be Bezie'd)
        dFrames = [NaN;dFrames];
        currTr = [currTr(1,:); currTr]; % repeat 1st point
        currTr(1,3) = currTr(1,3)-1;
    end
    if dFrames(end)>1 % gap between penultimate & last point (can't be Bezie'd) 
        dFrames = [dFrames;1];
        currTr = [currTr; currTr(end,:)]; % repeat last pt
        currTr(end,3) = currTr(end,3)+1;
    end
    xyDist = diff(currTr(:,1:2),1); % x & y dists between points for pythogarean below
    s = [NaN; sqrt(sum(xyDist.^2, 2))]; % Euclidean distance between points

    interPrep = [currTr(:,1:4) s dFrames s./dFrames];
    % Index in track where gap to predecessor is >1
    interInd = find(dFrames>1 & s < threshUnseen);
    nanInd = find(dFrames>1 & s >= threshUnseen);
    % Makes every row a cell to add a cell of points in between
    inter = mat2cell(interPrep(:,1:4),ones(size(interPrep,1),1));
    
    % Short gaps: Replaces 1st pt before gap w/ this pt + interpolated pts
    for i = 1:size(interInd,1)
        currInd = interInd(i,1);
        interPtsNr = dFrames(currInd)-1;
        
        interXY = interpolBezier(...
               [interPrep(currInd-2:currInd-1,1);interPrep(currInd:currInd+1,1)],...
               [interPrep(currInd-2:currInd-1,2);interPrep(currInd:currInd+1,2)],...
               interPtsNr); % Makes curvy (Bezier) xy interpolation
        inter{currInd-1} = [inter{currInd-1};...
            [interXY...
             linspace(inter{currInd-1,1}(end,3)+1,inter{currInd,1}(1,3)-1,interPtsNr)'...
             repmat(inter{currInd}(1,4),interPtsNr,1)]];
    end
    % Long gaps: adding NaNs
    for i = 1:size(nanInd,1)
        currInd = nanInd(i,1);
        currInt = inter{currInd};
        interNr = round((currInt(1,3)-inter{currInd-1}(end,3))); % Nr of points to be added
        inter{currInd-1,1} = [NaN(interNr,2) (inter{currInd-1,1}(end,3) : currInt(1,3)-1)',...
                              repmat(currInt(1,4),interNr,1)];
    end
    
    interpol = vertcat(inter{:});
    

    interpol8ed{tr,1} = interpol;
    if ~exist('quiet','var')
        waitbar(tr/size(jC,1),wBar,['Interpol8ing ' num2str(tr/size(jC,1)*100,2) '% of '...
            num2str(size(jC,1))]);
    end
end
interpol8ed(:,size(interIn,2)+1:end) = [];
if ~exist('quiet','var')
    close(wBar)
end