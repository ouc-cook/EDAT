function subP03_birthDeath(DD,x,y,B,D,lo,la)
    close all
    [long,lat]=loadcoast360;
    
    
     %%
    pcolor(lo,la,log(abs(hypot(x,y))));shading flat;
    set(gcf,'windowstyle','docked')
    CB = colorbar;
    colormap(jet(100));
    yt= get(CB,'ytick');
    set(CB,'ytick',log(round(exp(yt))));
    set(CB,'yticklabel',round(exp(yt)));
    hold on
    plot(long,lat);
    title(['distance to location of dissipation [km].'])
    %%
    tit=[DD.path.root 'mapBinDistTillDeath'];
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    
    
    %%
    pcolor(lo,la,log(B.map));shading flat;
    set(gcf,'windowstyle','docked')
    CB = colorbar;
    colormap(jet(100));
    yt= get(CB,'ytick');
    set(CB,'ytick',log(round(exp(yt))));
    set(CB,'yticklabel',round(exp(yt)));
    hold on
    plot(long,lat);
    title(['Births per 1x1deg bin.'])
    %%
    tit=[DD.path.root 'mapBinBirths'];
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    %%
    pcolor(lo,la,log(D.map));shading flat;
    set(gcf,'windowstyle','docked')
    CB = colorbar;
    colormap(jet(100));
    yt= get(CB,'ytick');
    set(CB,'ytick',log(round(exp(yt))));
    set(CB,'yticklabel',round(exp(yt)));
    hold on
    plot(long,lat);
    title(['Deaths per 1x1deg bin.'])
    %%
    tit=[DD.path.root 'mapBinDeaths'];
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    
    %%
    clf
    lims=[-20 20];
    pcolor(lo,la,B.map-D.map);shading flat;
    set(gcf,'windowstyle','docked')
    CB = colorbar;
    
    caxis(lims)
    colormap(bluewhitered(100,true));
  
  set(CB,'ytick',lims);
  set(CB,'yticklabel',{'deaths','births'});
    hold on
    plot(long,lat);
    title(['(births - deaths) per 1x1deg bin.'])
    %%
    tit=[DD.path.root 'mapBinBminusD'];
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    
end