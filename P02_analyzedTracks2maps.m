function P02_analyzedTracks2maps
   TODO
    DD = initialise;
    window = getfieldload(DD.path.windowFile,'window');
    main(DD,window);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,window)
    %%
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    %     writeToTxtFiles(txtFileName,FN,tracks);
    %%  TODO
    %     buildNetCdfFromTxtFiles(FN,txtFileName)
    %%
    %     meanMap =  initMeanMaps(DD,window);
    %%
    %     meanMap = buildMeanMaps(meanMap,FN,txtFileName); %#ok<NASGU>
    %%
    meanMap.birthDeath = buildBirthDeathMaps(tracks);
    %%
    save(DD.path.analyzed,'meanMaps.mat','meanMap');
    
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
function map = initMeanMaps(DD,window)
    geo = window.geo;
    bs  = DD.map.out.binSize;
    %%
    rlvec   = @(a,len,inc) round(a*inc)/inc:inc:inc*len ;
    xvec    = rlvec(geo.west,geo.east,bs);
    yvec    = rlvec(geo.south,geo.north,bs);
    %%
    [map.lon,map.lat] = meshgrid(xvec,yvec);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buildNetCdfFromTxtFiles(FN,txtFileName)
    return
    % TODO
    for ii=1:numel(FN); fn = FN{ii};
        f.(fn) = fopen(txtFileName.(fn), 'r');
    end
    lat=fscanf(f.lat,'%f');
    lon=fscanf(f.lon,'%f');
    u=fscanf(f.u,'%f');
    v=fscanf(f.v,'%f');
    N=numel(a);
    nccreate('bla.nc','lat',...
        'Dimensions',{'x',1,'N',N},...
        'Format','classic')
    
    nccreate('bla.nc','lon','Dimensions',{'x',1,'N',N})
    nccreate('bla.nc','u','Dimensions',{'x',1,'N',N})
    nccreate('bla.nc','v','Dimensions',{'x',1,'N',N})
    
    ncwrite('bla.nc','lat',lat')
    ncwrite('bla.nc','lon',lon')
    ncwrite('bla.nc','u',u')
    ncwrite('bla.nc','v',v')
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = buildMeanMaps(meanMaps,FN,txtFileName)
    %% init
    [Y,X] = size(meanMaps.lat);
    meanMaps.count = zeros(Y,X);
    meanMaps.u     = zeros(Y,X);
    meanMaps.v     = zeros(Y,X);
    meanMaps.scale = zeros(Y,X);
    %% read lat lon vectors
    lat = fscanf(fopen(txtFileName.lat, 'r'), '%f ');
    lon = fscanf(fopen(txtFileName.lon, 'r'), '%f ');
    %% find index in output geometry
    [LAT1, LAT2] = meshgrid(lat,meanMaps.lat(:,1));
    [~,idx.y]    = min(abs(LAT1-LAT2),[],1);
    [LON1, LON2] = meshgrid(lon,meanMaps.lon(1,:));
    [~,idx.x]    = min(abs(LON1-LON2),[],1);
    idx.lin      = drop_2d_to_1d(idx.y,idx.x,Y);
    %% read parameters
    u     = fscanf(fopen(txtFileName.u, 'r'), '%e ');
    v     = fscanf(fopen(txtFileName.v, 'r'), '%e ');
    scale = fscanf(fopen(txtFileName.scale, 'r'), '%e ');
    %% sum over parameters for each grid cell
    for kk = 1:X*Y
        flag = (idx.lin == kk);
        meanMaps.count(kk) = meanMaps.count(kk) + sum(flag);
        meanMaps.u(kk) = meanMaps.u(kk) + sum(u(flag));
        meanMaps.v(kk) = meanMaps.v(kk) + sum(v(flag));
        meanMaps.scale(kk) = meanMaps.scale(kk) + sum(scale(flag));
    end
    %% build means
    meanMaps.count(meanMaps.count==0)   = nan;
    meanMaps.u     = meanMaps.u     ./ meanMaps.count;
    meanMaps.v     = meanMaps.v     ./ meanMaps.count;
    meanMaps.scale = meanMaps.scale ./ meanMaps.count;
    %% calc angle
    uv               = meanMaps.u + 1i * meanMaps.v;
    meanMaps.absUV   = abs(uv) ;
    meanMaps.angleUV = reshape(wrapTo360(rad2deg(phase(uv(:)))),Y,X);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        f.(fn) = fopen(txtFileName.(fn), 'a');
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





