function subP03_drawTracksAge(DD,window)
    trackFiles = DD.path.analyzed.files;
    figure(1)
    set(gcf,'windowstyle','docked'),clf
    hold on
    CM = jet(100);
    maxageF = [DD.path.root 'maxage.mat'];
    las=@(x) x(end);
    %%
    
    if ~exist(maxageF,'file')
        maxage=0;
        for tt=1:numel(trackFiles)
            fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
            track = load(trackFiles(tt).fullname);
            age = las(track.age);
            if age>maxage
                maxage=age;
            end
        end
        save(maxageF,'maxage');
    else
        load(maxageF);
    end
    %%
    for tt=1:numel(trackFiles)
        fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
        track = load(trackFiles(tt).fullname);
        geo = track.daily.geo;
        age = las(track.age);
        if isnan(age),continue,end % TODO
        tag = abs(diff(geo.lon([1 1:end])))>180;
        geo.lon(tag) = nan;
        geo.lat(tag) = nan;
        plot(geo.lon,geo.lat,'color',CM(ceil(age/maxage*100),:),'linewidth',.2)
    end
    colormap(CM);
    cb=colorbar;
    yt=get(cb,'ytick');
    ytn=linspace(0,maxage,numel(yt));
    set(cb,'yticklabel',(ytn));
    title('final age [days]');
    
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
    tit=[DD.path.root 'tracksplotAge'];
    print(tit,'-r400','-depsc')
    system(sprintf('epstopdf %s.eps',tit));
    system(sprintf('rm %s.eps',tit));
    
end