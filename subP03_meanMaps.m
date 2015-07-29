function fig=subP03_meanMaps(DD,window,meanMaps)
    %%
    la = meanMaps.lat;
    lo = meanMaps.lon;
   %%
    fig.birthdeath = figure('windowstyle','docked');
    mapBD(meanMaps.birthDeath,lo,la);
    %%
    fig.angle = figure('windowstyle','docked');
    mapAngle(meanMaps,lo,la);
    %%
    fig.u = figure('windowstyle','docked');
    mapU(meanMaps.u,lo,la);
    %%
    fig.v = figure('windowstyle','docked');
    mapV(meanMaps.v,lo,la);
    %%
    fig.scale = figure('windowstyle','docked');
    mapScale(meanMaps.scale,lo,la);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapBD(BD,lo,la)
    BD.age
    BD.birth.lat
    BD.birth.lon
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapAngle(mM,lo,la)
    a=pcolor(lo,la,mM.absUV);
    set(a,'facealpha',.5);
    shading flat;
    caxis([0 .2]);
    colorbar;
    hold on;
    quiver(lo(1:2:end),la(1:2:end),mM.u(1:2:end),mM.v(1:2:end),2,'color','red');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapScale(scale,lo,la)
    pcolor(lo,la,scale/1000);
    colorbar
    shading flat
    caxis([20 200])    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapU(u,lo,la)
    pcolor(lo,la,u);
    shading flat
    caxis([-.2 .2])
    colorbar
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapV(v,lo,la)
    pcolor(lo,la,v);
    shading flat
    caxis([-.05 .05])
    colorbar
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%