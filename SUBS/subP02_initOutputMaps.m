function map = subP02_initOutputMaps(DD,window)
     %%
    [map] = MakeMaps(DD,window);   
    %% find respective index for all grid points of input map
    map.idx = main(DD,window,map);
    %% save map
    save([DD.path.root,'protoMaps.mat'],'-struct','map'	)  
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this function finds for every index of the original input geometry its
% respective index in the output map (for plots).
function idx = main(DD,inMap,outMap)
    
    deg2elev = @(lat) deg2rad(wrapTo180(lat));
        
    azi      = reshape(deg2rad(inMap.lon),[],1)';
    elev     = reshape(deg2elev(inMap.lat),[],1)';  
    [x,y,z]  = sph2cart(azi,elev,1);
    qazi     = deg2rad(outMap.lon(:));
    qelev    = deg2elev(outMap.lat(:));
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
function [map] = MakeMaps(DD,window)
    %% init output map dim
    geo = window.geo;
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
