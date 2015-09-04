function subP03_hists(DD)
    dt = DD.time.delta_t;
    tracksFs = DD.path.tracks.files;
    
    datacount = 0;
    for aa=1:numel(tracksFs)
        datacount = datacount + str2double(tracksFs(aa).name(35:38))/dt;
    end
    
    HH.scale = nan(datacount,1);
    HH.age   = nan(datacount,1);
    HH.amp   = nan(datacount,1);
    
    
    %%
    T = disp_progress('init','extracting from tracks');
   ca = 1;
    for aa=1:numel(tracksFs)
        T = disp_progress('show',T,numel(tracksFs),1000);
        track = getfieldload(tracksFs(aa).fullname,'track');
        cb = ca+numel(track)-1;
        HH.scale(ca:cb) = extractdeepfield(track,'radius.mean');
        HH.age(ca:cb)   = extractdeepfield(track,'age');
        HH.amp(ca:cb)   = extractdeepfield(track,'peak.amp.to_ellipse');
        ca = cb + 1;
    end
    
    save([DD.path.root 'histStruct.mat'],'-struct','HH')
    %% plotting
%     save
%     figure(1)
%       set(gcf,'windowstyle','docked')
%     scatter(HH.age,HH.amp,(HH.scale/10000).^2)
   %%
    figure(2)
      set(gcf,'windowstyle','docked')
      histogram(HH.scale/1000)
   title(sprintf('scale[km]. %d values from %d tracks.',datacount,numel(tracksFs)))
      
      
end