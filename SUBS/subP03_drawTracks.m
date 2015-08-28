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
        if isnan(amp),continue,end % TODO
        tag = abs(diff(geo.lon([1 1:end])))>180;
        geo.lon(tag) = nan;
        geo.lat(tag) = nan;
        plot(geo.lon,geo.lat,'color',CM(ceil(amp/maxamp*100),:))
    end
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
    colorbar
    %%
    tit=[DD.path.root 'tracksplotAmp'];
    print(tit,'-depsc')
    system(sprintf('epstopdf %s.eps',tit))
    
end