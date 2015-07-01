function sub09_trackstuff
    load S09main II DD T
    flds = {'age';'lat';'lon';'rad';'vel';'velDP';'amp';'radLe';'radLeff';'radL'};
    %     sub09_trackinit(DD);
    % TRv = getVelFunc(DD);
    %  getLonFunc(DD);
    TR=getTR(DD,flds) ;
    
    %%
    senses=DD.FieldKeys.senses;
    catsen= @(f) [TR.(senses{1}).(f); TR.(senses{2}).(f) ];
    S.t2l=@(t) round(linspace(t(1),t(2),t(3)));
    
    %%
    for ff=1:numel(flds)
        fld = flds{ff};
        eval([fld ' = catsen(''' fld ''');']);
    end
    %%
    rad = round(rad/1000);
    radLe = round(radLe/1000);
    radLeff = round(radLeff/1000);
    radL = round(radL/1000);
    vel = vel*100;
    velDP = velDP*100;
    %%
    S.rightyscalenum = 5;
    for ff = 1:numel(flds)
        fld = flds{ff};
        eval([fld '(end+1:end+S.rightyscalenum) = 0;']);
    end
    age(end-S.rightyscalenum+1:end) = max(age)-0;
    lat(end-S.rightyscalenum+1:end) = S.t2l([min(lat) max(lat) S.rightyscalenum]);
    lon(end-S.rightyscalenum+1:end) = S.t2l([min(lon) max(lon) S.rightyscalenum]);
    rad(end-S.rightyscalenum+1:end) = S.t2l([min(rad) max(rad) S.rightyscalenum]);
    
    %%
    [~,sml2lrg] = sort(rad)  ; %#ok<ASGLU>
    
    for ff=1:numel(flds)
        fld = flds{ff};
        eval(['S.(fld) = ' fld '(fliplr(sml2lrg));']);
    end
    
    %% kill unrealistic data
    zerage  = S.age<=0  ;
    velHigh = S.vel>30 | S.vel <-30;
    radnill = isnan(S.rad) | S.rad==0;
    %    SOonly  = S.lat > -30 | S.lat < -70 ;
    %    killTag = zerage | velHigh | radnill | SOonly  | S.age<30;
    killTag = zerage | velHigh | radnill ;
    FN=fieldnames(S);
    for ii=1:numel(FN)
        try
            S.(FN{ii})(killTag)=[];
        end
    end
    %%
    fn=fnA;
    %%
    %     save SaviI
    velZonmeans(S,DD,II,T,fn.vel);
    %     velDPZonmeans(S,DD,II,T,fn.velDP);
    %     scaleZonmeans(S,DD,II,T,fn.sca);
    %     scattStuff(S,T,DD,II);
    %%
    %     fnB(fn);
    %aa= griddata(wrapTo180(S.lon),S.lat,abs(S.vel),(-180:.01:180)',-70:.01:-30);
    %imagesc((-180:.01:180)',-70:.01:-30,flipud(aa))
    %colorbar
    %%     pcolor(aa);shading flat
    %caxis([0 10])
    %hold on
    %load coast
    %plot(long,lat,'black','linewidth',3)
    %     [~,b]=sort(S.iq);
    %     SS=1:100:1400745;
    %
    %     scatter(S.iq(SS),(S.age(SS)),1,abs(S.rad(SS)))
    %     colorbar
    % %     caxis([0 300])
    %     colormap(jet(100))
    %     set(gcf,'windowStyle','docked')
    %     axis tight
    
    %     scatter(S.iq,S.lat,abs(S.vel),log(S.age))
    %%%
    %% scatter(S.lat,log(abs(S.amp)),log(S.age),log(abs(S.vel)))
    %scatter(S.lon,S.lat,1,(abs(S.vel)))
    %cb=colorbar
    %caxis([0 10])
    %% set(cb,'yticklabel',exp(get(cb,'ytick')))
    %set(cb,'yticklabel',(get(cb,'ytick')))
    %axis tight
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fn=fnA
    fn.vel= 'S-velZonmean4chelt11comp';
    fn.velDP= 'S-velDPZonmean4chelt11comp';
    fn.sca= 'S-scaleZonmean4chelt11comp';
    fn.scaRat= 'S-scaleRatios';
    fn.combo = 'Schelts';
    [fn.roo,fn.pw]=fileparts(pwd);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fnB(fn)
    fn.plts = [fn.roo '/PLOTS/' fn.pw '/'];
    system(['pdfjam --nup 2x1 -o ' fn.plts fn.combo '.pdf ' fn.plts fn.vel '.pdf '  fn.plts fn.sca '.pdf']);
    system(['pdfcrop --margins "1 1 1 1" ' fn.plts fn.combo '.pdf '  fn.plts fn.combo '.pdf ' ]);
    cpPdfTotexMT(fn.combo);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h=scaleZonmeans(S,DD,II,T,outfname) %#ok<INUSD>
    %     s The right panel shows meridional proﬁles of the average (solid line) and the interquartile range of the distribution of Ls (gray shading) in 1° latitude bins. The long dashed line is the meridional proﬁle of the average of the e-
    % folding scale Le of a Gaussian approximation of each eddy (see Appendix B.3). The short dashed line represents the 0.4° feature resolution limitation of the SSH ﬁelds of the
    % AVISO Reference Series for the zonal direction (see Appendix A.3) and the dotted line is the meridional proﬁle of the average Rossby radius of deformation from Chelton et al.
    % (1998).
    
    S.beta = 2*(2*pi/(24*60*60))/earthRadius * cosd(S.lat);
    S.rhinesScale = sqrt(S.amp./(S.beta.*S.rad*1000));
    
    close all
    chelt = imread('/scratch/uni/ifmto/u300065/FINAL/presStuff/LTpresMT/FIGS/png1024x/chSc.png');
    LA     = round(S.lat);
    LAuniq = unique(LA)';
    %     FN     = {'rad','radL','radLe','radLeff'};
    %     FN     = {'rad','radLe','rhinesScale'};
    FN     = {'rad','radLe'};
    %     FN     = {'Lrossby'};
    %     Rpath = DD.path.Rossby.name;
    %     Rname = [DD.FieldKeys.Rossby{2} ,'.mat'];
    %     LR = getfield(load([Rpath Rname]),'data');
    %     zerFlag = S.reflin == 0;
    %     S.reflin(zerFlag) = 1;
    %     S.Lrossby = LR(S.reflin)/1000; % m2km
    %     S.Lrossby(zerFlag) = nan;
    for ff=1:numel(FN)
        fn=FN{ff};
        S.(fn)(S.(fn)<10) = nan;
    end
    %%
    visits = nan(size(LAuniq));
    for ff=1:numel(FN)
        fn=FN{ff};
        vvM(numel(LAuniq)).(fn)=struct;
        vvMed(numel(LAuniq)).(fn)=struct;
        [vvM(:).(fn)]=deal(nan);
        [vvMed(:).(fn)]=deal(nan);
        
        for cc=1:(numel(LAuniq))
            idx=LA==LAuniq(cc);
            visits(cc) = sum(idx);
            
            if visits(cc) >= 100
                vvMed(cc).(fn)=nanmedian(S.(fn)(idx));
                vvM(cc).(fn)=nanmean(S.(fn)(idx));
                if abs(LAuniq(cc))<=5
                    vvM(cc).(fn)=nan;
                    vvMed(cc).(fn)=nan;
                end
            end
        end
    end
    %
    h.ch=chOverLayScale(chelt,LAuniq,vvM,vvMed);
    %     grid minor
    savefig(DD.path.plots,72,400,300,outfname,'dpdf',DD2info(DD),12);
    cpPdfTotexMT(outfname);
    %
    %     %
    %     	[h.own,pp,dd]=ownPlotScale(DD,II,LAuniq,vvM,vvS); %#ok<NASGU>
    %     	[~,pw]=fileparts(pwd);
    %     	save(sprintf('scaleZonMean-%s.mat',pw),'h','pp','dd');
    %     	savefig(DD.path.plots,T.rez,800,800,['S-scaleZonmean'],'dpdf',DD2info(DD));
    
    %% TODO
    figure; clf;
    fn=FN{1};
    
    [~,cc]=min(abs(LAuniq-(-10)));
    idx10=LA==LAuniq(cc);
    [~,cc]=min(abs(LAuniq-(-60)));
    idx50=LA==LAuniq(cc);
    histogram(S.(fn)(idx10),[10:10:500])
    axis tight
    yl=get(gca,'yLim');
    set(gca,'ytick',round([yl/2 yl(2)]))
    xlabel('$\sigma$ at $-10^{\circ}$')
    %     killevery2ndytl;
    title(sprintf('total: %d counts',sum(idx10)))
    %
    savefig('./',T.rez,300,250,'a','dpdf',DD2info(DD));
    close all;      clf
    histogram(S.(fn)(idx50),[10:3:200])
    set(gca,'yaxisLocation','right')
    axis tight
    yl=get(gca,'yLim');
    set(gca,'ytick',round([yl/2 yl(2)]))
    title(sprintf('total: %d counts',sum(idx50)))
    xlabel('$\sigma$ at $-50^{\circ}$')
    savefig('./',T.rez,300,250,'b','dpdf',DD2info(DD));
    %     killevery2ndytl;
    %%
    fname='hist-sigmaAt-both';
    system(['pdfjam --nup 2x1 -o c.pdf a.pdf b.pdf'])
    system(['pdfcrop c.pdf ' DD.path.plots fname '.pdf'])
    cpPdfTotexMT(fname);
    system(['rm ?.pdf'])
end
function scaleZonmeansLeSigmaRatio(S,DD,II,T,outfname)
    close all
    LA     = round(S.lat);
    LAuniq = unique(LA)';
    %     FN     = {'rad','radL','radLe','radLeff','rhinesScale'};
    FN     = {'rad','radLe'};
    for ff=1:numel(FN)
        fn=FN{ff};
        S.(fn)(S.(fn)<5) = nan;
    end
    %%
    visits = nan(size(LAuniq));
    for ff=1:numel(FN)
        fn=FN{ff};
        [vvM.(fn)]  = nan(size(LAuniq));
        [vvMed.(fn)]= nan(size(LAuniq));
        for cc=1:(numel(LAuniq))
            idx=LA==LAuniq(cc);
            visits(cc) = sum(idx);
            
            if visits(cc) >= 100
                vvMed.(fn)(cc) = nanmedian(S.(fn)(idx));
                vvM.(fn)(cc)   = nanmean(S.(fn)(idx));
                if abs(LAuniq(cc))<=5
                    vvM.(fn)(cc)   = nan;
                    vvMed.(fn)(cc) = nan;
                end
            end
        end
    end
    %%
    figure(1)
    clf
    pl =  plot(LAuniq,vvM.rad./vvM.radLe);  hold on
    plot(LAuniq,vvMed.rad./vvMed.radLe,'color',pl.Color,'linestyle',':');
    title('\textit{ratio } $\sigma/\mathrm{L_e}$')
    xlabel('latitude')
    %     legend('MII','MI','median','location','northwest')
    grid on
    axis([-75 75 1.1 1.6])
    set(gca,'ytick',[1.1:.1:1.6])
    set(gca,'xtick',[-70:10:70])
    
    %%
    grid minor
    savefig(DD.path.plots,72,500,200,outfname,'dpdf',DD2info(DD),15);
    cpPdfTotexMT(outfname);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h=velDPZonmeans(S,DD,II,T,fn)
    close all
    LA     = round(S.lat);
    LAuniq = unique(LA)';
    vvM=nan(size(LAuniq));
    visits = nan(size(LAuniq));
    for cc=1:(numel(LAuniq))
        idx=LA==LAuniq(cc);
        visits(cc) = sum(idx);
        if visits(cc) >= 10 % TODO!!!!!!!!
            vvM(cc)=nanmedian(S.velDP(idx));
        end
    end
    
    vvM(abs(LAuniq)<5)=nan;
    %%
    chelt = imread('/scratch/uni/ifmto/u300065/FINAL/PLOTS/chelt11Ucomp.jpg');
    chelt= chelt(135:3595,415:3790,:);
    h.ch=chOverLay(chelt,LAuniq,vvM);
    savefig(DD.path.plots,72,400,300,fn,'dpdf',DD2info(DD),12);
    cpPdfTotexMT(fn)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h=velZonmeans(S,DD,II,T,fn)
    
    %     Rpath = DD.path.Rossby.name;
    %     Rname = [DD.FieldKeys.Rossby{1} ,'.mat'];
    %     cR = getfield(load([Rpath Rname]),'data');
    %     zerFlag = S.reflin == 0;
    %     S.reflin(zerFlag) = 1;
    %     S.Crossby = cR(S.reflin)*100; % m2cm
    %     S.Crossby(zerFlag) = nan;
    
    
    %   LA     = round(S.lon);
    %     LAuniq = unique(LA)';
    %     vvM=nan(size(LAuniq));
    %
    %
    %     visits = nan(size(LAuniq));
    %     for cc=1:(numel(LAuniq))
    %         idx=LA==LAuniq(cc);
    %         visits(cc) = sum(idx);
    %     end
    
    
    close all
    LA     = round(S.lat);
    LAuniq = unique(LA)';
    vvM=nan(size(LAuniq));
    vvS=nan(size(LAuniq));
    
    vvSkew=nan(size(LAuniq));
    visits = nan(size(LAuniq));
    for cc=1:(numel(LAuniq))
        idx=LA==LAuniq(cc);
        visits(cc) = sum(idx);
        if visits(cc) >= 100 % TODO!!!
            vvM(cc)=nanmedian(S.vel(idx));
            vvS(cc)=std(S.vel(idx));
            vvSkew(cc)=skewness(S.vel(idx));
        end
    end
    %%
    % TODO do this with pop7 or better pop3 data ! and maybe do similar with
    % scales..
    
    vvM(abs(LAuniq)<5)=nan;
    
    %     save pop1IIVM vvM LAuniq
    
    
    %     vvS(abs(LAuniq)<5)=nan;
    
    %%
    %     [h.own,~,dd]=ownPlotVel(DD,II,LAuniq,vvM,vvS); %#ok<NASGU>
    %     [~,pw]=fileparts(pwd);
    %     save(sprintf('velZonMean-%s.mat',pw),'h','pp','dd');
    %     savefig(DD.path.plots,T.rez,800,800,['S-velZonmean'],'dpdf',DD2info(DD));
    
    
    pop1II = load('../pop1IIC/pop1IIVM')
    hold on
    chOverLay(chelt,pop1II.LAuniq,pop1II.vvM,8,0);
    savefig(DD.path.plots,72,400,300,'pop2Andpop7velZonMean','dpdf',DD2info(DD),12);
    
    
    
    %%
    chelt = imread('/scratch/uni/ifmto/u300065/FINAL/PLOTS/chelt11Ucomp.jpg');
    chelt= chelt(135:3595,415:3790,:);
    h.ch=chOverLay(chelt,LAuniq,vvM,5,1);
    savefig(DD.path.plots,72,400,300,fn,'dpdf',DD2info(DD),12);
    cpPdfTotexMT(fn)
    %       figure
    %     h.ch=chOverLay(S,DD,chelt,LAuniq,vvCross);
    %     title([])
    %     savefig(DD.path.plots,T.rez,800,800,['S-RossbyCfromPopToCh'],'dpdf',DD2info(DD));
    %
    figure(10)
    clf
    nrm=@(x) x/nanmax(x-nanmin(x));
    SK(:,1) = nrm(smooth(-vvM,10));
    SK(:,2) = nrm(smooth(-vvSkew,10));
    SK(:,3) = nrm(smooth(visits,10))*.8;
    plot(repmat(LAuniq',1,3), SK)
    hold on
    axis([-80 80 -1 1])
    axis tight
    legend('-u','-skew(u)','count')
    plot([-70 70],[0 0],'--black')
    grid on
    set(gca,'yticklabel','')
    savefig(DD.path.plots,T.rez,400,200,['Skew'],'dpdf',DD2info(DD));
    cpPdfTotexMT('Skew')
    %     %
    %     %
    %
    %% TODO
    figure(2)
    cc = 70;
    idx=LA==LAuniq(cc); % -10
    hist(S.vel(idx),50)
    axis tight
    xlabel('$u$ [cm/s] at $-10^{\circ}$')
    title(sprintf('total: %d counts',sum(idx)))
    savefig(DD.path.plots,T.rez,600,600,['hist-uAt-10deg'],'dpdf',DD2info(DD));
    
    
    figure(3)
    cc = 30;
    idx=LA==LAuniq(cc); % -50
    hist(S.vel(idx),50)
    axis tight
    xlabel('$u$ [cm/s] at $-50^{\circ}$')
    title(sprintf('total: %d counts',sum(idx)))
    savefig(DD.path.plots,T.rez,600,600,['hist-uAt-50deg'],'dpdf',DD2info(DD));
    %
    %
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [h,pp,dd]=ownPlotVel(DD,II,LAuniq,vvM,vvS) %#ok<*DEFNU>
    %%
    clf
    lw=2;
    %%
    dd(1).y=-II.maps.zonMean.Rossby.small.phaseSpeed*100;
    dd(2).y=-vvM;
    dd(4).y=-vvM+vvS;
    dd(5).y=-vvM-vvS;
    dd(3).y= [0 0];
    %%
    dd(1).name='rossbyPhaseSpeed';
    dd(2).name='zonal mean eddy phase speeds';
    dd(4).name='std upper bound';
    dd(5).name='std lower bound';
    dd(3).name='nill line';
    %%
    dd(1).x=II.la(:,1);
    dd(2).x=LAuniq;
    dd(4).x=LAuniq;
    dd(5).x=LAuniq;
    geo=DD.map.window.geo;
    dd(3).x=[geo.south geo.north];
    %%
    pp(1)=plot(dd(1).x,dd(1).y); 	hold on
    pp(2)=plot(dd(2).x,dd(2).y,'r');
    pp(4)=plot(dd(4).x,dd(4).y,'r');
    pp(5)=plot(dd(5).x,dd(5).y,'r');
    pp(3)=plot(dd(3).x,dd(3).y,'b--');
    %%
    axis([-70 70 -5 20])
    set(pp(1:3),'linewidth',lw)
    leg=legend('Rossby-wave phase-speed',2,'all eddies',2,'std');
    legch=get(leg,'children');
    set( legch(1:3),'linewidth',lw)
    ylabel('[cm/s]')
    xlabel('[latitude]')
    title(['westward propagation [cm/s]'])
    set(get(gcf,'children'),'linewidth',lw)
    grid on
    h=gcf;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ownPlotScale
    
    a = load('../aviII/SaviII.mat');
    aI = load('../aviI/SaviI.mat');
    p = load('../p2aII/Sp2aII.mat');
    m = load('../pop7II/Spop7II.mat');
    %%
    AP = {'a';'aI';'p';'m'};
    for aa=1:4
        ap = AP{aa};
        eval([ 'LA.' ap ' = round(' ap '.S.lat);'])
        eval([ 'LO.' ap ' = round(' ap '.S.lon);'])
        LALO.(ap) = LA.(ap) + 1i*LO.(ap);
    end
    %     LAuniq     = unique([ LA.p; LA.a;LA.aI; LA.m]');
    LALOuniq     =  intersect(LALO.p,intersect(LALO.a,intersect(LALO.aI, LALO.m)));
    LAuniq = unique(real(LALOuniq));
    fn     = 'rad';
    
    for aa=1:4
        ap = AP{aa};
        eval([ap '.S.(fn)( ~ismember(LALO.' ap ',LALOuniq )) = nan;'])
        eval([ap '.S.(fn)( ' ap '.S.(fn)<5 ) = nan;'])
    end
    
    
    %%
    for aa=1:4
        ap = AP{aa};
        visits.(ap) = nan(size(LAuniq));
        vvM.(ap) = visits.(ap);
        vvMe.(ap) = visits.(ap);
        for cc=1:(numel(LAuniq))
            idx.(ap)=LA.(ap)==LAuniq(cc);
            visits.(ap)(cc) = sum(idx.(ap));
            if visits.(ap)(cc) >= 100
                eval(['vvM.(ap)(cc)  =   nanmean(' ap '.S.(fn)(idx.(ap)));'])
                eval(['vvMe.(ap)(cc) = nanmedian(' ap '.S.(fn)(idx.(ap)));'])
                if abs(LAuniq(cc))<=5
                    vvM.(ap)(cc)=nan;
                    vvMe.(ap)(cc)=nan;
                end
            end
        end
    end
    
    %%
    figure(1)
    clf
    pl = plot(LAuniq,vvM.a - vvM.p,LAuniq,vvM.aI - vvM.p);
    hold on
    plot(LAuniq,vvMe.a - vvMe.p,'linestyle',':','color',pl(1).Color)
    plot(LAuniq,vvMe.aI - vvMe.p,'linestyle',':','color',pl(2).Color)
    title('\textit{satellite - remapped model}')
    xlabel('latitude')
    ylabel('$\sigma$ [km]')
    legend('MII','MI','median','location','northwest')
    grid on
    axis([-75 75 -12 42])
    
    plot([-75 75],[0 0],'black--')
    plot([0 0],[-12 42],'black--')
    set(gca,'ytick',[-10:10:40])
    set(gca,'xtick',[-70:10:70])
    
    %%
    outfname = 'sigmaSatMinusP2aINTRSCTLOLA';
    savefig(aI.DD.path.plots,72,500,200,outfname,'dpdf',DD2info(aI.DD),15);
    cpPdfTotexMT(outfname);
    %%
    figure(2)
    clf
    pl = plot(LAuniq,vvM.a - vvM.m,LAuniq,vvM.aI - vvM.m);
    hold on
    plot(LAuniq,vvMe.a - vvMe.m,'linestyle',':','color',pl(1).Color)
    plot(LAuniq,vvMe.aI - vvMe.m,'linestyle',':','color',pl(2).Color)
    
    title('\textit{satellite - model}')
    %      xlabel('latitude')
    ylabel('$\sigma$ [km]')
    %     legend('MII','MI','location','northwest')
    grid on
    axis([-75 75 -12 42])
    hold on
    plot([-75 75],[0 0],'black--')
    plot([0 0],[-12 42],'black--')
    set(gca,'ytick',[-10:10:40])
    set(gca,'xtick',[-70:10:70])
    
    %%
    outfname = 'sigmaSatMinusModelbINTRSCTLOLA';
    savefig(aI.DD.path.plots,72,500,200,outfname,'dpdf',DD2info(aI.DD),15);
    cpPdfTotexMT(outfname);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h=chOverLayScale(chelt,LAuniq,vvM,vvMed)
    clf
    [Y,X,Z]=size(chelt);
    ch=reshape(flipud(reshape(chelt,Y,[])),[Y,X,Z]);
    ch=permute(reshape(fliplr(reshape(permute(ch,[3,1,2]),1,[])),[Z,Y,X]),[2,3,1]);
    ch=permute(reshape(flipud(reshape(permute(ch,[2,1,3]),[X,Y*Z])),[X,Y,Z]),[2,1,3]);
    %%
    imagesc(linspace(-70,70,X),linspace(0,275,Y),ch)
    hold on
    %%
    FN=fieldnames(vvM)';
    for ff=1:numel(FN)
        lau=LAuniq;
        kill.lau = isnan(lau) | abs(lau)>70;
        fn=FN{ff};
        vvm=-cat(2,vvM.(fn))+275;
        kill.vvm = isnan(vvm);
        kill.both = kill.lau | kill.vvm;
        vvm(kill.both)=nan;
        lau(kill.both)=nan;
        x(:,ff)=lau;
        y(:,ff)=vvm;
    end
    PP=plot(x,y,'linewidth',.8);
    
    %%
    FN=fieldnames(vvMed)';
    for ff=1:numel(FN)
        lau=LAuniq;
        kill.lau = isnan(lau) | abs(lau)>70;
        fn=FN{ff};
        vvm=-cat(2,vvMed.(fn))+275;
        kill.vvm = isnan(vvm);
        kill.both = kill.lau | kill.vvm;
        vvm(kill.both)=nan;
        lau(kill.both)=nan;
        x(:,ff)=lau;
        y(:,ff)=vvm;
    end
    
    PP2=plot(x,y,'linewidth',.8,'linestyle',':');
    set(PP2(1),'color',PP(1).Color)
    set(PP2(2),'color',PP(2).Color)
    legend('\sigma','L_e','medians')
    
    %%
    set(gca, 'ytick', 0:25:275);
    axis([-70 70 0 275])
    set(gca, 'yticklabel', flipud(get(gca,'yticklabel')));
    %     axis tight
    grid on
    ylabel('[km]')
    xlabel('latitude')
    h.fig=gcf;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h=chOverLay(chelt,LAuniq,vvM,prla,backgr)
    [Y,X,Z]=size(chelt);
    ch=reshape(flipud(reshape(chelt,Y,[])),[Y,X,Z]);
    ch=permute(reshape(fliplr(reshape(permute(ch,[3,1,2]),1,[])),[Z,Y,X]),[2,3,1]);
    ch=permute(reshape(flipud(reshape(permute(ch,[2,1,3]),[X,Y*Z])),[X,Y,Z]),[2,1,3]);
    %%
    y=vvM+15;
    x=LAuniq;
    kill=isnan(x) | isnan(vvM) | abs(x)<10 | abs(x)>65;
    x(kill)=nan;
    y(kill)=nan;
    %%
    %     clf
    if backgr
        imagesc(linspace(-50,50,X),linspace(-5,20,Y),ch)
    end
    hold on
    plot(x,y,'linewidth',.8,'color',getParula(prla,10));
    set(gca, 'yticklabel', flipud(get(gca,'yticklabel')));
    axis tight
    grid on
    ylabel('[cm/s]')
    xlabel('latitude')
    %     title(['westward propagation [cm/s]'])
    axis([-65 65 -5 20])
    h=gcf;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scattStuff(S,T,DD,II) %#ok<*INUSD>
    age=S.age;
    lat=S.lat;
    vel=S.vel;
    rad=round(S.rad);
    inc=1;
    %%
    clf
    oie=@(inc,x) x(1:inc:end);
    incscatter=@(inc,a,b,c,d) scatter(oie(inc,a),oie(inc,b),oie(inc,c),oie(inc,d));
    incscatter(inc,age,lat,rad/10,abs(vel));
    grid on
    axis tight
    set(gca,'XAxisLocation','bottom')
    cb=colorbar;
    cb1 = findobj(gcf,'Type','axes','Tag','Colorbar');
    cbIm = findobj(cb1,'Type','image');
    alpha(cbIm,0.5)
    T.vel = [0 10 11];
    set(cb,'location','north','xtick',(S.t2l(T.vel)),'xlim',T.vel([1 2]))
    %     colormap(jet(100));
    doublemap([T.vel(1) 0 T.vel(2)],autumn(50),winter(50),[.9 1 .9],20)
    h1=gca;
    h1pos = get(h1,'Position'); % store position of first axes
    h2 = axes('Position',h1pos,...
        'XAxisLocation','top',...
        'YAxisLocation','right',...
        'Color','none');
    set(h2, ...
        'ytick',linspace(0,1,S.rightyscalenum),...
        'xtick',[],...
        'yticklabel',(S.t2l([min(rad) max(rad) S.rightyscalenum])))
    set(h1, ...
        'ytick',[-50 -30 -10 0 10 30 50],...
        'xtick',S.t2l(T.age))
    ylabel(h2,'radius [km]')
    ylabel(h1,'lat  [$^{\circ}$]')
    xlabel(h1,'age [d]')
    xlabel(h2,'zon. vel.  [cm/s] - eddies beyond scale dismissed!')
    set(get(gcf,'children'),'clipping','off')
    %%
    %  figure(1)
    savefig(DD.path.plots,1.5*T.rez,2*T.width,2*T.height,['sct-ageLatRadUabs'],'dpdf',DD2info(DD));
    %     savefig(DD.path.plots,T.rez,T.width,T.height,['sct-ageLatRadU'],'dpng',DD2info(DD));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TR=getTR(DD,F)
    xlt=@(sen,f) extractfield(load(['TR-' sen '-' f '.mat']),'tmp');
    g=@(c) cat(1,c{:});
    for ss=1:2
        sen=DD.FieldKeys.senses{ss};
        for fi=1:numel(F);f=F{fi};
            TR.(sen).(f)=((xlt(sen,f))');
        end
        f='vel';
        TR.(sen).(f)=g(g(xlt(sen,f)));
        f='velDP';
        TR.(sen).(f)=g(g(xlt(sen,f)));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TR=getVelFunc(DD)
    xlt=@(sen,f) extractfield(load(['TR-' sen '-' f '.mat']),'tmp');
    g=@(c) cat(1,c{:});
    for ss=1:2
        sen=DD.FieldKeys.senses{ss};
        f='vel';
        TR.(sen).vel = g(xlt(sen,f));
        TR.(sen).std = cellfun(@std, TR.(sen).vel);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function getLonFunc(DD)
    Fs = DD.path.tracks.files;
    
    T=disp_progress('init','stdTracksArcLens');
    lims = thread_distro(12,numel(Fs));
    spmd(12)
        arclendiffStd = nan(diff(lims(labindex,:))+1,1);
        cc=0;
        for ff = lims(labindex,1):lims(labindex,2)
            cc=cc+1;
            %             for ff = 1:numel(Fs)
            T=disp_progress('calc',T,diff(lims(labindex,:))+1,100);
            track = cell2mat(extractfield(getfield(load([DD.path.tracks.name Fs(ff).name ]),'track'),'geo'));
            la = cat(1,track.lat);
            lo = cat(1,track.lon);
            arclendiffStd(cc) = nanstd(distance(la(1:end-1),lo(1:end-1),la(2:end),lo(2:end)));
        end
        arclendiffStdCat = gcat(arclendiffStd,1,1);
    end
    arclendiffStdCat = arclendiffStdCat{1};
    %%
    
    %%
    save([DD.path.analyzed.name 'arclendiffStd.mat'],'arclendiffStdCat')
    %%
    D.II = arclendiffStdCat;
    D.I  = load([ strrep(DD.path.analyzed.name,'aviII','aviI') 'arclendiffStd.mat'],'arclendiffStdCat');
end
