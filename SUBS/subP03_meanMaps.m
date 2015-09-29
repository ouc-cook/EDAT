function subP03_meanMaps(DD,window,mM)
    %%
    la = mM.lat;
    lo = mM.lon;
    close all
    [long,lat]=loadcoast360;
    %%

    
    
    
    
    
    %     pr=parula(20);
%     CM = [pr(:,[1 2 3]);flipud(pr)];
    figure(1);
    pcolor(lo,la,mM.v*100);set(gcf,'windowstyle','docked')
    shading flat
    caxis([-.01 .01]*100)
    colorbar
    title('V [cm/s]')
    hold on
    plot([min(lo(:)) max(lo(:))],[0 0],'color','black','linewidth',0.5,'linestyle','--')
    grid on
    plot(long,lat)
    colormap(bluewhitered(100))
    tit=[DD.path.root 'mapBinV'];
    %%
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    %%
    figure(2);    
    pcolor(lo,la,mM.u*100);set(gcf,'windowstyle','docked')
    shading flat
    caxis([-.2 .2]*100)
    colorbar
    title('POP @ AVISO geom.: U [cm/s]')
    hold on
    plot([min(lo(:)) max(lo(:))],[0 0],'color','black','linewidth',0.5,'linestyle','--')
    grid on  
      plot(long,lat)
       colormap(bluewhitered(100))
%        colormap(hsv(100))
    tit=[DD.path.root 'mapBinU'];
    savefig(gcf,tit)        
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    
    %%
    
    figure(3);
    
    avi = load(['../dataAVI/meanMaps.mat'])
    
    m = mM.scale/1000;
    fl=isnan(avi.scale);
    m(fl)=nan;
    
    pcolor(lo,la,m);set(gcf,'windowstyle','docked')
    shading flat
    caxis([0 200])
    colorbar
    colormap(hsv(20))
    title('POP @ AVISO geom.: scale [km]')
    hold on
    plot([min(lo(:)) max(lo(:))],[0 0],'color','black','linewidth',0.5,'linestyle','--')
    grid on
    plot(long,lat,'-black')
    tit=[DD.path.root 'mapBinScale'];
      savefig(gcf,tit)
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    
      %%
    figure(4);
    clf
    lim=.2;
    u= mM.u(:);v= mM.v(:);llo=lo(:);lla=la(:);
    
      fl=abs(u)>lim | abs(v)>.05;
    v(fl)=[];
     llo(fl)=[];
      lla(fl)=[];
        u(fl)=[];
        inc=4;
    quiver(llo(1:inc:end),lla(1:inc:end),u(1:inc:end),v(1:inc:end),2)
    title('quiver [cm/s]')
    hold on
    plot([min(lo(:)) max(lo(:))],[0 0],'color','black','linewidth',0.5,'linestyle','--')
    grid on  
      plot(long,lat)
      axis tight
    tit=[DD.path.root 'mapBinQuiv'];
    xlabel(sprintf('skipping vectors with u>%d cm/s',lim*100))
    %%
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
         %%
    figure(5);   
    pcolor(lo,la,mM.amp);set(gcf,'windowstyle','docked')
    shading flat
    caxis([1 30])
    colorbar
    colormap(hsv(20))
    title('amplitude [cm]')
    hold on
    plot([min(lo(:)) max(lo(:))],[0 0],'color','black','linewidth',0.5,'linestyle','--')
    grid on
    plot(long,lat,'-black')
    tit=[DD.path.root 'mapBinAmp'];
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    
    
    
   
    
    
end
