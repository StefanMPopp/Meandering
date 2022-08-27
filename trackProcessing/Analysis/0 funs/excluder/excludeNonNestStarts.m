function nestOut = excludeNonNestStarts(noNestIn,rule)
% Excludes tracks which do not start near the nest entrance
if rule > 0
    sorted = sortrows(noNestIn,[4 3]); % Just to be sure
    [ids,ind] = unique(sorted.id); % Picks 1st point of each track
    nestIDs = ids(sorted.nestDisp(ind)<rule); % Those ids close to nest
    nestOut = sorted(ismember(sorted.id,nestIDs),:); % Only keeping the above
else
    nestOut = noNestIn;
end