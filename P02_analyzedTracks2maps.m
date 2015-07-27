function P02_analyzedTracks2maps
    
    DD = initialise;
    window = getfieldload(DD.path.windowFile,'window');
    main(DD,window);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,window)
    %%
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks);
    %  TODO
    %         buildNetCdfFromTxtFiles(FN,txtFileName)
    %
    meanMap =  initMeanMaps(window);
    %
    meanMap = buildMeanMaps(meanMap,FN,txtFileName,DD.threads.num); %#ok<NASGU>
    %%
    meanMap.birthDeath = buildBirthDeathMaps(tracks);
    %%
    save([DD.path.root,'meanMaps.mat'],'meanMap');
    a = load([DD.path.root,'meanMaps.mat']);
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
function map = initMeanMaps(window)
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
function meanMaps = buildMeanMaps(meanMaps,FN,txtFileName,threads)
    %% init
    [Y,X] = size(meanMaps.lat);
    meanMaps.count = zeros(Y,X);
    meanMaps.u     = zeros(Y,X);
    meanMaps.v     = zeros(Y,X);
    meanMaps.scale = zeros(Y,X);
    %% read lat lon vectors
    lat = fscanf(fopen(txtFileName.lat, 'r'), '%f ');
    lon = wrapTo360(fscanf(fopen(txtFileName.lon, 'r'), '%f '));
    %% find index in output geometry
        
    lalo = lon + 1i*lat;
    Mlalo = reshape(meanMaps.lon + 1i*meanMaps.lat,[],1);
    idxlin = nan(size(lalo));
    
    lims = thread_distro(threads,numel(lalo));
    spmd(threads)
        T = disp_progress('init','blibb');
        for ii=lims(labindex,1):lims(labindex,2)
            T = disp_progress('blubb',T,diff(lims(labindex,:)),1000);
            [minA,minAidx] = min(abs(lalo(ii)-Mlalo)) ;
            [minB,minBidx] = min(abs(lalo(ii)-Mlalo+360)) ;
            if minA < minB
                idxlin(ii) = minAidx;
            else
                idxlin(ii) = minBidx;
            end
        end
        idxx = gop(@horzcat,idxlin,1);
    end
    idxx = idxx{1};
    idxlin = nansum(idxx,2);
    
    
    %% read parameters
    u     = fscanf(fopen(txtFileName.u, 'r'),     '%e ');
    v     = fscanf(fopen(txtFileName.v, 'r'),     '%e ');
    scale = fscanf(fopen(txtFileName.scale, 'r'), '%e ');
    %% sum over parameters for each grid cell
    % TODO make faster
    
    for kk = 1:X*Y
        fprintf('%2.1f%%\n',round(1000*kk/X/Y)/10)
        flag = (idxlin == kk);
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





