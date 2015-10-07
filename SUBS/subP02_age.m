%  --- Post-processing step 2 ---
%
%  -(I) prepare .txt files at "TXT"
%  -(II) cat all values of all tracks into one .txt per parameter.
%  -(III) build means of parameters over 1x1degree bins.
function subP02_age(DD,window)
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks,DD.threads.num);
    %%
    meanMap =  initMeanMaps(window);
    %%
    [idxlin] = getCrossRefIdx(meanMap,txtFileName,DD.threads.num,DD.path.windowFile);
    %%
    [meanMap] = buildMeanMaps(meanMap,txtFileName,DD.threads.num,idxlin); %#ok<NASGU>
    %%
    try
        save([DD.path.root,'meanMaps.mat'],'-struct','meanMap','-append');
    catch
        save([DD.path.root,'meanMaps.mat'],'-struct','meanMap');
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
function [idxlinOrig] = getCrossRefIdx(meanMaps,txtFileName,threads,windowFile)
    
    if ~isfield(load(windowFile),'idxlinOrig')
        %% read lat lon vectors
        lat = fscanf(fopen(txtFileName.latOrig, 'r'), '%f ');
        lon = wrapTo360(fscanf(fopen(txtFileName.lonOrig, 'r'), '%f '));
        
        %% find index in output geometry
        idxlinOrig = binDownGlobalMap(lat,lon,meanMaps.lat,meanMaps.lon,threads);
        save(windowFile,'idxlinOrig','-append');
    else
        idxlinOrig = getfield(load(windowFile),'idxlinOrig') ;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = buildMeanMaps(meanMaps,txtFileName,threads,idxlin)
    %% init
    [Y,X] = size(meanMaps.lat);
    
    %% read parameters
    age = fscanf(fopen(txtFileName.ageOrig, 'r'), '%e ');
    
    %% sum over parameters for each grid cell
    meanMaps.age = meanMapOverIndexedBins(age,idxlin,Y,X,threads);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD)
    tracks = DD.path.analyzed.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
    FN = {'latOrig','lonOrig','ageOrig'};
    for ii=1:numel(FN); fn = FN{ii};
        txtFileName.(fn) = [ txtdir fn '.txt' ];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%amp%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
            track = load(tracks(tt).fullname);
            fprintf(fid.latOrig,'%3.3f ',track.dist.lat );
            fprintf(fid.lonOrig,'%3.3f ',track.dist.lon );
            fprintf(fid.ageOrig,'%3.3f ',track.age);
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
