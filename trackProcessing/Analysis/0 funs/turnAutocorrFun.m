function varargout = turnAutocorrFun(in, tauMax)
% Calculates autocorrelations from tracks
% Input: table of tracks
% Output: struct of 1) table of autocorr. value (rho) by timelag (tau)
%         2) table of 1st & second time autocorr=0, rho & tau of minimum
%           (most negative autocorr)

% Making the turnAutocorr table
ids = unique(in.id);
rho = cell(size(ids));
for tr = 1:length(ids)
    track = in(in.id==ids(tr),:);
    a = deg2rad(track.alpha(3:end-1));
    rho{tr,1} = table('size',[tauMax,2],'VariableTypes',{'single','single'},'variablenames',{'id','rho'});
    for tau = 1:tauMax % rho in 2nd col
        [rho{tr,1}.rho(tau),~] = circ_corrcc(a(1:end-tau-1), a(1+tau:end-1));
    end
    rho{tr,1}.id = repmat(ids(tr),tauMax,1); % ID in 1st col
    rho{tr,1}.tau = (1:tauMax)';
end
turnAutocorr = struct;
rhoTau = vertcat(rho{:});

% turnAutocorr Summary metrics
turnAutocorrMetr = struct('zerocross1',NaN(size(ids)),'zerocross2',NaN(size(ids)),...
                'id',NaN(size(ids)),'minRho',NaN(size(ids)),'minTau',NaN(size(ids)));

for tr = 1:length(ids)
    rho = rhoTau.rho(rhoTau.id == ids(tr));
    zeroCrosses = find(diff(rho >= 0),2);
    turnAutocorrMetr(tr,1).id = ids(tr);
    if ~isempty(zeroCrosses)
        turnAutocorrMetr(tr,1).zerocross1 = zeroCrosses(1);
        if length(zeroCrosses)>1
            turnAutocorrMetr(tr,1).zerocross2 = zeroCrosses(2);
        else
            turnAutocorrMetr(tr,1).zerocross2 = NaN;
        end
    else
        turnAutocorrMetr(tr,1).zerocross1 = NaN;
        turnAutocorrMetr(tr,1).zerocross2 = NaN;
    end
    [turnAutocorrMetr(tr,1).minRho, turnAutocorrMetr(tr,1).minTau] = min(rho);
end

if nargout == 1 % 1 output = raw rho & metrics written to 1 struct
    turnAutocorr.rhoTau = rhoTau;
    turnAutocorr.metr = struct2table(turnAutocorrMetr);
    varargout{1} = turnAutocorr;
else % 2 outputs = rhoTau may not be wanted (large table)
    varargout{1} = rhoTau;
    varargout{2} = struct2table(turnAutocorrMetr);
end
