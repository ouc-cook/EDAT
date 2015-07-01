%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prepare ssh data
% reads user input from input_vars.m and map_vars.m
function S00b_prep_data
    %% set up
    [DD]=set_up;
    %% spmd
    main(DD);   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    if DD.debugmode
        spmd_body(DD);
    else
        spmd(DD.threads.num)
            spmd_body(DD);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD]=set_up
    %% init dependencies
    addpath(genpath('./'))
    %% get user input
    DD = initialise('raw',mfilename);
    %% get sample window
    file=SampleFile(DD);
    [window]=GetWindow3(file,DD.map.in);   
    %% read geo info
    for kk={'lat','lon'}
        keys.(kk{1})=DD.map.in.keys.(kk{1});
    end
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(DD)
    %% distro days to threads
    [II]=SetThreadVar(DD);
    %% loop over files
    S00b_main(DD,II);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function file=SampleFile(DD)
    dir_in =DD.path.raw;
    pattern_in=DD.map.in.fname;
    readable=false;
    sample_time=DD.time.from.str;
    while ~readable
        file=[dir_in.name, strrep(pattern_in, 'yyyymmdd',sample_time)];
        if ~exist(file,'file')
            sample_time=datestr(DD.time.from.num + DD.time.delta_t,'yyyymmdd');
            continue
        end
        readable=true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dy,dx]=dydx(lat,lon)
    betweenNodesX = @(lalo) (lalo(:,2:end) + lalo(:,1:end-1))/2;
    betweenNodesY = @(lalo) (lalo(2:end,:) + lalo(1:end-1,:))/2;
    copyBndryX    = @(X) X(:,[1 1:end end]);
    copyBndryY    = @(Y) Y([1 1:end end],:);
    deg2m         = @(degs) deg2km(degs) * 1e3; 
    %% y
    dy=deg2m(abs(diff(lat,1,1)));
    %% x
    dlon=abs(diff(lon,1,2));
    dlon(dlon>180) = abs(dlon(dlon>180) - 360);
    dx=deg2m(dlon) .* cosd(betweenNodesX(lat));
    %% mean back to nodes
    dx=copyBndryX(betweenNodesX(dx));    
    dy=copyBndryY(betweenNodesY(dy));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%