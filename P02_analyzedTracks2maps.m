function P02_analyzedTracks2maps
    DD = initialise;
    window = getfieldload(DD.path.windowFile,'window')
    main(DD,window);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,window)
    %%
    [FN,tracks,txtFileName] = initTxtFileWrite(DD);
    %%
    writeToTxtFiles(txtFileName,FN,tracks);
    %%
    res=1; % TODO
    meanMaps = initMeanMaps(res,window);
    %%
    meanMaps = buildMeanMaps(meanMaps,FN,txtFileName);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = buildMeanMaps(meanMaps,FN,txtFileName)
    TODO
    fr.lat = fopen(txt.lat, 'r');
    fr.lon = fopen(txt.lon, 'r');
    fr.u = fopen(txt.u, 'r');
    fr.v = fopen(txt.v, 'r');
    
    lat = fscanf(fr.lat, '%f ');
    lon = fscanf(fr.lon, '%f ');
    u = fscanf(fr.u, '%e ');
    v = fscanf(fr.v, '%e ');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function meanMaps = initMeanMaps(res,window)
    TODO
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [FN,tracks,txtFileName] = initTxtFileWrite(DD)
    tracks = DD.path.tracks.files;
    txtdir = [ DD.path.root 'TXT/' ];
    mkdirp(txtdir);
    FN = {'lat','lon','u','v'};
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
        track = getfieldload(tracks(tt).fullname,'analyzed');
        fprintf(f.lat,'%3.3f ',track.daily.geo.lat );
        fprintf(f.lon,'%3.3f ',track.daily.geo.lon );
        fprintf(f.u,  '%1.3e ',track.daily.vel.u);
        fprintf(f.v,  '%1.3e ',track.daily.vel.v);
    end
    %% close files
    for ii=1:numel(FN); fn = FN{ii};
        fclose(f.(fn));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%