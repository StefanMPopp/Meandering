%% Meander simulation & analysis script
% 1-click creation of meander data.
% Loads ant data, creates simulations,
% calculates 3 metrics (turn autocorrelation, #of crosses, dispersivity)
% for each raw data track & their simulations,
% saves the output as .mat to be analyzed & plotted in m2 and m3 scripts.
% Inputs: ants table
%         either meanderParams table or setting params in this script
% Output: Struct w/ fields acAnt & acAntRe, each w/ field metr.
%                       metr has columns 0 cross 1, 2, id, minRho, minTau

% Operating system compatibility
if ispc; slash = '\'; else; slash = '/'; end

trials = {'HRM_T1_','HRM_U1_','HRM_V1_','HRM_W1_','HRM_Y1_'};
newFolder = "Yes";

if newFolder == "Yes"
    infolder = uigetdir('cleanDir','Get the clean folder'); % Where the ants data, excludeParams & procParams are
    addpath(genpath(infolder))
    tStamp = num2str(round(now-737911,4),'%07.3f'); tStamp(4) = []; % time stamp
    meanderDirName = ['meander_' tStamp]; % Making new folder for this analysis
    mkdir(meanderDirName); addpath(meanderDirName);
    defParams = {'1999' '10' '30'}; % nrSims nrBins tauMax
    analysisParams = inputdlg({'#of Simulations','#of Bins for CRW',...
                               ['Max ' char(964) ' for turn autocorrelation']},...
                               'Enter analysis parameters',[1 30],defParams);
    nrSims = str2num(analysisParams{1}); % #of simulations per empirical track (min 39)
    nrBins = str2num(analysisParams{2}); % For CRWas: #of bins the raw a & s are divided into
    tauMax = str2num(analysisParams{3}); % Max time lag for autocorrelation analysis
    meanderParams = table(string(infolder),nrSims,nrBins,tauMax,...
            'variablenames',{'infolder','nrSims','nrBins','tauMax'});
    writetable(meanderParams,[meanderDirName slash 'meanderParams.txt'])
else % Save into same meander analysis folder
    meanderDirName = uigetdir('meander','Get the meander folder');
    addpath(genpath(meanderDirName))
    meanderParams = readtable([meanderDirName slash 'meanderParams.txt']);
    infolder = meanderParams.infolder{:};
    addpath(genpath(infolder))
    nrSims = meanderParams.nrSims;
    nrBins = meanderParams.nrBins;
    tauMax = meanderParams.tauMax;
end

% Does the calculations
for tri = 1:length(trials)
    vidName = trials{tri};
    ants = readtable([infolder slash vidName 'ants.txt']);
    ids = unique(ants.id);
    trial = table(convertCharsToStrings(extractBetween(vidName, '_', '_')),'variablenames',{'trial'});
    load([infolder slash vidName 'procParams.mat']);
    % Summary metrics/stats/descriptors of each whole set of raw data
    sumStats.nrOfPoints = [trial array2table(height(ants),'variablenames',{'nrOfPoints'})];
    sumStats.nrOfTracks = [trial array2table(length(ids),'variablenames',{'nrOfTracks'})];
    sumStats.speedMedian = [trial array2table(nanmedian(ants.v),'variablenames',{'speedMedian'})];

    % #of ants out at a frame over time
    nrAntsOutTimes = [min(ants.t); (144:144:18000)'];
    nSamp = length(nrAntsOutTimes);
    nrAntsOut = zeros(nSamp,2);
    for i = 1:nSamp
        t = nrAntsOutTimes(i);
        nrAntsOut(i,:) = [t, numel(unique(ants.id(ants.t>t & ants.t<t+4)))];
    end
    sumStats.nrAntsOut = [repmat(trial,length(nrAntsOutTimes),1) array2table(nrAntsOut,'variablenames',{'t','nrAntsOut'})];

    % Calculating per-track metrics: turn autocorrelation, mean displacement, #of crosses
    % Preallocations
    meandStrct.mDispAnt = cell(size(ids));
    meandStrct.acAnt = cell(size(ids));
    meandStrct.crossesAnt = cell(size(ids));
    meandStrct.mDispSim = cell(size(ids));
    meandStrct.acSim = cell(size(ids));
    meandStrct.crossesSim = cell(size(ids));
    meandStrct.trackMeta = cell(size(ids));
    wBar = waitbar(0,'Starting','name','Meander Analysis');
    meanToc = round(nrSims/600);
    tic
    for tr = 1:length(ids)
        % Raw ant
        waitbar((tr)/(numel(ids)-1),wBar,[trials(tr) ', track ' num2str(tr) '/' num2str(numel(ids)),...
            '. Eta: ' num2str(round(meanToc*(length(ids)-tr))) 'min'],'name','Meander Analysis')
        ant = ants(ants.id==ids(tr),:); % Current track to be analyzed
        % Track metadata (length [mm] & duration [s])
        meandStrct.trackMeta{tr,1} = [trial array2table([sum(ant.s(2:end)) ant.id(1) nansum(ant.dFrames) sum(ant.alpha(2:end-1))],...
            'variablenames',{'trackLength' 'id' 'trackDuration' 'trackSumAlpha'})];
        % Ac, disp, crosses
        [~,acCurr] = turnAutocorrFun(ant, tauMax); % Autocorrelation
        meandStrct.acAnt{tr,1} = [trial acCurr];
        antCross = crossFun(ant, 'cc'); % #of crosses
        meandStrct.crossesAnt{tr,1} = [trial antCross];
%         meandStrct.mDispAnt{tr,1} = [trial meanDispFun(ant)]; % dist from nest
        meandStrct.mDispAnt{tr,1} = [ant.id(1), sum(ant.disp)/meandStrct.trackMeta{tr,1}.trackLength];

        % Sim from raw ant
        sim = trackMetrics(MCscrambleFun(ant, nrSims, nrBins),params,'ismm'); % Making sims
        idAnt = table(repmat(acCurr.id,nrSims,1),'variablenames',{'idAnt'});
        [~,acCurr] = turnAutocorrFun(sim, tauMax);
        meandStrct.acSim{tr,1} = [repmat(trial,nrSims,1) acCurr idAnt];
        simCross = crossFun(sim, 'cc');
        meandStrct.crossesSim{tr,1} = [repmat([trial idAnt(1,1)],height(simCross),1) simCross]; % #of crosses
%         meandStrct.mDispSim{tr,1} = [repmat(trial,nrSims,1) meanDispFun(sim) idAnt];
        meandStrct.mDispSim{tr,1} = [repmat(trial,nrSims,1) unique(sim.id),...
            accumarray(sim.id,sim.disp)./meandStrct.trackMeta{tr,1}.trackLength idAnt];
        meanToc = (toc/tr)/60;
    end
    close(wBar)
    meanderData = structfun(@(n) vertcat(n{:}),meandStrct,'Un',0); % All output

    % Saving
    save([meanderDirName slash 'meanderData_' vidName(1:end-1)],'meanderData','-v7.3');
    save([meanderDirName slash 'sumStats_' vidName(1:end-1)],'sumStats');
end
