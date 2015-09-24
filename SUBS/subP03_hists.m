function subP03_hists(DD)
    dt = DD.time.delta_t;
    tracksFs = DD.path.tracks.files;
    %% total count
    datacount = 0;
    for aa=1:numel(tracksFs)
        datacount = datacount + str2double(tracksFs(aa).name(35:38))/dt;
    end
    %% init
    histoStuff.scale = nan(datacount,1);
    histoStuff.age   = nan(datacount,1);
    histoStuff.amp   = nan(datacount,1);
    %% extract
    histoStuff = extractStuff(tracksFs);
    %% save
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


function hS = extractStuff(tracksFs,hS)
    T = disp_progress('init','extracting from tracks');
    ca = 1;
    for aa=1:numel(tracksFs)
        T = disp_progress('show',T,numel(tracksFs),1000);
        track = getfieldload(tracksFs(aa).fullname,'track');
        cb = ca+numel(track)-1;
        hS.scale(ca:cb) = extractdeepfield(track,'radius.mean');
        hS.age(ca:cb)   = extractdeepfield(track,'age');
        hS.amp(ca:cb)   = extractdeepfield(track,'peak.amp.to_ellipse');
        ca = cb + 1;
    end
end