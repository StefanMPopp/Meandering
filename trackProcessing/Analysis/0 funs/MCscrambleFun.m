function simOut = MCscrambleFun(MCin, nrSims, nrBins)
% Creates simulated tracks based on alpha & s of 1 empirical track.
% Shuffling a&s of points around while keeping 1st-order correlation
%
% Inputs: track, must be table w/ headers
%         nrSims: max nr of simulations,
%         nrBins: nr of bins in which the alpha data is divided
% Output: Table of all simulations of this track

nullModel = 'CRWas'; % To test simpler null-models, make this an input argument

MCsimC = cell(nrSims,1);
for sim = 1:nrSims
    % === Inputs === %
    stepMaxNr = size(MCin,1); % time the simulated track runs in total
    sIn = MCin.s(2:end); % step-lengths pre
    sIn(isnan(sIn)) = 0; % problem if NaN interpolated parts
    alphaIn = MCin.alpha(2:end-1); % excluding 1st & last point (no angles)
    alphaIn(isnan(alphaIn)) = 0; % WARNING: turns gaps into straight segments!
    % ============== %
    switch nullModel
        case 'BW' % s drawn from emprical, alpha from uniform distribution
            s = sIn(randperm(length(sIn)),1); % Sampling from empirical
            alpha = [rand(length(alphaIn),1).*360-180; 0];
        case 'CRW' % s & a drawn independently
            s = sIn(randperm(length(sIn)),1); % Sampling from empirical
            alpha = [alphaIn(randperm(length(alphaIn)),1); 0]; % Sampling from empirical
        case 'CRWa'  % s & a drawn in pairs (avoiding sharp fast turns)
            randList = randperm(length(sIn));
            s = sIn(randList,1);
            randListAlpha = randperm(length(sIn)-1);
            alpha = [alphaIn(randListAlpha,1); 0];
        case 'CRWas' % s drawn from set of s assoc. w/ bin of s(t-1), a assoc. w/ s.
            % Making bins
            alphaNextBin = cell(nrBins,1); % Preallocating bin from which the next step will be drawn
            alphaCurr = alphaIn(1:end-1); % vector of a(t)
            alphaNext = alphaIn(2:end); % vector of a(t+1)
            binsAll = quantileranks([alphaCurr;alphaNext(end)],nrBins); % vector of bin# for each pt
            bins = binsAll(1:end-1); % Last pt only in binsAll to continue loop if drawn below
            for bin = 1:nrBins % a(t+1) for every s bin
                alphaNextBin{bin,1} = alphaNext(bins==bin); % Cell# = curr pt, content of cell# = set of pot. next pt
            end

            % Draw alpha(t+1) given which bin alpha(t) is in
            alpha = alphaCurr(1); % 1st alpha taken from real track to initialize
            for t = 2:stepMaxNr-1
                alphaBinPre = binsAll([alphaCurr;alphaNext(end)]==alpha(t-1));
                alphaBinCurr = alphaBinPre(1); % bin# of alphaCurr
                drawInd = randi(length(alphaNextBin{alphaBinCurr,1})); % Index of drawn point in bin
                alpha(t,1) = alphaNextBin{alphaBinCurr,1}(drawInd);
            end
            s = repmat(mean(sIn),stepMaxNr-1,1); % Slap mean step length on
    end
    
    theta = cumsum(alpha); % Initial heading theta=0 (=right (south))
    dx = [0; s.*cosd(theta)]; % Initial position [0,0]
    dy = [0; s.*sind(theta)];
    currSim.x = cumsum(dx);
    currSim.y = cumsum(dy);
    currSim.t = MCin.t;
    currSim.id = MCin.id.*10000+sim;
    MCsimC{sim,1} = struct2table(currSim); % ID = 10,001; 10,002...; 11,001,...
end
simOut = vertcat(MCsimC{:});
