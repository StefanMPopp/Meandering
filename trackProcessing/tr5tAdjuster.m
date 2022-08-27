% Manual syncing of individual tracks: click the one to be moved first
indX = find(joined(:,1) == cursor_info(2).Position(1,1));
indY = find(joined(:,2) == cursor_info(2).Position(1,2));
indZ = find(joined(:,3) == cursor_info(2).Position(1,3));
ind = intersect(intersect(indX,indY),indZ);
id = joined(ind,4);
dt = cursor_info(2).Position(3) - cursor_info(1).Position(3);

joined(joined(:,4)==id,3) = joined(joined(:,4)==id,3) - dt;

clear cursor_info
%%
cursor_info = cursor_info1; clear cursor_info1
%%
cursor_info = cursor_info2; clear cursor_info2
%%
cursor_info = cursor_info3; clear cursor_info3
%%
cursor_info = cursor_info4; clear cursor_info4

%% X, Y adjuster
indX = find(joined(:,1) == cursor_info(2).Position(1,1));
indY = find(joined(:,2) == cursor_info(2).Position(1,2));
indZ = find(joined(:,3) == cursor_info(2).Position(1,3));
ind = intersect(intersect(indX,indY),indZ);
id = joined(ind,4);
dx = cursor_info(2).Position(1) - cursor_info(1).Position(1);
dy = cursor_info(2).Position(2) - cursor_info(1).Position(2);

joined(joined(:,4)==id,1) = joined(joined(:,4)==id,1) - dx;
joined(joined(:,4)==id,2) = joined(joined(:,4)==id,2) - dy;
clear cursor_info
