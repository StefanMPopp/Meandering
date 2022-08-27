%% Load data or make them
% This script creates figures 1 & 2
% Rows: 1: example tracks, 2: ac plots, 3: turn angle histograms

% Operating system compatibility
if ispc; slash = '\'; else; slash = '/'; end
addpath(genpath('trackProcessing'))
addpath(genpath('non-ant_Data'))
plotPath = 'plots/Meander/'; % Where plots will be saved to
addpath(genpath(plotPath))
ftsz = {'fontsize',8};
dataSource = questdlg('Load supplied data or make it w/ code now?',...
                'Data source','Load supplied','Make now','Load supplied');

% Making data or loading it in
if strcmp(dataSource,'Load supplied')
    % Make plots from supplied data
    load(['non-ant_Data' slash 'allFigureData'])
else
    % Make data for plotting to check yourself
    load('HRM_T1_procParams.mat')

    % =================================================================== %
    % =========== Data for Left column: Cosmorhaphe (fossils) =========== %
    % =================================================================== %
    newWormTrack = questdlg('Load supplied worm data or create from image?',...
        'Worm data source','Load supplied','Make now','Load supplied');
    wormName = 'C_tremensSims'; % as printed in Sims et al 2014

    if newWormTrack % Making skeleton (= 1px tracks) of input image + sims of it
        % === Making track === %
        I = imread([wormName '.png']);
        Icomplement = imcomplement(I(:,:,1));
        BW = imbinarize(Icomplement);
        mat = bwskel(BW);
        [ycoo, xcoo] = find(mat);
        fig = figure;
        scatter(xcoo, ycoo, 2);
        title('Raw pixels, get c\_i of track start, then close plot and press a key') 
        while size(findobj(fig))>0
            pause %some input
        end

        % Sort pixels so that they form a continous track
        % Find neighbor pixels, starting with one that's assigned
        xRaw = zeros(size(mat,1),1);
        yRaw = zeros(size(mat,2),1);
        xRaw(1) = cursor_info.Position(2);
        yRaw(1) = cursor_info.Position(1);
        wBar = waitbar(0, 'Sorting pixels');
        numPix = sum(mat,'all');
        for i = 1:numPix
            if mat(xRaw(i)-1, yRaw(i)) % left
                xRaw(i+1) = xRaw(i)-1;
                yRaw(i+1) = yRaw(i);
            elseif mat(xRaw(i)+1, yRaw(i)) % right
                xRaw(i+1) = xRaw(i)+1;
                yRaw(i+1) = yRaw(i);
            elseif mat(xRaw(i), yRaw(i)-1) % below
                xRaw(i+1) = xRaw(i);
                yRaw(i+1) = yRaw(i)-1;
            elseif mat(xRaw(i), yRaw(i)+1) % above
                xRaw(i+1) = xRaw(i);
                yRaw(i+1) = yRaw(i)+1;
            elseif mat(xRaw(i)-1, yRaw(i)-1) % left below
                xRaw(i+1) = xRaw(i)-1;
                yRaw(i+1) = yRaw(i)-1;
            elseif mat(xRaw(i)+1, yRaw(i)-1) % right below
                xRaw(i+1) = xRaw(i)+1;
                yRaw(i+1) = yRaw(i)-1;
            elseif mat(xRaw(i)-1, yRaw(i)+1) % left above
                xRaw(i+1) = xRaw(i)-1;
                yRaw(i+1) = yRaw(i)+1;
            elseif mat(xRaw(i)+1, yRaw(i)+1) % right above
                xRaw(i+1) = xRaw(i)+1;
                yRaw(i+1) = yRaw(i)+1;
            end
            mat(xRaw(i),yRaw(i)) = 0; % Current pixel becomes 0
            waitbar(i/numPix, wBar, 'Sorting pixels')
        end
        close(wBar)
        figure
        plot(xRaw,yRaw); title('Connected track. Close after answering Q')
        contin = questdlg('Does this look ok?','Track Ok?','Ya','No','Ya');
        uiwait
        if strcmp(contin,'No'); error('Rerun this section to try again'); end

        % Smooth
        % Thin the track out, to get a reasonable scale
        xThin = xRaw(1:10:end);
        yThin = yRaw(1:10:end);
        x = smooth(1:length(xThin), xThin); % LOWESS not necessary
        y = smooth(1:length(yThin), yThin);
        t = (1:length(x))';
        id = ones(size(x));
        wormParams.pxpermm = 100; % 20ct = 22.5mm, px taken from coords above
        wormParams.fps = 1;
        worm = trackMetrics([x y t id], wormParams);

        % === Making simulations === %
        nrSims = 99;
        wormSim = trackMetrics(MCscrambleFun(worm,nrSims,10),params,'inMM');

        writetable(worm,['non-ant_Data/' wormName 'Track']);
        writetable(wormSim,['non-ant_Data/' wormName 'Sim']);
    else % Read in worm data as it appears in the paper
        worm = readtable(['non-ant_Data' slash wormName 'Track']);
        wormSim = readtable(['non-ant_Data' slash wormName 'Sim']);
        nrSims = numel(unique(wormSim.id))/numel(unique(worm.id));
    end

    % === Turn autocorrelation of both sets of tracks === %
    tauMax = 50; % Max lag calculated
    acWorm = turnAutocorrFun(worm,tauMax);
    acWormSim = turnAutocorrFun(wormSim,tauMax);

    % Making 95% sim bands
    % Converting #of points to [mm]
    acWormSimBandRaw = sortrows(acWormSim.rhoTau,[3,2]);
    acWormSim.rhoTau.tau = acWormSim.rhoTau.tau .* nanmean(wormSim.s);
    % 95% Confidence intervals from sim data
    acWormSimBand.low = acWormSimBandRaw(round(nrSims/20):nrSims:height(acWormSim.rhoTau),:);
    acWormSimBand.high = acWormSimBandRaw((nrSims-round(nrSims/20)):nrSims:(height(acWormSim.rhoTau)),:);
    acWormSimBandFill = [[acWormSimBand.low.tau; flip(acWormSimBand.low.tau)]'; [acWormSimBand.low.rho; flip(acWormSimBand.high.rho)]'];


    % =================================================================== %
    % ============ Data for Right column: Temnothorax (ants) ============ %
    % =================================================================== %
    % Importing data & setting parameters
    trackPath = 'clean_724000_meander';
    addpath(genpath(trackPath))
    ants = readtable([trackPath slash 'HRM_T1_ants.txt']);
    id = 37; % Example track
    ant = ants(ants.id==id,:); % Used for all example plots

    % === Making simulations === %
    newAntSim = 0;
    if newAntSim == 1
        nrSims = 99; % #of simulations per empirical track
        nrBins = 10; % #of bins of step length & turn angle for simulations
        sim = trackMetrics(MCscrambleFun(ant, nrSims, nrBins),params,'alreadyInMM');
        writetable(sim,['non-ant_Data/ant' id 'sim']);
    else
        sim = readtable(['non-ant_Data/ant' id 'sim']);
    end

    % === Autocorrelation Calculations === %
    acAnt = turnAutocorrFun(ant, tauMax);
    acSim = turnAutocorrFun(sim, tauMax);
    % Converting tau from [#of points] to [mm]
    acAnt.rhoTau.tau = acAnt.rhoTau.tau .* nanmean(ant.s);
    acSim.rhoTau.tau = acSim.rhoTau.tau .* nanmean(sim.s);
    % 95% Confidence intervals from sim data
    acSimBandRaw = sortrows(acSim.rhoTau,[3,2]);
    acSimBand.low = acSimBandRaw(round(nrSims/20):nrSims:height(acSim.rhoTau),:);
    acSimBand.high = acSimBandRaw((nrSims-round(nrSims/20)):nrSims:(height(acSim.rhoTau)),:);
    acSimBandFill = [[acSimBand.low.tau; flip(acSimBand.low.tau)]'; [acSimBand.low.rho; flip(acSimBand.high.rho)]'];

    % === Picking out simulation examples === %
    idAntSim = min(sim.id);
    idWormSim = min(wormSim.id);
    wormSimTrack = wormSim(wormSim.id==idWormSim,:);
    antSimTrack = sim(sim.id==idAntSim,:);
    wormSimAcEx = acWormSim.rhoTau(acWormSim.rhoTau.id==idWormSim,:);
    antSimAcEx = acSim.rhoTau(acSim.rhoTau.id==id*1000+1,:);

    % === Saving all data created in this script in a .mat workspace === %
    save('non-ant_Data/allFigureData')
end

%% Creating the Introduction panel figure of fossil & ant examples (Fig. 1)
figure('units','centimeters','Outerposition',[.2 1 18 22])
f1 = tiledlayout(3,2,'padding','tight','TileSpacing','tight');
f1.Units = 'inches';
f1.OuterPosition = [0.25 0.25 6.5 6.5]; % x,y origin, width, height
textBoxFont = {'FontSize',8,'FontWeight','bold','LineStyle','none'};

% Track Cosmorhaphe
nexttile
plot(worm.x,worm.y,'k','linewidth',1)
hold on
plot(wormSimTrack.x,wormSimTrack.y,'linewidth',1)
hold off
xlabel('x [mm]'); ylabel('y [mm]'); title('{\it Cosmorhaphe tremens}');
axis equal
leg = legend({'Fossil' 'Simulation'},'location','southeast');
leg.ItemTokenSize = [10;18]; % Shortens lines in legend
annotation('textbox',[.1 .95 .2 0],'String','A',textBoxFont{:});

% Tracks of ant + simulation
nexttile
ant.x = ant.x-min(ant.x); ant.y = ant.y-min(ant.y);
plot(ant.x,ant.y,'k','linewidth',1)
hold on
plot(antSimTrack.x,antSimTrack.y,'linewidth',1)
hold off
axis('equal')
xlabel('x [mm]')
leg = legend({'Ant' 'SimulAnt'});
leg.ItemTokenSize = [10;18]; % Shortens lines in legend
xlim([-120 1400]); ylim([-280 700]); title('{\it Temnothorax rugatulus}')
annotation('textbox',[.6 .95 .2 0],'String','B',textBoxFont{:});

% Turn autocorrelation Cosmo
nexttile
w = plot(acWorm.rhoTau.tau, acWorm.rhoTau.rho,'k','linewidth',1);
hold on
plot(wormSimAcEx.rho,'color',[0.8500 0.3250 0.0980],'linewidth',1) % Of the first (shown) track
s = fill(acWormSimBandFill(1,:),acWormSimBandFill(2,:),'r');
s.FaceColor = [1 .67 .5];
s.EdgeColor = 'none';
plot([0,tauMax],[0 0], '--', 'color',[.5 .5 .5])
hold off
xlabel('Distance between points \delta [mm]'); ylabel('Autocorrelation strength \rho')
ylim([-0.2 0.45])
leg = legend({'Fossil' 'Simulation' '95% interval'});
leg.ItemTokenSize = [10;18]; % Shortens lines in legend
uistack(s,'bottom'); uistack(w,'top')
annotation('textbox',[.1 .64 .2 0],'String','C',textBoxFont{:});

% Turn autocorrelation ant
nexttile
a = plot(acAnt.rhoTau.tau,acAnt.rhoTau.rho,'k','linewidth',1);
hold on
plot(antSimAcEx.tau,antSimAcEx.rho,'color',[0.8500 0.3250 0.0980],'linewidth',1)
s = fill(acSimBandFill(1,:),acSimBandFill(2,:),'red');
s.FaceColor = [1 .67 .5];
s.EdgeColor = 'none';
uistack(s,'bottom'); uistack(a,'top')
plot([0 100],[0 0],'--','color',[.5 .5 .5]) % Dashed line @ 0
hold off
xlabel('Distance between points \delta [mm]')
xlim([0 103])
leg = legend({'95% interval' 'SimulAnts' 'Ant'});
leg.ItemTokenSize = [10;18]; % Shortens lines in legend
annotation('textbox',[.6 .64 .2 0],'String','D',textBoxFont{:});


% Turn angle histogram Cosmo
nexttile
histogram(worm.alpha,'facecolor',[0.8500 0.3250 0.0980]./2)
xlabel('Turn angle [°]'); ylabel('Number of angles');
leg = legend({'Fossil & \newlineSimulations'});
leg.ItemTokenSize = [10;18]; % Shortens lines in legend
annotation('textbox',[.1 .3 .2 0],'String','E',textBoxFont{:});

% Turn angle histogram ant
nexttile
histogram(ant.alpha,'facecolor',[0.8500 0.3250 0.0980]./2)
xlabel('Turn angle [°]')
leg = legend({'Ant & \newlineSimulAnts'});
leg.ItemTokenSize = [10;18]; % Shortens lines in legend
annotation('textbox',[.6 .3 .2 0],'String','F',textBoxFont{:});

% % Saving
% exportgraphics(f1,[plotPath 'f1Intro.tiff'],'Resolution',1000)
% exportgraphics(f1,[plotPath 'f1Intro.pdf'],'Resolution',1000)

%% Figure 'allTracks' (Fig. 2)
% All included tracks of one trial (T1) in the arena, colored by ID
% Loading tracks if necessary
if ~exist('ants','var')
    trackPath = 'clean_724000_meander';
    addpath(genpath(trackPath))
    ants = readtable([trackPath '/HRM_T1_ants.txt']);
    id = 37; % Example track
    ant = ants(ants.id==id,:); % Example track from Fig. 1
    ids = unique(ants.id);
end

% =============================== All tracks ============================ %
f2 = figure('units','centimeters','Outerposition',[.2 1 18 10]);
axes('Position',[.05 0.15 0.6450 0.820])
hold on
for tr = 1:length(ids)
    currTr = ants(ants.id==ids(tr),:);
    plot(currTr.x,currTr.y,'linewidth',.75)
end
xlabel('x [mm]',ftsz{:}); ylabel('y [mm]',ftsz{:}); axis equal

% ========================== Zoom of example track ====================== %
zoomTr = ant(1650:1734,:); % ToDo: set to a pretty track segment
zoom = struct;
zoom.xmin = min(zoomTr.x);
zoom.xmax = max(zoomTr.x);
zoom.ymin = min(zoomTr.y);
zoom.ymax = max(zoomTr.y);
% Box in main plot
rectangle('position',[zoom.xmin zoom.ymin zoom.xmax-zoom.xmin zoom.ymax-zoom.ymin],'LineWidth',1)
annotation('line',[0.351 0.722],[0.385 0.201],'color','k','LineWidth',1); % Lower line
annotation('line',[0.351 0.722],[0.418 0.898],'color','k','LineWidth',1); % Upper line

hold off
axes('YAxisLocation','right','Position',[.7 .2 .3 .7]) % Y on right doesn't work
box on
plot(zoomTr.x,zoomTr.y,'k','linewidth',1)
xlim([min(zoomTr.x) max(zoomTr.x)])
ylim([min(zoomTr.y) max(zoomTr.y)])
xlabel('x [mm]',ftsz{:}); axis equal

% =============================== Ant image ============================= %

axes('pos',[.8 .51 .07 .065])
temnoPic = imrotate(imread('temno.png'),20);
alphaMask = temnoPic(:,:,1)>0 & temnoPic(:,:,2)>0 & temnoPic(:,:,3)>0;
h = imshow(temnoPic);
set(h, 'AlphaData', alphaMask)

%% Saving figure 2
exportgraphics(f2,[plotPath 'f2Tracks.tiff'],'Resolution',1000)
exportgraphics(f2,[plotPath 'f2Tracks.pdf'],'Resolution',1000)
