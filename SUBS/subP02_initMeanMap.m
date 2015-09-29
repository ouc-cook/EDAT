
function meanMap = subP02_initMeanMap(geo)
    %     bs  = DD.map.out.binSize;
    if round(geo.east - geo.west)==360
        xvec    = wrapTo360(1:1:360);
    else
        xvec    = wrapTo360(round(geo.west):1:round(geo.east));
    end
    yvec    = round(geo.south):1:round(geo.north);
    %%
    [meanMap.lon,meanMap.lat] = meshgrid(xvec,yvec);
    
end