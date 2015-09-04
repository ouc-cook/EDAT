function subP03_drawTracks(DD,window)
    trackFiles = DD.path.analyzed.files;
    figure(1)
    set(gcf,'windowstyle','docked'),clf
    hold on
    CM = jet(100);
    maxampF = [DD.path.root 'maxamp.mat'];
    %%
    if ~exist(maxampF,'file')
        maxamp=0;
        for tt=1:numel(trackFiles)
            fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
            track = load(trackFiles(tt).fullname);
            amp = mean(track.amp);
            if amp>maxamp
                maxamp=amp;
            end
        end
        save(maxampF,'maxamp');
    else
        load(maxampF);
    end
    %%
    for tt=1:numel(trackFiles)
        fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
        track = load(trackFiles(tt).fullname);
        geo = track.daily.geo;
        amp = nanmean(track.amp);
        if isnan(amp),continue,end % TODO
        tag = abs(diff(geo.lon([1 1:end])))>180;
        geo.lon(tag) = nan;
        geo.lat(tag) = nan;
        plot(geo.lon,geo.lat,'color',CM(ceil(amp/maxamp*100),:),'linewidth',.2)
    end
    colormap(CM);
    cb=colorbar;
    yt=get(cb,'ytick');
    ytn=linspace(0,maxamp,numel(yt));
    set(cb,'yticklabel',round((ytn*100)));
    title('mean amplitude [cm]');
    
    %%
    load coast
    axis tight
    xl=get(gca,'xlim');
    yl=get(gca,'ylim');
    long=wrapTo360(long);
    tag = abs(diff(long([1 1:end])))>180;
    long(tag)=nan;
    lat(tag)=nan;
    plot(long,lat,'color','blue');
    axis([xl yl]);
        
    %%
    tit=[DD.path.root 'tracksplotAmp'];
    print(tit,'-r400','-depsc')
    system(sprintf('epstopdf %s.eps',tit));
     system(sprintf('rm %s.eps',tit));
end