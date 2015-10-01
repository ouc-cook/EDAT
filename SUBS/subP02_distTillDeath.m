function subP02_distTillDeath(DD,binMap)
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks,DD.threads.num);
    %%
    binMap = buildBinMaps(binMap,txtFileName,DD.threads.num); %#ok<NASGU>
    %%
    save([DD.path.root,'meanMaps.mat'],'-struct','binMap','-append');
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [inout] = buildBinMaps(inout,txtFileName,threads)
    %% init
    [Y,X] = size(inout.lat);
    
    %% read lat lon vectors
    dX = fscanf(fopen(txtFileName.distTillDeathX, 'r'), '%f ');
    dY = fscanf(fopen(txtFileName.distTillDeathY, 'r'), '%f ');
    lat= fscanf(fopen(txtFileName.lat, 'r'), '%f ');
    lon= fscanf(fopen(txtFileName.lon, 'r'), '%f ');
    
    %% find index in output geometry
    idxlin = binDownGlobalMap(lat,lon,inout.lat,inout.lon,threads);
    
    %% sum over parameters for each grid cell
    inout.tillDeath.x = meanMapOverIndexedBins(dX,idxlin,Y,X,threads);
    inout.tillDeath.y = meanMapOverIndexedBins(dY,idxlin,Y,X,threads);
    
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