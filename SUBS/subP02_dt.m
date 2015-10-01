%  --- Post-processing step 2 ---
%
%  -(I) prepare .txt files at "TXT"
%  -(II) cat all values of all tracks into one .txt per parameter.
%  -(III) build means of parameters over 1x1degree bins.
function subP02_dt(DD,meanMap)
    keys = {'lat','lon','amp','scale','age'};
    [FN,tracks,txtFileName] = initTxtFileWrite(DD,keys);
    %%
    writeToTxtFiles(txtFileName,FN,tracks,DD.threads.num);
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
function [idxlin] = getCrossRefIdx(meanMaps,txtFileName,threads,windowFile)
    
    if ~isfield(load(windowFile),'idxlin')
        %% read lat lon vectors
        lat = fscanf(fopen(txtFileName.lat, 'r'), '%f ');
        lon = wrapTo360(fscanf(fopen(txtFileName.lon, 'r'), '%f '));
        %% find index in output geometry
        idxlin = binDownGlobalMap(lat,lon,meanMaps.lat,meanMaps.lon,threads);
        save(windowFile,'idxlin','-append');
    else
        idxlin = getfield(load(windowFile),'idxlin') ;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = buildMeanMaps(meanMaps,txtFileName,threads,idxlin)
    %% init
    [Y,X] = size(meanMaps.lat);
    %% read parameters
    amp   = fscanf(fopen(txtFileName.amp, 'r'), '%e ');
    scale = fscanf(fopen(txtFileName.scale, 'r'), '%e ');
    age   = fscanf(fopen(txtFileName.age, 'r'), '%e ');
    %% sum over parameters for each grid cell
    meanMaps.amp   = meanMapOverIndexedBins(amp,  idxlin,Y,X,threads);
    meanMaps.scale = meanMapOverIndexedBins(scale,idxlin,Y,X,threads);
    meanMaps.age   = meanMapOverIndexedBins(age  ,idxlin,Y,X,threads);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD,FN)
    tracks = DD.path.analyzed.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
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
            track = load(tracks(tt).fullname);
            fprintf(fid.lat,'%3.3f ',track.dist.lat );
            fprintf(fid.lon,'%3.3f ',track.dist.lon );
            fprintf(fid.amp,'%3.3f ',track.amp*100);
            fprintf(fid.scale,'%d ',track.scale);
            fprintf(fid.age,'%d ',track.age);
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
