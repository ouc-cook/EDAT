%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 08-Apr-2014 19:50:46
% Computer: GLNX86
% Matlab: 7.9
% Author: NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S06_init_output_maps
    %% init
    DD = initialise([],mfilename);
    DD.map.window = getfieldload(DD.path.windowFile,'window');
    %     load DD
    %%
    [map] = MakeMaps(DD);
    %%
    DD.threads.num = init_threads(DD.threads.num);
    %% find respective index for all grid points of input map
    map.idx = main(DD,map);
    %% save map
    save([DD.path.root,'protoMaps.mat'],'-struct','map'	)
    %% update infofile
    % 	conclude(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function idx = main(DD,out)
    %% get input example lon/lat
    deg2elev = @(lat) deg2rad(wrapTo180(lat));
    
    
    azi      = reshape(deg2rad(DD.map.window.lon),[],1)';
    elev     = reshape(deg2elev(DD.map.window.lat),[],1)';
    %     azi      = deg2rad(extractdeepfield(read_fields(DD,1,'cuts'),'fields.lon'));
    %     elev     = deg2elev(extractdeepfield(read_fields(DD,1,'cuts'),'fields.lat'));
    [x,y,z]  = sph2cart(azi,elev,1);
    qazi     = deg2rad(out.lon(:));
    qelev    = deg2elev(out.lat(:));
    [qx,qy,qz] = sph2cart(qazi,qelev,1);
    inxyz    = [x',y',z'];
    outxyz   = [qx,qy,qz];
    JJ       = thread_distro(DD.threads.num,numel(azi));
    
    spmd(DD.threads.num)
        idx = dsearchn(outxyz,inxyz(JJ(labindex,1):JJ(labindex,2),:));
        idx = gcat(idx,1,1);
    end
    
    idx = idx{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [map] = MakeMaps(DD)
    %% init output map dim
    geo = DD.map.window.geo;
    bs  = DD.map.out.binSize;
    %%
    map.dim.x = round((geo.east - geo.west +1)/bs);
    map.dim.x = map.dim.x - mod(map.dim.x,360/bs);
    %%
    map.dim.y = round((geo.north - geo.south +1)/bs);
    %%
    rlvec   = @(a,len,inc) round(a*inc)/inc:inc:inc*len ;
    xvec    = rlvec(geo.west,geo.east,bs);
    yvec    = rlvec(geo.south,geo.north,bs);
    %%
    [map.lon,map.lat] = meshgrid(xvec,yvec);
    map.proto.nan     = nan(size(map.lon));
    map.proto.zeros   = zeros(size(map.lon));
    map.dim.numel     = map.dim.y * map.dim.x;
    map.inc.x         = diff(map.lon(1,[1,2]));
    map.inc.y         = diff(map.lat([1,2],1));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
