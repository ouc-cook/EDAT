function S00_prep_raw_data
    %% set up meta-data/info file "DD.mat"
    DD = set_up;
    %% main
%     main(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    for cc=1 : files;
        %% get data
        file = GetCurrentFile(DD);
        %% cut data
        CUT  = CutMap(file,DD);
        %% write data
        WriteFileOut(file.out,CUT);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD] = set_up
    %% init dependencies
    addpath(genpath('./'))
    %% get user input
    DD = initialise('raw');  
    %% build one file each for lat/lon
    constructGeoFiles(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function constructGeoFiles
   %% get sample window
    file = SampleFile(DD);
    [window] = GetWindow3(file,DD.map.in);
    %% read geo info
    keys.lat = DD.map.in.keys.lat;
    keys.lon = DD.map.in.keys.lon;
    [raw_fields,~]=GetFields(file,keys);
    %% cut
    [window]=mergeStruct2(window,cutSlice(raw_fields,window));
    %% get distance fields
    [window.dy,window.dx]=dydx(window.lat,window.lon);
    %% save
    DD.map.window=window;
    DD.map.windowFile = [DD.path.root 'window.mat'];
    save(DD.map.windowFile,'window');  
end

