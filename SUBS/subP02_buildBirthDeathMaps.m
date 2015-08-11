function subP02_buildBirthDeathMaps(DD,window)
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks,DD.threads.num);
    %%
    binMap =  initBinMaps(window);
    %     %%
    binMap = buildBinMaps(binMap,txtFileName,DD.threads.num); %#ok<NASGU>
    %     %%
    save([DD.path.root,'meanMaps.mat'],'-struct','binMap','-append');     
    
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
    b.lat = fscanf(fopen(txtFileName.birthLat, 'r'), '%f ');
    b.lon = wrapTo360(fscanf(fopen(txtFileName.birthLon, 'r'), '%f '));
    d.lat = fscanf(fopen(txtFileName.deathLat, 'r'), '%f ');
    d.lon = wrapTo360(fscanf(fopen(txtFileName.deathLon, 'r'), '%f '));
    
    %% find index in output geometry
    b.idxlin = binDownGlobalMap(b.lat,b.lon,binMaps.lat,binMaps.lon,threads);
    d.idxlin = binDownGlobalMap(d.lat,d.lon,binMaps.lat,binMaps.lon,threads);
    
    %% sum over parameters for each grid cell
    b.map = sumMapOverIndexedBins(b.idxlin,Y,X,threads);
    d.map = sumMapOverIndexedBins(d.idxlin,Y,X,threads);
    
    %% out
    out.birth = b;
    out.death = d;
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD)
    tracks = DD.path.analyzed.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
    FN = {'birthLat','deathLat','birthLon','deathLon'};
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
            track = getfieldload(tracks(tt).fullname,'birthdeath');
            fprintf(fid.birthLat,'%3.3f ',track.birth.lat);
            fprintf(fid.birthLon,'%3.3f ',track.birth.lon);
            fprintf(fid.deathLat,'%3.3f ',track.death.lat);
            fprintf(fid.deathLon,'%3.3f ',track.death.lon);
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