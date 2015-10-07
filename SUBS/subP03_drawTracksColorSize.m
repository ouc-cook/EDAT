minAge = 100;
trackFiles = DD.path.tracks.files;
figure(1)
set(gcf,'windowstyle','docked'),clf
hold on
CM = jet(100);
%%

for tt=1:numel(trackFiles)
    fprintf('%d%%\n',round(100*tt/numel(trackFiles)))
    
    FN = trackFiles(tt).fullname;
    j = regexp(FN,'-d\d\d\d\d') +2;
    age = str2double(FN(j:j+3));
    if age<minAge
        continue
    end
    track = getfield(load(FN),'track');
    
    scale.all = extractdeepfield(track,'radius.mean');
    scale.min = nanmin(scale.all) ;
    scale.max = nanmax(scale.all);
    scale.range = linspace(scale.min,scale.max,size(CM,1));
    
    startPoint.lat = track(1).geo.lat;
    startPoint.lon = track(1).geo.lon;
    for tt = 1:numel(track)-1
        geoA = track(tt).geo;
        geoB = track(tt+1).geo;
        sca = track(tt).radius.mean;
        [~,idxInRange] = min(abs(scale.range-sca));
        plot([geoA.lon geoB.lon]-startPoint.lon,[geoA.lat geoB.lat]-startPoint.lat,'color',CM(idxInRange,:))
    end
    
end
%%
colormap(CM);
cb=colorbar;
set(cb,'ytick',[0 1],'yticklabel',{'min scale','max scale'})
axis off
%%
tit=[DD.path.root 'tracksplotColorScale'];
print(tit,'-r400','-depsc')
system(sprintf('epstopdf %s.eps',tit));
system(sprintf('rm %s.eps',tit));

