function subP03_contourSSHwithDetectedContsOverlay(DD,window)
    day2plot = 1;
    %% load data
    [eddy,ssh] = loadEddiesAndSsh(DD,day2plot);
    %%
    fig = initFigure;
    %%
    drawContours(ssh,DD.contour.step,window.lat,window.lon);
    %%
    overlayEddies(eddy,window.lat,window.lon,2);
    %%
    drawCoast;
    %%
    labelsAndPrint(DD.path.root);
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function labelsAndPrint(dataDir)
    title('anti-cyclones in red. cyclones in black.')
    xlabel('longitude')
    ylabel('latitude')
    %%
    tit = [dataDir 'contoursWithEddies'];
    print(tit,'-dpng')
    system(sprintf('convert %s.png -trim %s.png',tit,tit))
    system(sprintf('eog %s.png &',tit))
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fig = initFigure
    fig = figure(1);
    set(fig,'windowstyle','docked');
    clf;
    hold on
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawContours(ssh,contourStep,lat,lon)
    contour(lon,lat,ssh,nanmin(ssh(:)):contourStep:nanmax(ssh(:)));
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function overlayEddies(eddy,lat,lon,linewidth)
    ac = eddy.AntiCycs;
    for kk = 1:numel(ac)
        coor = ac(kk).coor.exact;
        la = interp2(lat,coor.x,coor.y);
        lo = interp2(lon,coor.x,coor.y);
        plot(lo,la,'color','red','linewidth',linewidth)
        
    end
    %%
    c = eddy.Cycs;
    for kk = 1:numel(c)
        coor = c(kk).coor.exact;
        la = interp2(lat,coor.x,coor.y);
        lo = interp2(lon,coor.x,coor.y);
        plot(lo,la,'color','black','linestyle','-','linewidth',linewidth)
        
    end
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawCoast
    ax=axis;
    load coast
    long = wrapTo360(long);
    tag = abs(diff(long([1 1:end])))>180;
    long(tag) = nan;
    lat(tag) = nan;
    plot(long,lat,'color','black')
    axis(ax)
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eddy,ssh] = loadEddiesAndSsh(DD,day2plot)
    eddy = load(DD.path.eddies.files(day2plot).fullname);
    try
        ssh  = getfield(getfield(load(DD.path.cuts.files(day2plot).fullname),'fields'),'sshAnom');
    catch
        ssh  = getfield(getfield(load(DD.path.cuts.files(day2plot).fullname),'fields'),'ssh'); % in case cuts are recycled from old version (ssh anomaly used to be called "ssh")
    end   
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
