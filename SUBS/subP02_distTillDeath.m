function subP02_distTillDeath(DD,window)
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks,DD.threads.num);
    %%
    distTill =  initBinMaps(window);
    %     %%
    distTill = buildBinMaps(distTill,txtFileName,DD.threads.num); %#ok<NASGU>
    %     %%
    save([DD.path.root,'meanMaps.mat'],'-struct','distTill','-append');
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% init output map dim
function map = initBinMaps(window) % TODO make better
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
function [out] = buildBinMaps(binMaps,txtFileName,threads)
    %% init
    [Y,X] = size(binMaps.lat);
    
    %% read lat lon vectors
    dX = fscanf(fopen(txtFileName.distTillDeathX, 'r'), '%f ');
    dY = fscanf(fopen(txtFileName.distTillDeathY, 'r'), '%f ');
    lat= fscanf(fopen(txtFileName.lat, 'r'), '%f ');
    lon= fscanf(fopen(txtFileName.lon, 'r'), '%f ');
    
    %% find index in output geometry
    idxlin = binDownGlobalMap(lat,lon,binMaps.lat,binMaps.lon,threads);
    
    %% sum over parameters for each grid cell
    out.tillDeath.x = meanMapOverIndexedBins(dX,idxlin,Y,X,threads);
    out.tillDeath.y = meanMapOverIndexedBins(dY,idxlin,Y,X,threads);
    
    %% out
    
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD)
    tracks = DD.path.analyzed.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
    FN = {'distTillDeathX','distTillDeathY','lat','lon'};
    for ii=1:numel(FN); fn = FN{ii};
        txtFileName.(fn) = [ txtdir fn '.txt' ];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function writeToTxtFiles(txtFileName,FN,tracks,threads)
    %% open files
    lims = thread_distro(threads,numel(tracks));
    T = disp_progress('init','creating TXT/*.txt files');
    spmd(threads)
        for ii=1:numel(FN); fn = FN{ii};
            myFname = strrep(txtFileName.(fn),'.txt',sprintf('%02d.txt',labindex));
            system(sprintf('rm -f %s',myFname));
            fid.(fn) = fopen(myFname, 'w');
        end
        %% write parameters to respective files
        for tt=lims(labindex,1):lims(labindex,2)
            T = disp_progress('show',T,diff(lims(labindex,:))+1,100);
            track = getfieldload(tracks(tt).fullname,'dist');
            
            fprintf(fid.distTillDeathX,'%4.1f ',track.x(end));
            fprintf(fid.distTillDeathY,'%4.1f ',track.y(end));
            
            fprintf(fid.lat,'%3.2f ',track.lat(1) );
            fprintf(fid.lon,'%3.2f ',track.lon(1) );
            
        end
        %% close files
        for ii=1:numel(FN); fn = FN{ii};
            fclose(fid.(fn));
        end
    end
    
    %% cat workers' files
    for ii=1:numel(FN); fn = FN{ii};
        allFname = strrep(txtFileName.(fn),'.txt','??.txt');
        outFname = txtFileName.(fn);
        system(sprintf('cat %s > %s',allFname,outFname));
        system(sprintf('rm %s',allFname));
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%