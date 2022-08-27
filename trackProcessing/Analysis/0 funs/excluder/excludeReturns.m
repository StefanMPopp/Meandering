function outTab = excludeReturns(inTab,rule)
% Excludes parts of the track after the farthes displacement from the
% origin
% y, n

% Inputs: wallIn: input table, must not be by ID at this point
%         rule: 'points', 'tracks', 'after1st' (see comments below)
% Output: table not by ID of all tracks w/o wall following

varNames = inTab.Properties.VariableNames;
dispColNr = find(cellfun(@(n) strcmp(n,'disp'),varNames));

if rule == "nay" % No exclusion
    outTab = inTab;
    
elseif rule == "yay" % All points after farthest point excluded
    matC = trackByIDFun(table2array(inTab));
    outC = cell(size(matC));
    for tr = 1:size(matC,1)
        [~,retPtInd] = max(matC{tr,1}(:,dispColNr));
        outC{tr,1} = matC{tr,1}(1:retPtInd,:); % 1:returnPoint
    end
    outTab = array2table(cell2mat(outC),'VariableNames',varNames);
end
