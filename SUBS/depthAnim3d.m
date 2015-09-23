function depthAnim3d
    close all
    minAmp = 0;
    minAge = 0;
    
    pngdir = '../pngsDepMov3d/';
    mkdirp(pngdir)
    tr(1).fn = extractfield(dir2('../dataind500/TRACKS/*mat'),'fullname');
    tr(2).fn = extractfield(dir2('../dataind1000/TRACKS/*mat'),'fullname');
    tr(3).fn = extractfield(dir2('../dataind1900/TRACKS/*mat'),'fullname');
    
    tr(1).start = str2datenumarray(tr(1).fn,27,34);
    tr(1).end   = str2datenumarray(tr(1).fn,36,43);
    tr(2).start = str2datenumarray(tr(2).fn,28,35);
    tr(2).end   = str2datenumarray(tr(2).fn,37,44);
    tr(3).start = str2datenumarray(tr(3).fn,28,35);
    tr(3).end   = str2datenumarray(tr(3).fn,37,44);
    
    tr(1).age = tr(1).end - tr(1).start;
    tr(2).age = tr(2).end - tr(2).start;
    tr(3).age = tr(3).end - tr(3).start;
    
    dstart = min(cat(2,tr.start));
    dend   = max(cat(2,tr.end  ));
    
    dd = dstart:3:dend;
    for ii = 1:numel(dd)
        doDaPlot(tr,dd(ii),minAmp,minAge,pngdir);
    end
end

function doDaPlot(tr,dd,minAmp,minAge,pngdir)
    tit=sprintf('%s%0d',pngdir,dd);
    if exist([tit '.png'],'file')
        return
    end
    
    close all
    figure
    hold on
    
    doDaDepth(tr(1),dd,465,minAmp,minAge);
    doDaDepth(tr(2),dd,918,minAmp/2,minAge);
    doDaDepth(tr(3),dd,1875,minAmp/4,minAge);
    
    %%
%     set(gca,'ylim',[-2000 0])
%     CB = colorbar;
%     colormap(jet)
%     set(gca,'ytick',[-1875 -918 -465 ])
%     title(datestr(dd))
%     xt = 70:20:200;
%     set(gca,'xtick',deg2km(xt))
%     set(gca,'xticklabel',xt)
%     set(CB,'ytick',linspace(0,1,4))
%     set(CB,'yticklabel',[-60 -50 -40 -30])
%     xlabel('longitude. color:latitude.')
%     ylabel('depth')
%     axis([deg2km(70) deg2km(200) -2000 0])
%     %%
%     print(tit,'-dpng')
%     system(sprintf('convert %s.png -trim %s.png',tit,tit))
end

function CM = doDaDepth(tr,dd,depth,minAmp,minAge)
    flag = tr.start <= dd & tr.end >= dd  & tr.age >= minAge ;
    trn = tr.fn(flag);
    strtd = tr.start(flag);
    getday = @(x,ii) x(ii);
    CM = jet(31);
    for ff = 1:numel(trn)
        %         sprintf('%d%% done',round(100*ff/numel(trn)))
        ii = (dd-strtd(ff)+3)/3;
        try
            trck = getday(getfield(load(trn{ff}),'track'),ii) ;
        catch % TODO happens cos of missing data at end of life of eddy
            continue
        end
        amp = trck.peak.amp.to_ellipse*1000;
        if amp<minAmp || isnan(amp)
            continue
        end
        %         x = deg2km(trck.geo.lon)*cosd(trck.geo.lat);
        x = deg2km(trck.geo.lon);
        y = ceil(trck.geo.lat + 60);
        
        cx = trck.coor.exact.x;
        cy = trck.coor.exact.y;
               
        
        r = (trck.radius.mean)/1000;
        xi = linspace(x-2*r,x+2*r,100);
        yi = amp*exp(-.5*((xi-x)/r).^2)  -  depth;
        plot(xi,yi,'color',CM(y,:))
        hold on
    end
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dna = str2datenumarray(in,s,e)
    dna = nan(1,numel(in));
    for cc = 1:numel(in)
        dna(cc) = datenum(in{cc}(s:e),'yyyymmdd');
    end
end
