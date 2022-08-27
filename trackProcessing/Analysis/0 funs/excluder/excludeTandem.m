function tandemOut = excludeTandem(tandemIn,rule)
% Excludes or includes tandem runs depending on rule in SAWparams &
% assignments in metrics, coming from the tandem ID script.
if rule == "all"
    tandemOut = tandemIn;
elseif rule == "tandemOnly"
    tandemOut = tandemIn(tandemIn.tandem == 1,:);
elseif rule == "nonTandemOnly"
    tandemOut = tandemIn(tandemIn.tandem == 0,:);
end