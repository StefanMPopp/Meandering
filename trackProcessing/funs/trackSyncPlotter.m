function syncPlot = trackSyncPlotter(NEraw, NWraw, SEraw, SWraw, params)
% Plot to get sync info in the form of cursor_infos
NEflip = table2array(NEraw);
NWflip = table2array(NWraw);
SEraw = table2array(SEraw);
SWraw = table2array(SWraw);

NEflip = NEflip(NEflip(:,3)>300000,:); % only plotting end of trial
NWflip = NWflip(NWflip(:,3)>300000,:);
SEraw = SEraw(SEraw(:,3)>300000,:);
SWraw = SWraw(SWraw(:,3)>300000,:);

% Recreating stitch function's rotating + shifting
SEflip = [1920 + (1920 - SEraw(:,1)), 1080 + (1080 - SEraw(:,2)), SEraw(:,3:4)];
SWflip = [1920 + (1920 - SWraw(:,1)), 1080 + (1080 - SWraw(:,2)), SWraw(:,3:4)];
NEshift = NEflip;
NWshift = NWflip;
SEshift = SEflip;
SWshift = SWflip;

NEshift(:,1) = NEflip(:,1)+params.shiftNEX;
NEshift(:,2) = NEflip(:,2)+params.shiftNEY;
NWshift(:,1) = NWflip(:,1)+params.shiftNWX;
NWshift(:,2) = NWflip(:,2)+params.shiftNWY;
SEshift(:,1) = SEflip(:,1)+params.shiftSEX;
SEshift(:,2) = SEflip(:,2)+params.shiftSEY;
SWshift(:,1) = SWflip(:,1)+params.shiftSWX;
SWshift(:,2) = SWflip(:,2)+params.shiftSWY;

% Cutting out just the center where all cams overlap, for quick plotting
NEcen = NEshift(NEshift(:,1) > 2500,:);
NE = NEcen(NEcen(:,2) > 1600,:);
NWcen = NWshift(NWshift(:,1) > 2500,:);
NW = NWcen(NWcen(:,2) < 2400,:);
SEcen = SEshift(SEshift(:,1) < 3500,:);
SE = SEcen(SEcen(:,2) > 1600,:);
SWcen = SWshift(SWshift(:,1) < 3500,:);
SW = SWcen(SWcen(:,2) < 2400,:);

syncPlot = figure;
hold on
scatter3(NE(:,1),NE(:,2),NE(:,3),1)
scatter3(NW(:,1),NW(:,2),NW(:,3),1)
scatter3(SE(:,1),SE(:,2),SE(:,3),1)
scatter3(SW(:,1),SW(:,2),SW(:,3),1)
hold off
zlim([300000 305000])
view(90, 10)
legend('NE', 'NW', 'SE', 'SW')
title(['\color[rgb]{0, 0.4470, 0.7410}blue -> \color[rgb]{0.8500, 0.3250, 0.0980}red -> '...
    '\color[rgb]{0.9290, 0.6940, 0.1250}yellow -> \color[rgb]{0.4940, 0.1840, 0.5560}purple'...
    '\color{black}. Save data cursor, close plot & run next section.'])
