%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-Apr-2014 17:39:11
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S09_drawPlots
    %     DD=initialise([],mfilename);
    %     save DD
    load DD
    dbstop if error
    %%	set ticks here!
    %     ticks.rez=200;
    ticks.rez=get(0,'ScreenPixelsPerInch');
    ticks.width=2*600;
    ticks.height=2*200;
    geo=DD.map.window.geo;
    %     ticks.y= round(linspace(geo.south,geo.north,5));
    ticks.y= [-70 -50 -30 0 30 50 70];
    %     ticks.x=  round(linspace(geo.west,geo.east,5));
    ticks.x=  round(linspace(-180,180,5));
    ticks.axis=[geo.west  geo.east geo.south geo.north];
    ticks.age=[1,5*365,10];
    %     ticks.isoper=[DD.thresh.shape.iq,1,10];
    ticks.isoper=[.6,1,10];
    ticks.radius=[50,250,11];
    ticks.radiusStd=[0,150,11];
    ticks.radiusToRo=[1,5,5];
    ticks.amp=[1,20,7];
    %ticks.visits=[0,max([maps.AntiCycs.visitsSingleEddy(:); maps.Cycs.visitsSingleEddy(:)]),5];
    ticks.visits=[1,20,11];
    ticks.visitsunique=[1,10,10];
    ticks.dist=[-1500;500;11];
    %ticks.dist=[-100;50;16];
    ticks.disttot=[1;3000;5];
    ticks.vel=[-30;20;6];
    ticks.lat=[ticks.axis(3:4),5];
    %% main
    main(DD,ticks)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,ticks)
    close all
    [procData]=inits(DD);
    save([DD.path.analyzed.name 'procData.mat'],'procData');
    %     load([DD.path.analyzed.name 'procData.mat'],'procData');
    %%
    senses = DD.FieldKeys.senses';
    %     spmd(2)
    %     for labindex=1:2
    %         sen=senses{labindex};
    %         TPz(DD,ticks,procData.tracks,sen,'lat',30,'lat',0);
    %         TPz(DD,ticks,procData.tracks,sen,'peakampto_mean',30,'amp',1);
    %     TPzGlobe(DD,ticks,procData.tracks,sen,'peakampto_ellipse',30,'amp',1,100);
    TPzGlobe(DD,ticks,procData.tracks,senses,'age',50,'age',1,1);
    %         TPzGlobe(DD,ticks,procData.tracks,sen,'isoper',3,'iq',0,1);
    %     end
    %     TPzGlobe(DD,ticks,procData.tracks,sen,'peakampto_ellipse',3,'amp',1,100);
    %    TPzGlobe(DD,ticks,procData.tracks,sen,'isoper',50,'iq',0,1);
    %TPzGlobe(DD,ticks,procData.tracks,sen,'peakampto_ellipse',80,'amp',1,100);
    %     TPzGlobe(DD,ticks,procData.tracks,sen,'isoper',3,'iq',0,1);
    %     end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [OUT]=inits(DD)
    disp(['loading maps'])
    OUT.maps=load([DD.path.analyzed.name, 'maps.mat']);
    OUT.la=OUT.maps.Cycs.lat;
    OUT.lo=OUT.maps.Cycs.lon;
    if DD.switchs.netUstuff
        OUT.maps.meanU=load(DD.path.meanU.file);
    end
    %% collect tracks
    OUT.tracksfile=[DD.path.analyzed.name , 'tracks.mat' ];
    
    for ss=1:2
        sen = DD.FieldKeys.senses{ss};
        root=DD.path.analyzedTracks.(sen).name;
        OUT.(sen)={DD.path.analyzedTracks.(sen).files.name};
        Tac=disp_progress('init',['collecting all ', sen]);
        for ff=1:numel(OUT.(sen))
            Tac=disp_progress('calc',Tac,numel(OUT.(sen)),50);
            OUT.tracks.(sen)(ff)={[root OUT.(sen){ff}]};
        end
    end
    %%
    
    %% get vectors
    %     disp(['loading vectors'])
    % 	OUT.vecs=load([DD.path.analyzed.name, 'vecs.mat']);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPzGlobe(DD,ticks,tracks,senses,colorfield,minlen,cticks,logornot,fac)
    close all
    globe=true;
    %     drawLinez(tracks.(sen),minlen)
    cmap = winter(100);
    drawColorLinez(ticks,tracks.(senses{1}),colorfield,minlen,cticks,logornot,globe,fac,cmap) ;
    cb{1} = colorbar;
    colormap(cb{1},winter(100));
    hold on
    %%
    cmap=autumn(100);
    drawColorLinez(ticks,tracks.(senses{2}),colorfield,minlen,cticks,logornot,globe,fac,cmap) ;
    cb{2}=colorbar('westoutside');
    colormap(cb{2},autumn(100))
    
    %%
    axis([-180 180 -70 70])
    drawcoast
    
    tit=['tracks-' colorfield];
    if logornot
        ticks.(cticks)(1:2) = log(ticks.(cticks)(1:2));
        ticks.(cticks)(ticks.(cticks)==0) = 1;
    end
    for ss=1:2
        set(cb{ss},'ytick',linspace(ticks.(cticks)(1),ticks.(cticks)(2),ticks.(cticks)(3)))
        if logornot
            set(cb{ss},'yticklabel',round(exp(get(cb{ss},'ytick'))))
        end
    end
    set(cb{2},'yticklabel',[])
    grid minor
    savefig(DD.path.plots,ticks.rez,1400,600,tit,'dpdf')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPz(DD,ticks,tracks,sen,colorfield,minlen,cticks,logornot)
    drawColorLinez(ticks,tracks.(sen),colorfield,minlen,cticks,logornot,0) ;
    axis([-5000 3000 -2000 2000])
    axis equal
    set(gca,'ytick',[-1000   0   1000])
    set(gca,'xtick',[-4000 -2000 -1000  0 1000])
    tit=['defl-' colorfield '-' sen];
    cb=colorbar;
    if logornot
        set(cb,'yticklabel',round(exp(get(cb,'ytick'))))
    end
    axis tight
    saveas(gcf,[DD.path.plots tit])
    savefig(DD.path.plots,100,3*800,3*500,tit,'dpdf')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [totnum]=ratioBar(hc,field,xlab)
    %% ratio cyc/acyc per lat
    figure
    %% find max length for ratio vecotr
    len=nanmin([length(hc.Cycs.(field)),length(hc.AntiCycs.(field))]);
    hc.rat.(field)=hc.Cycs.(field)(1:len)./hc.AntiCycs.(field)(1:len);
    hc.rat.(field)(isinf(hc.rat.(field)))=nan;
    hc.rat.(field)((hc.rat.(field)==0))=nan;
    %% total length
    totnum=hc.Cycs.(field)(1:len) + hc.AntiCycs.(field)(1:len);
    %%%%
    logyBar(totnum,hc.rat.(field))
    %%%%
    xt= (1:numel(xlab));
    set(gca,'XTick',xt)
    set(gca,'YTickMode','auto')
    yt= get(gca,'YTick');
    set(gca,'yticklabel',sprintf('%0.1f|',exp(yt)));
    set(gca,'xticklabel',num2str(xlab));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function logyBar(totnum,y)
    len=numel(y);
    y=log(y);
    x=1:len;
    y(totnum==0)=[];
    x(totnum==0)=[];
    totnum(totnum==0)=[];
    
    colors = flipud(bone(max(totnum)));
    cols=colors(totnum,:);
    for ii = 1:numel(x)
        a=bar(x(ii), y(ii));
        hold on
        set(a,'facecolor', cols(ii,:));
    end
    cm=flipud(bone);
    colormap(cm)
    cb=colorbar;
    zticks=linspace(2,max(totnum),5)';
    zticklabel=num2str(round((zticks)));
    caxis([zticks(1) zticks(end)])
    set(cb,'ytick',zticks);
    set(cb,'yticklabel',zticklabel);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lat]=numPerLat(latin,DD,ticks,range,sen)
    figure
    lat=histc(latin,range);
    semilogy(range,lat);
    tit=['number of ',sen,' per 1deg lat'];
    title([tit]);
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['latNum-' sen],DD.debugmode,'dpng',1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [age,cum]=ageCum(agein,DD,ticks,range,sen)
    figure
    agein(agein<DD.thresh.life)=[];
    age=histc(agein,range);
    semilogy(range,age)
    tit=['number of ',sen,' per age'];
    unit='d';
    title([tit,' [',unit,']'])
    cum=fliplr(cumsum(fliplr(age)));
    semilogy(range,cum)
    tit=['upper tail cumulative of ',sen,' per age'];
    title([tit,' [',unit,']'])
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['ageUpCum-' sen ],DD.debugmode);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawcoast
    load coast;
    hold on; plot(long,lat,'LineWidth',0.5);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb=decorate(field,ticks,DD,tit,tit2,unit,logornot,decim,coast,rats)
    if nargin<10
        rats=false;
    end
    if nargin<9
        coast=true;
    end
    
    %     %% TEMP SOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     coast=false
    %     %% TEMP SOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    axis(ticks.axis);
    cb=colorbar;
    if logornot
        zticks=linspace(log(ticks.(field)(1)),log(ticks.(field)(2)),ticks.(field)(3))';
        zticklabel=round(exp(zticks)*decim)/decim;
        if rats
            [n,d]=rat(zticklabel);
            nc=(num2cell(n));
            dc=(num2cell(d));
            zticklabel=cellfun(@(a,b) [num2str(a) '/' num2str(b)],nc,dc,'uniformoutput',false);
        else
            zticklabel=num2str(zticklabel);
        end
    else
        zticks=linspace(ticks.(field)(1),ticks.(field)(2),ticks.(field)(3))';
        zticklabel=num2str(round(zticks*decim)/decim);
    end
    caxis([zticks(1) zticks(end)])
    set(cb,'ytick',zticks);
    set(cb,'yticklabel',zticklabel);
    title([tit,' - ',tit2,' [',unit,']'])
    xlabel(sprintf('Min. age: %d [d]',DD.thresh.life))
    if coast
        drawcoast;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function drawLinez(files,minlen)
    axesm sinusoid;
    hold on
    Tac=disp_progress('init','blibb');
    for ee=1:1:numel(files)
        Tac=disp_progress('calc',Tac,round(numel(files)),100);
        %         len=numel(getfield(load(files{ee},'age'),'age'));
        %         if len<minlen
        %             continue
        %         end
        V=load(files{ee},'lat','lon');
        plotm(V.lat,wrapTo180(V.lon),'linewidth',0.1);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [maxV]=drawColorLinez(ticks,files,fieldName,minlen,cticks,logornot,globe,fac,cmap)
    if nargin<8,fac=1;end
    %     cmap=jet;% Generate range of color indices that map to cmap
    %% get extremata
    minV=ticks.(cticks)(1);
    maxV=ticks.(cticks)(2);
    if logornot
        minV = log(minV);
        maxV = log(maxV);
    end
    kk=linspace(minV,maxV,size(cmap,1));
    Tac=disp_progress('init','blubb');
    for ee=1:1:numel(files)
        Tac=disp_progress('calc',Tac,round(numel(files)),100);
%         len=numel(getfield(load(files{ee},'age'),'age'));
%         if len<minlen
%             continue
%         end
        
        V=load(files{ee},fieldName,'lat','lon');
        VV=V.(fieldName)*fac;
        if logornot
            VV = log(VV);
        end
        cm = spline(kk,cmap',VV);       % Find interpolated colorvalue
        cm(cm>1)=1;                     % Sometimes iterpolation gives values that are out of [0,1] range...
        cm(cm<0)=0;
        cm(:,1)=cm(:,2);
        %% deg2km
        if globe
            yy=V.lat;
            xx=wrapTo180(V.lon);
            dJump=100;
        else
            yy=[0 cumsum(deg2km(diff(V.lat)))];
            xx=[0 cumsum(deg2km(diff(V.lon)).*cosd((V.lat(1:end-1)+V.lat(2:end))/2))];
            dJump=1000;
        end
        
        for ii=1:length(xx)-1
            if  abs(xx(ii+1)-xx(ii))<dJump % avoid 0->360 jumps
                line([xx(ii) xx(ii+1)],[yy(ii) yy(ii+1)],'color',cm(:,ii),'linewidth',0.2);
            end
        end
    end
    caxis([minV maxV])
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [maxV,cmap]=drawColorLinem(ticks,files,fieldName,fieldName2)
    cmap=jet;% Generate range of color indices that map to cmap
    %% get extremata
    maxIQ=ticks.isoper(2);
    minIQ=ticks.isoper(1);
    minV=ticks.lat(1);
    maxV=ticks.lat(2);
    iqiq=linspace(minIQ,maxIQ,10);
    kk=linspace(minV,maxV,size(cmap,1));
    %      kk=linspace(minIQ,maxIQ,10);
    %     iqiq=linspace(minV,maxV,size(cmap,1));
    
    meaniq=nan(size(files));
    for ee=1:numel(files)
        V=load(files{ee},fieldName2);
        VViq=V.(fieldName2);
        meaniq(ee)=nanmean(VViq);
    end
    meaniq(meaniq>1)=1;
    [~,iqorder]=sort(meaniq,'descend');
    
    maxthick=ticks.rez/300*10;
    minthick=ticks.rez/300*0.1;
    for ee=iqorder
        V=load(files{ee},fieldName,fieldName2,'lat','lon');
        %         V=load(files{ee});
        VV=V.(fieldName);
        VViq=V.(fieldName2);
        VViq(VViq>1)=1;
        if isempty(VV)
            continue
        end
        cm = spline(kk,cmap',VV);       % Find interpolated colorvalue
        cm(cm>1)=1;                     % Sometimes iterpolation gives values that are out of [0,1] range...
        cm(cm<0)=0;
        %% Find interpolated thickness
        iq = spline(iqiq,linspace(minthick,maxthick,10),VViq);
        iq(iq<0)=minthick;
        %% deg2km
        yy=[0 cumsum(deg2km(diff(V.lat)))];
        xx=[0 cumsum(deg2km(diff(V.lon)).*cosd((V.lat(1:end-1)+V.lat(2:end))/2))];
        for ii=1:length(xx)-1
            if  abs(xx(ii+1)-xx(ii))<1000 % avoid 0->360 jumps
                line([xx(ii) xx(ii+1)],[yy(ii) yy(ii+1)],'color',cm(:,ii),'LineWidth',iq(ii));
            end
        end
    end
    caxis([minV maxV])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [maxV,cmap]=drawColorLine(ticks,files,fieldName,maxV,minV,logornot,zeroshift)
    cmap=jet;% Generate range of color indices that map to cmap
    if logornot
        maxV=log(maxV);
        minV(minV==0)=1;
        minV=log(minV);
    end
    kk=linspace(minV,maxV,size(cmap,1));
    %%
    maxIQ=ticks.isoper(2);
    minIQ=ticks.isoper(1);
    iqiq=linspace(minIQ,maxIQ,10);
    %%
    meaniq=nan(size(files));
    for ee=1:numel(files)
        V=load(files{ee},'isoper');
        VViq=V.isoper;
        meaniq(ee)=nanmean(VViq);
    end
    meaniq(meaniq>1)=1;
    [~,iqorder]=sort(meaniq,'descend');
    %%
    maxthick=ticks.rez/300*10;
    minthick=ticks.rez/300*0.1;
    for ee=iqorder
        V=load(files{ee},fieldName,'isoper','lat','lon');
        VV=V.(fieldName);
        VViq=V.isoper;
        VViq(VViq>1)=1;
        if isempty(VV)
            continue
        end
        if logornot
            VV(VV==0)=1;
            cm = spline(kk,cmap',log(VV));  % Find interpolated colorvalue
            %             cm = spline(iqiq,cmap',log(VViq));  % Find interpolated colorvalue
        else
            cm = spline(kk,cmap',VV);       % Find interpolated colorvalue
            %             cm = spline(iqiq,cmap',VViq);       % Find interpolated colorvalue
        end
        cm(cm>1)=1;                        % Sometimes iterpolation gives values that are out of [0,1] range...
        cm(cm<0)=0;
        lo=V.lon;
        la=V.lat;
        if zeroshift
            lo=lo-lo(1);
            la=la-la(1);
        end
        %% Find interpolated thickness
        iq = spline(iqiq,linspace(minthick,maxthick,10),VViq);
        %         iq = spline(kk,linspace(0.01,2,10),VV);
        iq(iq<0)=minthick;
        %%
        for ii=1:length(la)-1
            if  abs(lo(ii+1)-lo(ii))<10 % avoid 0->360 jumps
                line([lo(ii) lo(ii+1)],[la(ii) la(ii+1)],'color',cm(:,ii),'LineWidth',iq(ii));
            end
        end
    end
    caxis([minV maxV])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


































function TPa(DD,ticks,tracks,sen)
    drawColorLinem(ticks,tracks.(sen),'lat','isoper') ;
    title([sen '- deflections'])
    axis([-2000 1000 -300 300])
    set(gca,'ytick',[-100 0 100])
    set(gca,'xtick',[-1000 0 500])
    colorbar
    xlabel('IQ repr. by thickness; latitude repr. by color')
    axis equal
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['defletcs' sen],DD.debugmode,'dpng',1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPb(DD,ticks,tracks,sen)
    field='age';
    drawColorLine(ticks,tracks.(sen),field,ticks.age(2),ticks.age(1),1,0) ;
    decorate(field,ticks,DD,sen,field,'d',1,1);
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['age' sen],DD.debugmode,'dpng',1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPc(DD,ticks,tracks,sen)
    drawColorLine(ticks,tracks.(sen),'isoper',ticks.isoper(2),ticks.isoper(1),0,0) ;
    decorate('isoper',ticks,DD,sen,'IQ',' ',0,100)
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['IQ' sen],DD.debugmode,'dpng',1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPd(DD,ticks,tracks,sen)
    drawColorLine(ticks,tracks.(sen),'radiusmean',ticks.radius(2)*1000,ticks.radius(1)*1000,0,0) ;
    decorate('radius',ticks,DD,sen,'Radius','km',0,1)
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['radius' sen],DD.debugmode,'dpng',1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPe(DD,ticks,tracks,sen)
    drawColorLine(ticks,tracks.(sen),'peakampto_ellipse',ticks.amp(2)/100,ticks.amp(1)/100,0,0) ;
    decorate('amp',ticks,DD,sen,'Amp to ellipse','cm',1,1)
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['TrackPeakampto_ellipse' sen],DD.debugmode,'dpng',1);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TPf(DD,ticks,tracks,sen)
    drawColorLine(ticks,tracks.(sen),'peakampto_contour',ticks.amp(2)/100,ticks.amp(1)/100,0,0) ;
    decorate('amp',ticks,DD,sen,'Amp to contour','cm',1,1)
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['TrackPeakampto_contour' sen],DD.debugmode)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapstuff(maps,vecs,DD,ticks,lo,la)
    aut=autumn;
    win=winter;
    ho=hot;
    % 	je=jet;
    senses={'Cycs','AntiCycs'};
    sensesB={'Cyclones','Anti-Cyclones'};
    lo=wrapTo180(lo);
    [~,loA]=min(lo(1,:));
    lo = lo(:,[loA:end,1:loA-1]);
    
    for ss=1:2
        sen=senses{ss};senB=sensesB{ss};
        %         if isempty(vecs.(sen).lat), warning(['warning, no ' sen ' found!']);continue;end %#ok<*WNTAG>
        %
        %         figure
        %         b.la=vecs.(sen).birth.lat;
        %         b.lo=vecs.(sen).birth.lon;
        %         d.la=vecs.(sen).death.lat;
        %         d.lo=vecs.(sen).death.lon;
        %         plot(b.lo,b.la,'.r',d.lo,d.la,'.g','markersize',5)
        %         hold on
        %         axis(ticks.axis);
        %         set(gca,'ytick',ticks.y);
        %         set(gca,'xtick',ticks.x) ;
        %         legend('births','deaths')
        %         title(sen)
        %         savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['deathsBirths-' sen],DD.debugmode,'dpdf');
        %
        %%
        maps.(sen).age.logmean=log(maps.(sen).age.mean);
        VV=maps.(sen).age.logmean;
        pcolor(lo,la,VV);shading flat
        %         caxis([ticks.age(1) ticks.age(2)])
        decorate('age',ticks,DD,senB,'age','d',1,1);
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapAge-' sen],DD.debugmode,'dpdf')
        %%
        figure
        VV=maps.(sen).visits.single;
        VV(VV==0)=nan;
        pcolor(lo,la,VV);shading flat
        %                 caxis([ticks.visits(1) ticks.visits(2)])
        decorate('visitsunique',ticks,DD,sen,'Visits of unique eddy',' ',0,1);
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapVisits-' sen],DD.debugmode,'dpdf');
        
        %
        figure
        VV=maps.(sen).dist.zonal.fromBirth.mean/1000;
        pcolor(lo,la,VV);shading flat
        %         caxis([ticks.dist(1) ticks.dist(2)])
        cb=decorate('dist',ticks,DD,sen,'Zonal Distance from Birth','km',0,1);
        doublemap([ticks.dist(1),0,ticks.dist(2)]	,ho(10:end,:),win,[.9 1 .9])
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapDFB' sen],DD.debugmode,'dpdf');
        %%
        figure
        VV=maps.(sen).dist.zonal.tillDeath.mean/1000;
        pcolor(lo,la,VV);shading flat
        %         caxis([ticks.dist(1) ticks.dist(2)]) %%
        cb=decorate('dist',ticks,DD,sen,'Zonal Distance till Death','km',0,1);
        doublemap([ticks.dist(1),0,ticks.dist(2)]	,ho(10:end,:),win,[.9 1 .9])
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapDTD' sen],DD.debugmode,'dpdf');
        %%
        figure
        VV=log(maps.(sen).dist.traj.fromBirth.mean/1000);
        pcolor(lo,la,VV);shading flat
        %         caxis([ticks.disttot(1) ticks.disttot(2)])
        decorate('disttot',ticks,DD,sen,'Total distance travelled since birth','km',1,1);
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapDTFB' sen],DD.debugmode,'dpdf');
        %%
        figure
        VV=log(maps.(sen).dist.traj.tillDeath.mean/1000);
        pcolor(lo,la,VV);shading flat
        decorate('disttot',ticks,DD,sen,'Total distance to be travelled till death','km',1,1);
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapDTTD' sen],DD.debugmode,'dpdf');
        %%
        figure
        VV=maps.(sen).vel.zonal.mean*100;
        pcolor(lo,la,VV);shading flat
        cb=decorate('vel',ticks,DD,sen,'Zonal velocity','cm/s',0,1);
        doublemap([ticks.vel(1),0,ticks.vel(2)]	,aut,win,[.9 1 .9])
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapVel' sen],DD.debugmode,'dpdf');
        %%
        if DD.switchs.netUstuff
            figure
            VV=maps.(sen).vel.net.mean*100;
            pcolor(lo,la,VV);shading flat
            cb=decorate('vel',ticks,DD,sen,...
                ['(Zonal velocity -Mean Current @('...
                ,num2str(DD.parameters.meanU)	,...
                'm))'],'cm/s',0,1);
            doublemap([ticks.vel(1),0,ticks.vel(2)],aut,win,[.9 1 .9])
            savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapVelNet' sen],DD.debugmode,'dpdf');
        end
        %%
        figure
        VV=maps.(sen).radius.mean.mean/1000;
        pcolor(lo,la,VV);shading flat
        decorate('radius',ticks,DD,sen,'Radius','km',0,1);
        savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapRad' sen],DD.debugmode,'dpdf');
        %%
        if DD.switchs.RossbyStuff
            figure
            VV=log(maps.(sen).radius.toRo/2);
            pcolor(lo,la,VV);shading flat
            %         caxis([ticks.radiusToRo(1) ticks.radiusToRo(2)])
            cb=decorate('radiusToRo',ticks,DD,sen,'Radius/(2*L_R)',' ',1,10,1,1);
            doublemap([ticks.radiusToRo(1),1,ticks.radiusToRo(2)],aut,win,[.9 1 .9])
            savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapRadToRo' sen],DD.debugmode,'dpdf');
            
            %
            %%
            figure
            VV=(maps.(sen).vel.zonal.mean-maps.Rossby.small.phaseSpeed)*100;
            pcolor(lo,la,VV);shading flat
            %         caxis([ticks.vel(1) ticks.vel(2)])
            cb=decorate('vel',ticks,DD,sen,['[Zonal U - c_1)]'],'cm/s',0,1);
            doublemap([ticks.vel(1),0,ticks.vel(2)],aut,win,[.9 1 .9])
            savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['MapUcDiff' sen],DD.debugmode,'dpdf');
            
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function histstuff(vecs,DD,ticks)
    senses={'Cycs','AntiCycs'};
    for sense=senses;sen=sense{1};
        %%
        if isempty(vecs.(sen).lat), warning(['warning, no ' sen ' found!']);return;end
        lamin=round(nanmin(vecs.(sen).lat));
        lamax=round(nanmax(vecs.(sen).lat));
        lainc=5;
        range.(sen).lat= round(linspace(lamin,lamax,(lamax-lamin+1)/lainc));
        %%
        agemin=round(nanmin(vecs.(sen).age));
        agemax=round(nanmax(vecs.(sen).age));
        ageinc=10;
        range.(sen).age= round(linspace(agemin,agemax,(agemax-agemin+1)/ageinc));
        %%
        range.(sen).cum=range.(sen).age;
        %%
        [hc.(sen).lat]=numPerLat(vecs.(sen).lat,DD,ticks,range.(sen).lat,sen);
        %%
        [hc.(sen).age,hc.(sen).cum]=ageCum(vecs.(sen).age,DD,ticks,range.(sen).age,sen);
    end
    
    %%
    ratioBar(hc,'lat', range.Cycs.lat);
    tit='ratio of cyclones to anticyclones as function of latitude';
    title(tit)
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['S-latratio-' sen],DD.debugmode);
    %%
    ratioBar(hc,'age', range.Cycs.age);
    tit='ratio of cyclones to anticyclones as function of age (at death)';
    xlab='age [d] - gray scale indicates total number of eddies available';
    title(tit);
    xlabel(xlab)   ;
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['S-ageratio-' sen],DD.debugmode);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function velZonmeans(DD,IN,ticks)
    plot(IN.la(:,1),IN.maps.zonMean.Rossby.small.phaseSpeed	); 	hold on
    acv=squeeze(nanmean(IN.maps.AntiCycs.vel.zonal.mean,2));
    cv=squeeze(nanmean(IN.maps.Cycs.vel.zonal.mean,2));
    plot(IN.la(:,1),acv	,'r')
    plot(IN.la(:,1),cv,'black')
    axis([DD.map.out.south DD.map.out.north min([min(acv) min(cv)]) max([max(acv) max(cv)]) ])
    legend('Rossby-wave phase-speed','anti-cyclones net zonal velocity','cyclones net zonal velocity')
    ylabel('[cm/s]')
    xlabel('[latitude]')
    title(['velocity - zonal means [cm/s]'])
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['S-velZonmean'],DD.debugmode,'dpdf');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scaleZonmeans(DD,IN,ticks)
    plot(IN.la(:,1),2*IN.maps.zonMean.Rossby.small.radius); 	hold on
    plot(IN.la(:,1),IN.maps.zonMean.AntiCycs.radius.mean.mean,'r')
    plot(IN.la(:,1),IN.maps.zonMean.Cycs.radius.mean.mean,'black')
    set(gca,'xtick',ticks.x	)
    set(gca,'ytick',ticks.y	)
    legend('2 x Rossby Radius','anti-cyclones radius','cyclones radius')
    ylabel('[m]')
    xlabel('[latitude]')
    title(['scale - zonal means'])
    maxr=nanmax(nanmax([IN.maps.zonMean.AntiCycs.radius.mean.mean(:) IN.maps.zonMean.Cycs.radius.mean.mean(:)]));
    axis([min(IN.la(:,1)) max(IN.la(:,1)) 0 maxr])
    savefig(DD.path.plots,ticks.rez,ticks.width,ticks.height,['S-scaleZonmean'],DD.debugmode,'dpdf');
end
