function fig=subP03_meanMaps(DD,window,meanMaps)
    %%
    la = meanMaps.lat;
    lo = meanMaps.lon;   
   %%
    fig.v = figure;
    mapV(meanMaps.v,lo,la);
    %%
    fig.u = figure;
    mapU(meanMaps.u,lo,la);
    %%
    fig.scale = figure;
    mapScale(meanMaps.scale,lo,la);
end


function mapScale(scale,lo,la)
    %%
    pcolor(lo,la,scale/1000);set(gcf,'windowstyle','docked')
    colorbar
    shading flat
    caxis([20 200])    
end

function mapV(v,lo,la)
    pcolor(lo,la,v);set(gcf,'windowstyle','docked')
    shading flat
    caxis([-.01 .01])
    colorbar
end

function mapU(u,lo,la)
    pcolor(lo,la,u);set(gcf,'windowstyle','docked')
    shading flat
    caxis([-.2 .2])
    colorbar
end