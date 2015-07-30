DD = initialise;
%%
T = DD.path.tracks.files;
%%
close all
figure('windowstyle','docked');
hold on
load coast
plot(long,lat,'color','black')
CM = jet(12);
axis([-45 -15 55 75])
meanMonth=nan(size(T));
%%
for t = 1:1:numel(T)
    fprintf('%d%%\n',round(t/numel(T)*100))
  tr = getfieldload(T(t).fullname,'track');
  geo.la = extractdeepfield(tr,'geo.lat');
  geo.lo = wrapTo180(extractdeepfield(tr,'geo.lon'));
  dn = extractfield(tr,'daynum');
  meanMonth(t) = month(mean(dn));
  plot(geo.lo,geo.la,'color',CM(meanMonth(t),:))  
end
cb=colorbar;
set(cb,'ytick',1:12,'yticklabel',1:12)
title('all tracks')
%%
figure('windowstyle','docked');
histogram(meanMonth)
title('all tracks')

%%
figure('windowstyle','docked');
hold on
load coast
plot(long,lat,'color','black')
CM = jet(12);
axis([-45 -15 55 75])
meanMonth=nan(size(T));
for t = 1:1:numel(T)
    fprintf('%d%%\n',round(t/numel(T)*100))
  tr = getfieldload(T(t).fullname,'track');
  geo.la = extractdeepfield(tr,'geo.lat');
  if geo.la(1)<65
      continue
  end
  geo.lo = wrapTo180(extractdeepfield(tr,'geo.lon'));
  dn = extractfield(tr,'daynum');
  meanMonth(t) = month(mean(dn));
  plot(geo.lo,geo.la,'color',CM(meanMonth(t),:))  
end
cb=colorbar;
set(cb,'ytick',1:12,'yticklabel',1:12)
title('tracks born north of 65N')
%%
figure('windowstyle','docked');
histogram(meanMonth)
title('tracks born north of 65N')


