%% Smoothes data after filling in missing points
% 1. Adds missing points through linear interpolation
% 2. Smoothes nest tracks w/ LOWESS (LOcally WEighted Scatterplot Smoothing).
%    See Matlab Filtering & Smoothing data page for how. Could be expanded w/
%    repeated running mean as in Hen et al. 2004 (SEE/SPSM).
% 3. Makes IDs go 1,2,3,...#ofTracks
%    Saves smoothed track
% 4. Equidistantly resamples smoothed track (e.g. 2mm between each point)
%    Saves EDR track
% 5. Adds metrics like angles, acceleration, etc to EDR track
%    Saves metrics & metrics meta file

% Scale of optic wobble (=min resolution): 0.09mm (=0.2px)
% Scale of optic wobble during stops: 2x2 px.
% Stop: 0.9mm/s in Hunt et al. 2016 = 2 px/s = 0.08 px/f.
    % My own data different: smaller value ~0.32mm/s = 0.5px/s = 0.02 px/f

% Load data
addpath(genpath('trackProcessing'))
[filename,filepath] = uigetfile('*.txt');
addpath(filepath);
colTrial = extractBetween(filename, '_', '_');
if exist('vidName','var') && ~strcmp(extractBetween(vidName,'_','_'),colTrial{:})
    clearvars correct % Switching input data
end
vidName = [extractBefore(filename,'_') '_' colTrial{:} '_'];
% keepStops = questdlg('What to do with stop periods?','Stop in or not','Keep','NaN','Keep');
keepStops = {'Keep'}; % EDR gets rid of stops. NaN @ stop is funky...
disp('Loading Data.')
if ~exist('correct','var') % Don't load the same .txt if it's already in the Workspace
    smoothInTab = readtable(filename);
    varNames = smoothInTab.Properties.VariableNames;
    smoothIn = table2array(smoothInTab);
end
load([vidName 'procParams']);

% === Interpolates missing data ===================
params.stopRule = keepStops;
interpol8ed = trackInterpolate(smoothIn, params);

% Smoothing adds pts & runs slowly @ NaN's -> removed here, added after smooth.
interpolNoNan = cellfun(@(n) n(~isnan(n(:,1)),:), interpol8ed, 'un',0); % tracks w/o interpolated NaNs
% Split tracks where NaN's were, to smooth over every track fragment separately
interpolFragsNested = cellfun(@(n) mat2cell(n, diff([0;find(diff(n(:,3))>1);size(n,1)])),interpolNoNan,'un',0);
interpolFrags = vertcat(interpolFragsNested{:}); % list of all frags
interpolNan = cellfun(@(n) n(isnan(n(:,1)),:), interpol8ed, 'un',0); % to be added after smoothFun

% === Smoothes using LOWESS & averaging positions in stopping episodes ===
save([vidName 'procParams'],'params','vidName')
smoothedC = trackSmooth(interpolFrags, params); % params has smooth window

smoothed = array2table(sortrows(cell2mat([smoothedC; interpolNan]),[4 3]),...
                       'variablenames',varNames(1:4)); % collating frags into tracks again
[~,~,trackNr] = unique(smoothed.id); smoothed.id = trackNr; % Make IDs go from 1,2,3,...
clearvars interpol8ed interpolFrags interpolFragsNested interpolNan interpolNoNan % To avoid memory issues
clearvars smoothInTab smoothIn

% === Equidistantly Resample Tracks (rids stop periods) ===
s = 2*params.pxpermm; % Resample step length [px] (should be ASmallAP, while no stop noise)
M = 50; % #of interpolated points between each input point. Higher = more precise but slower
type = "disp"; % "trav" for distance travelled, "disp" for net displacement

ids = unique(smoothed.id);
edrC = cell(size(ids));
wBar = waitbar(0,'EDR');
for id = 1:length(ids)
    waitbar(id/length(ids), wBar, 'EDRing')
    currTr = smoothed(smoothed.id==ids(id),:);
    edrC{id,1} = resampleEquidist(currTr, s, M, type);
end
edrC = edrC(cellfun(@(n) size(n,1)>9, edrC),:); % Kicks out stationary noise
edr = vertcat(edrC{:});
close(wBar)

% === Make Metrics Master ============================
[metrics,metricsMeta] = trackMetrics(edr, params); % Does the magic

% === Save === %
tStamp = num2str(round(now-737911,4),'%07.3f'); tStamp(4) = [];
writetable(smoothed, [vidName, num2str(tStamp) '_smooth.txt']);
tStamp = num2str(round(now-737911+0.001,4),'%07.3f'); tStamp(4) = [];
writetable(edr, [vidName, num2str(tStamp) '_EDR.txt']);
writetable(metrics, [vidName, num2str(tStamp) '_metricsMaster.txt']);
writetable(metricsMeta,[vidName, num2str(tStamp) '_metricsMasterMeta.txt']);
clearvars -except smoothed edr metrics vidName params
disp(['Smoothing, EDR, metrics on ' vidName ' done & .txt saved.'])
