function subP03_hists(DD)
    dt = DD.time.delta_t;
    tracksFs = DD.path.tracks.files;

    datacount = 0;
    for aa=1:numel(tracksFs)
        datacount = datacount + str2double(tracksFs(aa).name(35:38))/dt;
    end
    histoStuff.scale = nan(datacount,1);
    histoStuff.age   = nan(datacount,1);
    histoStuff.amp   = nan(datacount,1);
    %%
    T = disp_progress('init','extracting from tracks');
    ca = 1;
    for aa=1:numel(tracksFs)
        T = disp_progress('show',T,numel(tracksFs),1000);
        track = getfieldload(tracksFs(aa).fullname,'track');
        cb = ca+numel(track)-1;
        histoStuff.scale(ca:cb) = extractdeepfield(track,'radius.mean');
        histoStuff.age(ca:cb)   = extractdeepfield(track,'age');
        histoStuff.amp(ca:cb)   = extractdeepfield(track,'peak.amp.to_ellipse');
        ca = cb + 1;
    end
    try
        save([DD.path.root 'histStruct.mat'],'-append','histoStuff')
    catch
        save([DD.path.root 'histStruct.mat'],'histoStuff')
    end
    %% plotting
    %     save
    %     figure(1)
    %       set(gcf,'windowstyle','docked')
    %     scatter(histoStuff.age,histoStuff.amp,(histoStuff.scale/10000).^2)
    %%
    figure(2)
    set(gcf,'windowstyle','docked')
    histogram(histoStuff.scale/1000)
    title(sprintf('scale[km]. %d values from %d tracks.',datacount,numel(tracksFs)))


end
