function subP03_drawTracks(DD,window)
    trackFiles = DD.path.analyzed.files;
    figure(1)
    set(gcf,'windowstyle','docked'),clf
    hold on
    CM = hot(100);
    %%
    maxamp=0;
    for tt=1:numel(trackFiles)
        fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
        track = load(trackFiles(tt).fullname);
        amp = mean(track.amp);
        if amp>maxamp
            maxamp=amp;
        end
    end
    %%
    for tt=1:numel(trackFiles)
        fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
        track = load(trackFiles(tt).fullname);
        geo = track.daily.geo;
        amp = nanmean(track.amp);
        plot(geo.lon,geo.lat,'color',CM(ceil(amp/maxamp*100),:))
    end
    %%
    load coast
    xl=get(gca,'xlim');
    yl=get(gca,'ylim');
    plot(long,lat,'color','blue');
    axis([xl yl]);
    %%
    tit=[DD.path.root 'tracksplotAmp'];
    print(tit,'-depsc')
    system(sprintf('epstopdf %s.eps',tit))
    
end