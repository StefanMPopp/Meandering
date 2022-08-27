function [NEraw, NWraw, SEraw, SWraw] = trackCatFunTrex(params)
% 1) Reads all .txt files by camera (& chunk)
% 2) Concatenates them
% 3) Makes t of ..2 increase to continue ..1 seamlessly & ID to not overlap
% 4) Switches columns 3&4 to get [x y t ID] format
% 5) Cuts off temporally last part of tracks, to remove experimenter noise
% Inputs: parameters of where .txt files are stored, time infos
% Outputs: .txts of concatenated raw tracks rdy to be stitched

% Unpack parameters
filedir = params.filedir;
vidName = params.nameVid;
tmax = table2array(params.framesChunkList);

% Load & Concatenate .txt files
for chunk = 1:10
    NEfiles{chunk} = dir(fullfile(filedir, strcat(vidName, 'NE', num2str(chunk,'%02d'), '*')));
    NWfiles{chunk} = dir(fullfile(filedir, strcat(vidName, 'NW', num2str(chunk,'%02d'), '*')));
    SEfiles{chunk} = dir(fullfile(filedir, strcat(vidName, 'SE', num2str(chunk,'%02d'), '*')));
    SWfiles{chunk} = dir(fullfile(filedir, strcat(vidName, 'SW', num2str(chunk,'%02d'), '*')));
end

warning('off') % Suppresses warning about how MATLAB changed the headers to make them compatible
for cam = 1:4
    switch cam
        case 1
            files = NEfiles;
        case 2
            files = NWfiles;
        case 3
            files = SEfiles;
        case 4
            files = SWfiles;
    end
    camRaw = table(0,0,0,0,'variablenames',...
            {'X_wcentroid_cm_','Y_wcentroid_cm_','frame','id'}); % Seed for appending
    for chunk = 1:10
        nfiles = length(files{chunk});
        for i = 1:nfiles
           currRaw = readtable(files{chunk}(i).name); % Cols: t x y miss
           if size(currRaw,2)>4; warning([files{chunk}(i).name ' has extra columns']); end
           try 
               currRaw(currRaw.frame>tmax(chunk+1),:) = []; % Deleting parts overlapping between chunks
               currRaw.frame = currRaw.frame + sum(tmax(1:chunk)) +1; % makes t of chunks go up
               currRaw = currRaw(currRaw.missing==0,[2 3 1]); % skips empty files
               currRaw.id = repmat(max(camRaw.id)+i,size(currRaw,1),1); % col5: id
               camRaw = [camRaw; currRaw];
           catch warning([files{chunk}(i).name ' is probably empty'])
           end
        end
    end
    camRaw(1,:) = []; % Deletes seed for appending
    camRaw.Properties.VariableNames = {'x' 'y' 't' 'id'}; % Renaming columns
    switch cam
        case 1
            NEraw = camRaw;
            disp('NE loaded')
        case 2
            NWraw = camRaw;
            disp('NW loaded')
        case 3
            SEraw = camRaw;
            disp('SE loaded')
        case 4
            SWraw = camRaw;
            disp('SW loaded')
    end
end
warning('on')
