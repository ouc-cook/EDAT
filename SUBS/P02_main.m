function meanMap = P02_main(DD,window)
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks);
    %%
    meanMap =  initMeanMaps(window);
    %%
    meanMap = buildMeanMaps(meanMap,txtFileName,DD.threads.num);
    %%
    meanMap.birthDeath = buildBirthDeathMaps(tracks);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BD = buildBirthDeathMaps(tracks)
    N = numel(tracks);
    BD.birth.lat = nan(N,1);
    BD.birth.lon = nan(N,1);
    BD.death.lat = nan(N,1);
    BD.death.lon = nan(N,1);
    for tt = 1:numel(tracks)
        bd = getfield(getfieldload(tracks(tt).fullname,'analyzed'),'birthdeath');
        BD.birth.lat(tt) = bd.birth.lat;
        BD.birth.lon(tt) = bd.birth.lon;
        BD.death.lat(tt) = bd.death.lat;
        BD.death.lon(tt) = bd.death.lon;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init output map dim
function map = initMeanMaps(window) % TODO make better
    geo = window.geo;
    %     bs  = DD.map.out.binSize;
    %%
    if round(geo.east - geo.west)==360
        xvec    = wrapTo360(1:1:360);
    else
        xvec    = wrapTo360(round(geo.west):1:round(geo.east));
    end
    yvec    = round(geo.south):1:round(geo.north);
    %%
    [map.lon,map.lat] = meshgrid(xvec,yvec);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = buildMeanMaps(meanMaps,txtFileName,threads)
    %% init
    [Y,X] = size(meanMaps.lat);
    
    %% read lat lon vectors
    lat = fscanf(fopen(txtFileName.lat, 'r'), '%f ');
    lon = wrapTo360(fscanf(fopen(txtFileName.lon, 'r'), '%f '));
    
%     sum(lat>35 & lat<40 & lon>65 & lon <75)
    
    
    %% find index in output geometry
    idxlin = binDownGlobalMap(lat,lon,meanMaps.lat,meanMaps.lon,threads);
    
    %% read parameters
    u     = fscanf(fopen(txtFileName.u, 'r'),     '%e ');
    v     = fscanf(fopen(txtFileName.v, 'r'),     '%e ');
    scale = fscanf(fopen(txtFileName.scale, 'r'), '%e ');
    
    %% sum over parameters for each grid cell
    meanMaps.u = meanMapOverIndexedBins(u,idxlin,Y,X,threads);
    meanMaps.v = meanMapOverIndexedBins(v,idxlin,Y,X,threads);
    meanMaps.scale = meanMapOverIndexedBins(scale,idxlin,Y,X,threads);
    
    %% calc angle
    uv               = meanMaps.u + 1i * meanMaps.v;
    meanMaps.absUV   = abs(uv) ;
    meanMaps.angleUV = reshape(wrapTo360(rad2deg(phase(uv(:)))),Y,X);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD)
    tracks = DD.path.tracks.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
    FN = {'lat','lon','u','v','scale'};
    for ii=1:numel(FN); fn = FN{ii};
        txtFileName.(fn) = [ txtdir fn '.txt' ];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeToTxtFiles(txtFileName,FN,tracks)
    %% open files    
    for ii=1:numel(FN); fn = FN{ii};
        system(sprintf('rm -f %s',txtFileName.(fn)));
        f.(fn) = fopen(txtFileName.(fn), 'w');
    end
    %% write parameters to respective files
    for tt=1:1:numel(tracks)
        fprintf('%d%%\n',round(100*tt/numel(tracks)));
        track = getfieldload(tracks(tt).fullname,'analyzed');
        fprintf(f.lat,'%3.3f ',track.daily.geo.lat );
        fprintf(f.lon,'%3.3f ',track.daily.geo.lon );
        fprintf(f.u,  '%1.3e ',track.daily.vel.u);
        fprintf(f.v,  '%1.3e ',track.daily.vel.v);
        fprintf(f.scale,  '%d ',track.daily.scale);
    end
    %% close files
    for ii=1:numel(FN); fn = FN{ii};
        fclose(f.(fn));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function buildNetCdfFromTxtFiles(FN,txtFileName)
%     return
%     % TODO
%     for ii=1:numel(FN); fn = FN{ii};
%         f.(fn) = fopen(txtFileName.(fn), 'r');
%     end
%     lat=fscanf(f.lat,'%f');
%     lon=fscanf(f.lon,'%f');
%     u=fscanf(f.u,'%f');
%     v=fscanf(f.v,'%f');
%     N=numel(a);
%     nccreate('bla.nc','lat',...
%         'Dimensions',{'x',1,'N',N},...
%         'Format','classic')
%     
%     nccreate('bla.nc','lon','Dimensions',{'x',1,'N',N})
%     nccreate('bla.nc','u','Dimensions',{'x',1,'N',N})
%     nccreate('bla.nc','v','Dimensions',{'x',1,'N',N})
%     
%     ncwrite('bla.nc','lat',lat')
%     ncwrite('bla.nc','lon',lon')
%     ncwrite('bla.nc','u',u')
%     ncwrite('bla.nc','v',v')
%     
% end