clearvars -EXCEPT GLOBAL_VARS
close all
addpath(genpath('./SUBS'));
dbstop if error
%global threads
%##########################################################################
%%
DIM.Xdim=360*.25+1;
DIM.Ydim=160*5+1;
DIM.Ya=-80;
DIM.Yb=80;
DIM.Xa=-180;
DIM.Xb=180;
DIM.round=1; % number of decimals in grid
%DIM.round=max([numel(num2str(mod((DIM.Xb-DIM.Xa)/(DIM.Xdim-1),1)))-2, numel(num2str((mod((DIM.Yb-DIM.Ya)/(DIM.Ydim-1),1))))-2]);
%%
I.del_time=24*60*60;
I.minage=20;
%%
I.file_in='/scratch/uni/ifmto/u300065/new_tracks2';
threads=2;

%%
I.stepsize=10;

%##########################################################################
init_threads(threads)

%%  get data
if ~exist('GLOBAL_VARS','var')
    disp('loading data...');   load([I.file_in,'.mat']);      addpath(genpath('./SUBS'));
end

%% calc stats
[STATS]=posteddies_getstats(GLOBAL_VARS,I);
DIM.lon=GLOBAL_VARS.lon;
DIM.lon=GLOBAL_VARS.lon;
disp('saving')
OUTAC = rmfield(STATS(1),{'POS';'TIME';'DIAM';'AREA';'AGE'});
OUTC = rmfield(STATS(2),{'POS';'TIME';'DIAM';'AREA';'AGE'});
%save([I.file_in,'_processed_AC'],'OUTAC');
%save([I.file_in,'_processed_C'],'OUTC');
%load([I.file_in,'_processed_AC']);
%load([I.file_in,'_processed_C']);
%STATS=[OUTAC OUTC];

%% prepare for plots
[STATS]=posteddies_PrepForPlot(DIM,STATS);
disp('saving')
OUTAC = rmfield(STATS(1),{'POS';'TIME';'DIAM';'AREA';'AGE'});
OUTC = rmfield(STATS(2),{'POS';'TIME';'DIAM';'AREA';'AGE'});
save([I.file_in,'_plotable_AC'],'OUTAC');
save([I.file_in,'_plotable_C'],'OUTC');
% load([I.file_in,'_plotable_AC']);
% load([I.file_in,'_plotable_C']);
% STATS=[OUTAC OUTC];
% STATS=[catstruct(STATS(1), posteddies_init(GLOBAL_VARS.ARCHV.AntiCyclonic,I.minage)) catstruct(STATS(2), posteddies_init(GLOBAL_VARS.ARCHV.Cyclonic,I.minage)) ];

%% further data prep...
vz=STATS(1).remapped.means.mean_velocities.zonal;
%vtraj=STATS(1).remapped.vels.mean_velocities.trajec;
%vtraj_signed=vtraj.*sign(vz);
vnet=vtraj_signed-vz;
vnetb=vtraj-abs(vz);

%% ...
clear DIST
DIST(2)=struct;
for ss=1:2
    DIST(ss).birth.netzon=STATS(ss).remapped.dist.atplaceofbirth.netZonal;
    DIST(ss).birth.full=STATS(ss).remapped.dist.atplaceofbirth.full;
    DIST(ss).death.netzon=STATS(ss).remapped.dist.atplaceofbirth.netZonal;
    DIST(ss).death.full=STATS(ss).remapped.dist.atplaceofbirth.full;
end




BVfile='/scratch/uni/ifmto/u300065/TEMP_BRUNT.nc';
ncdisp(BVfile)
BV=ncread(BVfile,'Brunt Vaisala squared');
load('/scratch/uni/ifmto/u300065/c_phase_one.mat');
BV=permute(BV,[2,1,3]);
c1=c1'; lat=lat';
c1lonm=nanmean(c1,2);
f=(2*sind(STATS(1).DIM.lon)*2*pi/(23.9344696*60*60));
beta=(2*cosd(STATS(1).DIM.lon)*2*pi/(23.9344696*60*60))/earthRadius;
Ro=c1./f;
eqflag=abs(STATS(1).DIM.lon)<5;
Ro(eqflag)=sqrt(c1(eqflag)/2./beta(eqflag));
pcolor(sqrt(abs(Ro(1:10:end,1:10:end))/1000));shading flat;cb=colorbar;
caxis([0 sqrt(300)])
set(cb,'ytick',sqrt([1 10 50 100 150 200 250 300])')
set(cb,'yticklabel',[1 10 50 100 150 200 250 300]')
figure
[c,h]=contour(abs(Ro(1:10:end,1:10:end))/1000,[0 10 50 100 150 250]);shading flat;colorbar;clabel(c,h)

Ro_rempd=remap(STATS(1).DIM.lon(:),STATS(1).DIM.lon(:),STATS(1).DIM.GLO,STATS(1).DIM.GLA,Ro);
beta=(2*cosd(STATS(1).DIM.GLA)*2*pi/(23.9344696*60*60))/earthRadius;

CR1l=- beta.*Ro_rempd.^2;
pcolor(CR1l);shading flat
colorbar
caxis([-.2 0])
figure
pcolor(vz);shading flat
colorbar
caxis([-.2 .2])

figure
[c,h]=contourf(CR1l-vz,[-.2 -.1 -.05 0 0.05 0.1]);
clabel(c,h);
colorbar


vzac=STATS(1).remapped.means.mean_velocities.zonal;
vzc=STATS(2).remapped.means.mean_velocities.zonal;
vzaclonm=nanmean(vzac,2);
vzclonm=nanmean(vzc,2);

CR1llonnm=nanmean(CR1l,2);



Rolonm=nanmean(Ro,2);

%% size
 
close all

sens={'anti-cyclonic','cyclonic'};
  


xx=linspace(-80,80,numel(vzclonm))
CR1llonnm(abs(xx)<10)=nan;
[AX,H1,H2] =plotyy(xx,-vzaclonm,xx,-vzclonm)
hold on; [H3]=plot(xx,-CR1llonnm,'r')
axis(AX(:),[-80 80 -.02 .2])
legend([H1,H2,H3],'zonal anti-cyc. eddy translation vel. west [m/s]','zonal cyc. eddy translation vel. west [m/s]','mode 1 long rossby wave phase speed west')
  dina4pdf(gcf,1,1,'test','landscape');



for ss=1:2
   
   subplot(1,2,ss)
D=STATS(ss).remapped.means.diameter/1000;
V=STATS(ss).remapped.means.mean_velocities.zonal;
Dm=nanmean(D,2);
Vm=nanmean(V,2)*1000;
Rom=nanmean(Ro_rempd,2)/1000;
xx=linspace(-80,80,numel(Dm))
Rom(abs(xx)<10)=nan;
Vm(abs(xx)<10)=nan;
Dm(abs(xx)<10)=nan;
xx(abs(xx)<10)=nan;
if ss==1
Dmax=max(Dm);
Vmax=max(abs(Vm));
end
[AX,H1,H2] =plotyy(xx,Dm/Dmax,xx,-Vm/Vmax)
hold on; [H3]=plot(xx,abs(Rom)/Dmax,'r')
axis(AX(:),[-80 80 0 1])
set(AX(1),'ytick',linspace(0,1,5)')
set(AX(1),'yticklabel',num2str(round(linspace(0,Dmax,5)')))
set(AX(2),'ytick',linspace(0,1,5)')
set(AX(2),'yticklabel',num2str(round(linspace(0,Vmax,5)')))
legend([H1,H2,H3],'scale [km]','translation speed [mm/s west]','Ro_1 [km]')
title([sens{ss},': zonal means'])
%   print(fig, '-dpdf',['-r',num2str(rez)],fname )

% 
% M=STATS(1).DIM;
% LO=M.GLO(1,:);
% LA=M.GLA(:,1);
%   
% con=[10 13  15 18 20 25 30  40  50 60 80 100 125 150]
%                 
% cons=log2(con)'
% cons=cons-mod(cons,.1)
% min(diff(cons))
% 
% 
% cm=min(cons):0.1:max(cons)
% 
%   caxis([min(cons) max(cons)])
%       col= rainbow(1, 1, 1 ,1, numel(cm)-1)
%        for cc=2:numel(cm)-1
%            col=[col; rainbow(1, 1, 1 ,cc, numel(cm)-1)]
%        end
%               
%  contourf(LO,LA,D,cons); 
%  hold on; plot(long,lat)
%     colormap(col)
%      caxis([min(cons) max(cons)])
%    colorbar('eastoutside','ytick',cons,'yticklabel',num2str(round(2.^cons)))
% 
%    title([sens{ss},':  eddy scale [km] - interp. on ',num2str(numel(LO)),'long/',num2str(numel(LA)),'lat grid'])

   
end

  dina4pdf(gcf,1,1,'test','landscape');


%%


sens={'anti-cyclonic','cyclonic'};
for ss=1:2
    
close all

    rez=1000;
    xdim=600;
    ydim=800;
    resolution=get(0,'ScreenPixelsPerInch');
    xdim=xdim*rez/resolution;
    ydim=ydim*rez/resolution;
     fig=figure('renderer','zbuffer');
  set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    fname=['./ALL_tracks_age_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    
D=sqrt(STATS(ss).remapped.vels.diameter/1000);
M=STATS(1).DIM;
LO=M.GLO;
LA=M.GLA;
LO3=LO;
LO3(LO<0)=LO(LO<0)+360;
    
    Slongs=[-100 0;-75 25;-5 45; 25 145;45 100;145 295;100 290];
Slats= [  8 80;-80  8; 8 80;-80   8; 8  80;-80   0;  0  80];

hold on
for l=1:5
     m_proj('sinusoidal','long',Slongs(l,:),'lat',Slats(l,:));
       hold on 
 m_grid('fontsize',6,'xticklabels',[],'xtick',[-180:30:360],...
        'ytick',[-80:20:80],'yticklabels',[],'linest','-','color',[.9 .9 .9]);
    hold on 
    m_coast('line');    
      hold on 
      m_pcolor(LO,LA,D); shading flat;hold on 
end

for l=6:7
hold on
 
     m_proj('sinusoidal','long',Slongs(l,:),'lat',Slats(l,:));
       hold on 
 m_grid('fontsize',6,'xticklabels',[],'xtick',[0:30:360],...
        'ytick',[-80:20:80],'yticklabels',[],'linest','-','color',[.9 .9 .9]);   
    m_coast('line');         
      m_pcolor(LO3,LA,D); shading flat;
end

% In order to see all the maps we must undo the axis limits set by m_grid calls:
set(gca,'xlimmode','auto','ylimmode','auto');

   
  colormap(jet);
    caxis([nanmin(D(:)) sqrt(200)]);
    ticks=linspace(nanmin(D(:)),sqrt(200),6)';
    colorbar('southoutside','xtick',ticks,'xticklabel',num2str(round(ticks.^2*10)/10))
  %  set(cb,'ytick',ticks);
  %  set(cb,'yticklabel',num2str(round(ticks.^2*10)/10));
   tit=[sens{ss},': eddy diameter [km]']
    title(tit)
    fname=[sens{ss},'_diameter.png']
      
    print(fig, '-dpng',['-r',num2str(rez)],fname )
    
end












%% tracks

close all


    rez=400;
    xdim=1400;
    ydim=800;
    resolution=get(0,'ScreenPixelsPerInch');
    xdim=xdim*rez/resolution;
    ydim=ydim*rez/resolution;
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    fname=['./ALL_tracks_age_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    


minage=50;
D=GLOBAL_VARS.ARCHV;
LO=GLOBAL_VARS.lon;
LA=GLOBAL_VARS.lon;
PAC=[D.ANTI_CYC.DATA{2} ];
TAC=[D.ANTI_CYC.DATA{1} ];
PC=[D.CYClonAL.DATA{2} ];
TC=[D.CYClonAL.DATA{1} ];
ageflagAC=cell2mat(cellfun(@(x) numel(x)<minage, PAC,'UniformOutput',false));
ageflagC=cell2mat(cellfun(@(x) numel(x)<minage, PC,'UniformOutput',false));
PAC(ageflagAC)=[];
PC(ageflagC)=[];
TAC(ageflagAC)=[];
TC(ageflagC)=[];
AAC=cellfun(@(x) log(x-x(1)+1), TAC,'UniformOutput',false);
AC=cellfun(@(x) log(x-x(1)+1), TC,'UniformOutput',false);
AACa=cat(1,AAC{:});
minage=log(minage);
cmap=jet;% Generate range of color indices that map to cmap


maxage=log(365*10);
kk=linspace(1,maxage,size(cmap,1));
for ee=1:numel(PAC)
    disp_progress(ee,numel(PAC),100)
    
    la=LA(PAC{ee});
    lo=LO(PAC{ee});
    age=AAC{ee};
    
    cm = spline(kk,cmap',age);                  % Find interpolated colorvalue
    cm(cm>1)=1;                               % Sometimes iterpolation gives values that are out of [0,1] range...
    cm(cm<0)=0;
    for ii=1:length(la)-1
        if  abs(lo(ii+1)-lo(ii))<10 % avoid 0->360 jumps
            h(ii)=line([lo(ii) lo(ii+1)],[la(ii) la(ii+1)],'color',cm(:,ii),'LineWidth',0.5);
        end
    end
end


for ee=1:numel(PC)
    disp_progress(ee,numel(PC),100)
    la=LA(PC{ee});
    lo=LO(PC{ee});
    age=AC{ee};   
    cm = spline(kk,cmap',age);                  % Find interpolated colorvalue
    cm(cm>1)=1;                               % Sometimes iterpolation gives values that are out of [0,1] range...
    cm(cm<0)=0;
    for ii=1:length(la)-1
        if  abs(lo(ii+1)-lo(ii))<10 % avoid 0->360 jumps
            h(ii)=line([lo(ii) lo(ii+1)],[la(ii) la(ii+1)],'color',cm(:,ii),'LineWidth',0.5,'LineStyle','--');
        end
    end
end

   
   yticks=[-80 -60 -40 -20 0 20 40 60 80]';
   set(gca,'ytick',yticks);
        xticks=linspace(-180,180,9);
   set(gca,'xtick',xticks) ;   
    title(['All tracks. age color-coded']);
      cb=colorbar;    
  load coast;
  axis([-180 180 -80 80])
   hold on; plot(long,lat,'LineWidth',0.5);
    ageticks=(linspace(0,maxage,10))';   
    set(cb,'ytick',ageticks/maxage*64);
    set(cb,'yticklabel',num2str(round(exp(ageticks))));
    title(['AC tracks, age colorcoded. eddies that died younger ',num2str(minage),' days are excluded'])
    print(fig, '-dpng',['-r',num2str(rez)],fname )

%% tracksstuff

minage=200;
for ss=1:2
   
    close all
    
     rez=600;
    xdim=1200;
    ydim=800;
    resolution=get(0,'ScreenPixelsPerInch');
    xdim=xdim*rez/resolution;
    ydim=ydim*rez/resolution;
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    fname=['./',sens{ss},'tracks_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    
    
    dd=cell2mat(extractfield(STATS(ss).processed,'dist'));
    xx=cellfun(@(ff) cumsum(ff),{dd.x},'UniformOutput',false);
    yy=cellfun(@(ff) cumsum(ff),{dd.y},'UniformOutput',false);
    lat=cellfun(@(x) (x(2:end)),{STATS(ss).processed(:).lon},'UniformOutput',false);
    %latone=cellfun(@(x) ones(length(x)-1,1)*x(1),{STATS(ss).processed(:).lon},'UniformOutput',false);
    lon=cellfun(@(x) (x(2:end)),{STATS(ss).processed(:).lon},'UniformOutput',false);
    
    ageflag=cell2mat(cellfun(@(x) numel(x)<minage,xx,'UniformOutput',false));
    
    xx(ageflag)=[];
    yy(ageflag)=[];
    lat(ageflag)=[];
    lon(ageflag)=[];
   
    equ_clip=8;
    cmap=jet;% Generate range of color indices that map to cmap
    kk=linspace(0,360,size(cmap,1));
    for ee=1:numel(xx)
        disp_progress(ee,numel(xx),100)
        
        la=lat{ee};
        lo=lon{ee};
        x=1000*deg2km(xx{ee});
        y=1000*deg2km(yy{ee})+deg2rad(la(1)-sign(la(1))*equ_clip)*earthRadius;
        c=lo;
        c(lo<0)=(c(lo<0)+360);
        cm = spline(kk,cmap',c);                  % Find interpolated colorvalue
        cm(cm>1)=1;                               % Sometimes iterpolation gives values that are out of [0,1] range...
        cm(cm<0)=0;
        for ii=1:length(x)-1
           
            h(ii)=line([x(ii) x(ii+1)],[y(ii) y(ii+1)],'color',cm(:,ii),'LineWidth',.5);
        end
    end
   % yticks=linspace(-80,80,9)';
    yticks=[-80 -60 -40 -20 -10 10 20 40 60 80]';
    yticks=yticks-sign(yticks)*equ_clip;
    maxdistx=1000*max(abs(deg2km(cat(1,xx{:}))));
    xticks=round((linspace(-maxdistx,maxdistx,20)))';
    set(gca,'ytick',deg2km(yticks)*1000)
    set(gca,'yticklabel',num2str(yticks))
     set(gca,'xtick',xticks)
    set(gca,'xticklabel',num2str(round(xticks/1000)))
    xlabel('[km]')
     ylabel('[lat]')
   axis([min(xticks) max(xticks) deg2km(min(yticks))*1000 deg2km(max(yticks))*1000])
    title([sens{ss},' tracks. longitude colorcoded. max ages of <',num2str(minage),' excluded'])
   cb=colorbar;    
    ticks=([0 90 180 270])';   
    set(cb,'ytick',ticks/360*64);
    set(cb,'yticklabel',num2str(ticks));
    print(fig, '-dpng',['-r',num2str(rez)],fname )
   
    
    
end



return

%% plot

cma=flipud([linspace(.95,0,100)'.^2,linspace(1,0,100)',(linspace(1,1,100)')]);
cmb=[linspace(.95,1,100)'.^2,linspace(1,0,100)',(linspace(1,0,100)')];
CM=flipud([cma;cmb]);

sens={'anti-cyclonic','cyclonic'};
rez=400;
xdim=1400;
ydim=800;
resolution=get(0,'ScreenPixelsPerInch');
xdim=xdim*rez/resolution;
ydim=ydim*rez/resolution;
M=STATS(1).DIM;
LO=M.GLO;
LA=M.GLA;
load coast

close all
cma=autumn;
cmb=winter;
cmb=flipud(cmb);
la=size(cma,1);
lb=size(cmb,1);
cmb(:,1)=0.9*exp(-linspace(0,8,lb))';
cmb(:,3)=cmb(:,3)+0.5*exp(-linspace(0,12,lb))';
cmb(:,1)=cmb(:,1)-flipud(exp(-linspace(0,5,lb))');
cmb(:,3)=cmb(:,3)-flipud(exp(-linspace(0,5,lb))');
cma(:,1)=linspace(1,0.9,la)'-exp(-linspace(0,32,la))';
cma(:,2)=0.5*(cos(linspace(-pi/4,2*pi,la))+1);
cma(:,3)=flipud(exp(-linspace(0,4,la))')+exp(-linspace(0,6,la))';
cma(cma<0)=0;
cmb(cmb<0)=0;
cma=cma/max(cma(:));
cmb=cmb/max(cmb(:));
CM3=[cma;cmb];



%% tracks



close all
for ss=1:2
    tracks=STATS(ss).remapped.tracks;
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    pcolor(LO,LA,log2(tracks));
    colormap(jet); cb=colorbar; shading flat;
    caxis([0 10]);
    ticks=linspace(0,10,11)';
    
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(2.^ticks));
    %
    hold on; plot(long,lat);
    title(  [ sens{ss}, ' - eddy visits']);
    %     xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fname=['./',sens{ss},'visits_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
   print(fig, '-dpng',['-r',num2str(rez)],fname )
end








close all
for ss=1:2
    dat=DIST(ss).birth.netzon/1000;
    datl=sign(dat).*log2(abs(dat));
    
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    pcolor(LO,LA,datl);colormap(CM3); cb=colorbar; shading flat;
    caxis([-log2(2000) log2(2000)]);
    ticks=-log2([2000, 500,  100, 20]);
    ticks=[ticks 0 -fliplr(ticks)]';
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(sign(ticks).*2.^abs(ticks)));
    
    hold on; plot(long,lat);
    title(  [ sens{ss}, ' - places of birth with mean zonal dist travelled in life [km]']);
    xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fnameD=['./',sens{ss},'distzon_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
  %  print(fig, '-dpng',['-r',num2str(rez)],fnameD )
    
    
    
    %%
    dat=DIST(ss).birth.full/1000;
    datl=sign(dat).*log2(abs(dat));
    
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    pcolor(LO,LA,datl);colormap(jet); cb=colorbar; shading flat;
    caxis(log2([50 4000]));
    ticks=log2([50,100,200,500,1000,2000,4000])';
    
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(2.^ticks));
    
    hold on; plot(long,lat);
    title(  [ sens{ss}, ' - places of birth with total dist travelled [km]']);
    xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fnameD=['./',sens{ss},'distfull_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
   % print(fig, '-dpng',['-r',num2str(rez)],fnameD )
    
end

%%
close all
for ss=1:2
    dat=DIST(ss).death.netzon/1000;
    datl=sign(dat).*log2(abs(dat));
    
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    pcolor(LO,LA,datl);colormap(CM3); cb=colorbar; shading flat;
    caxis([-log2(2000) log2(2000)]);
    ticks=-log2([2000, 500,  100, 20]);
    ticks=[ticks 0 -fliplr(ticks)]';
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(sign(ticks).*2.^abs(ticks)));
    
    hold on; plot(long,lat);
    title(  [ sens{ss}, ' - places of death with mean zonal dist travelled in life [km]']);
    xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fnameD=['./',sens{ss},'distzon_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    print(fig, '-dpng',['-r',num2str(rez)],fnameD )
    
    
    
    %%
    dat=DIST(ss).death.full/1000;
    datl=sign(dat).*log2(abs(dat));
    
    fig=figure('renderer','zbuffer');
    set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    pcolor(LO,LA,datl);colormap(jet); cb=colorbar; shading flat;
    caxis(log2([50 4000]));
    ticks=log2([50,100,200,500,1000,2000,4000])';
    
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(2.^ticks));
    
    hold on; plot(long,lat);
    title(  [ sens{ss}, ' - places of death with total dist travelled [km]']);
    xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fnameD=['./',sens{ss},'distfull_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    print(fig, '-dpng',['-r',num2str(rez)],fnameD )
    
end



%%
fig=figure('renderer','zbuffer');
set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
pcolor(LO,LA,vnetb); cb=colorbar; shading flat;
caxis([0 0.2]);
%  ticks=([7, 31, 90, 365, 2^10])';
% set(cb,'ytick',ticks);
% set(cb,'yticklabel',num2str(2.^ticks));
%  colormap(CM)
hold on; plot(long+(LO(1,2)-LO(1,1))/2,lat+(LA(2,1)-LA(1,1))/2)
title([sens{ss} ':mean speed - abs net zonal vel [m/s]']);
xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
fname=['./',sens{ss},'diff_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
% print(fig, '-dpng',['-r',num2str(rez)],fname )


%%

close all
cma=autumn;
cmb=winter;
cmb=flipud(cmb);
la=size(cma,1);
lb=size(cmb,1);
cmb(:,1)=0.9*exp(-linspace(0,8,lb))';
cmb(:,3)=cmb(:,3)+0.5*exp(-linspace(0,12,lb))';
cmb(:,1)=cmb(:,1)-flipud(exp(-linspace(0,5,lb))');
cmb(:,3)=cmb(:,3)-flipud(exp(-linspace(0,5,lb))');
cma(:,1)=linspace(1,0.9,la)'-exp(-linspace(0,32,la))';
cma(:,2)=0.5*(cos(linspace(-pi/4,2*pi,la))+1);
cma(:,3)=flipud(exp(-linspace(0,4,la))')+exp(-linspace(0,6,la))';
cma(cma<0)=0;
cmb(cmb<0)=0;
cma=cma/max(cma(:));
cmb=cmb/max(cmb(:));
CM3=[cma;cmb];

for ss=1:2
   VVz= STATS(ss).remapped.vels.mean_velocities.zonal;
   VVt= STATS(ss).remapped.vels.mean_velocities.trajec;
  LA=STATS(ss).DIM.GLA;
  LO=STATS(ss).DIM.GLO;
    pcolor_niko(VVz,LO,LA,1,500,2000,1000,CM3,'caxis([-0.1 .1])',['xlabel([''',sens{ss},' eddy speed zonal [m/s].''])'],  ['load coast;'],['plot(long,lat);']);
    pcolor_niko(VVt,LO,LA,1,500,2000,1000,jet,'caxis([0 .2])',['xlabel([''',sens{ss},' eddy speed full trajecory [m/s].''])'],  ['load coast;'],['plot(long,lat);']);
    %  pcolor_niko(VMEANS(ss).datacount,DIM.GLO,DIM.GLA,1,500,2000,1000,flipud(hot),'caxis([0 20])',['xlabel([''',sens{ss},' data count.''])'],  ['load coast;'],['plot(long,lat);']);
   % pcolor_niko(VMEANS(ss).diameter/1000,DIM.GLO,DIM.GLA,1,100,2000,1000,jet,'caxis([0 50])',['xlabel([''',sens{ss},' diameter [km]''])'],  'load coast;','plot(long,lat);');
end

pcolor_niko(Ro1_rs,DIM.GLO,DIM.GLA,1,200,2000,1000,[hot;flipud(hot)],'caxis([-800 800])','xlabel(''Ro_1 [m]'')',  'load coast;','plot(long,lat);');


%%
close all
D=VMEANS.diam_all;
LL=cellfun(@(x) numel(x), D);
LLmax=max(LL);

D(LL>1000 | LL<120)=[];
LL(LL>1000| LL<120)=[];
LLmax=max(LL);


for q=1:numel(D)
    disp_progress(q,numel(D),100)
    col=[1-LL(q)/LLmax .5 .5];
    xs=round(linspace(1,LLmax,LL(q)));
    
    
    windowSize = 80;
    Df= filter(ones(1,windowSize)/windowSize,1,D{q});
    
    plot(xs,Df,'color',col,'linewidth',0.005);
    hold on
end





%% plot ages

sens={'anti-cyclonic','cyclonic'};
rez=320;
xdim=1800;
ydim=900;
resolution=get(0,'ScreenPixelsPerInch');
xdim=xdim*rez/resolution;
ydim=ydim*rez/resolution;
LO=GLOBAL_VARS.lon;
LA=GLOBAL_VARS.lon;
landareas = shaperead('landareas.shp','UseGeoCoords',true);
for ss=1:2
    close all
    
    D=STATS(ss).ages.mean_age;
    B=STATS(ss).ages.births;
    DE=STATS(ss).ages.deaths;
    NET=STATS(ss).ages.NetBirthDeath;
    
    B(B==0)=nan;
    DE(DE==0)=nan;
    NET(NET==0)=nan;
    D(D==0)=nan;
    
    figD=figure('renderer','zbuffer');
    set(figD,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    axesm ('eckert4', 'Frame', 'off', 'Grid', 'off');
    geoshow(landareas,'FaceColor',[1 1 .5],'EdgeColor',[.6 .6 .6]);
    pcolorm(LA,LO,log2(D)); cb=colorbar;
    caxis([1 10]);
    ticks=log2([7, 31, 90, 365, 2^10])';
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(2.^ticks));
    title(['average ', sens(ss),' eddy age [days]']);
    xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fnameD=['./age_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    %   fnamet=['./age_',datestr(now,'mmddHHMMSS.FFF'),'thump.png'];
    
    figB=figure('renderer','zbuffer');
    set(figB,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    axesm ('eckert4', 'Frame', 'off', 'Grid', 'off');
    geoshow(landareas,'FaceColor',[1 1 .5],'EdgeColor',[.6 .6 .6]);
    pcolorm(LA,LO,B);
    title(['births -', sens(ss)]);
    fnameB=['./birth_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    
    figDE=figure('renderer','zbuffer');
    set(figDE,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    axesm ('eckert4', 'Frame', 'off', 'Grid', 'off');
    geoshow(landareas,'FaceColor',[1 1 .5],'EdgeColor',[.6 .6 .6]);
    pcolorm(LA,LO,DE);
    title(['deaths -', sens(ss)]);
    fnameDE=['./death_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    
    figNET=figure('renderer','zbuffer');
    set(figNET,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    axesm ('eckert4', 'Frame', 'off', 'Grid', 'off');
    geoshow(landareas,'FaceColor',[1 1 .5],'EdgeColor',[.6 .6 .6]);
    pcolorm(LA,LO,NET);
    title(['Net births/deaths -', sens(ss)]);
    fnameN=['./net_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    
    print(figD, '-dpng',['-r',num2str(rez)],fnameD )
    % print(fig, '-dpng','-r50',fnamet )
    print(figDE, '-dpng',['-r',num2str(rez)],fnameB )
    print(figB, '-dpng',['-r',num2str(rez)],fnameDE )
    print(figNET, '-dpng',['-r',num2str(rez)],fnameN )
    
end



%%


for ss=1:2
    %%
    close all
    da=STATS(ss).remapped.ages
    
    %%
    figD=figure('renderer','zbuffer');
    set(figD,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    pcolor(LO,LA,log2(da.meanage)); cb=colorbar; shading flat;
    caxis([1 10]);
    ticks=log2([7, 31, 90, 365, 2^10])';
    set(cb,'ytick',ticks);
    set(cb,'yticklabel',num2str(2.^ticks));
    hold on; plot(long,lat)
    title(['average '  sens{ss} ' eddy age [days]']);
    xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
    fnameD=['./',sens{ss},'age_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
    
    %%
%     figB=figure('renderer','zbuffer');
%     set(figB,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
%     pcolor(LO,LA,da.births); cb=colorbar; shading flat;
%     title(['births -', sens(ss)]);
%     colormap(cmb)
%     fnameB=['./',sens{ss},'birth_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
%     hold on; plot(long,lat)
%     %%
%     figDE=figure('renderer','zbuffer');
%     set(figDE,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
%     pcolor(LO,LA,da.deaths); cb=colorbar; shading flat;
%     title(['deaths -', sens(ss)]);
%     colormap(cmb)
%     fnameDE=['./',sens{ss},'death_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
%     hold on; plot(long,lat)
%     %%
%     figNET=figure('renderer','zbuffer');
%     set(figNET,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
%     data=da.net;
%     data(data>0)=log2(data(data>0));
%     data(data<0)=-log2(-data(data<0));
%     ticks=(-5:2:5)';
%     pcolor(LO,LA,data); cb=colorbar; shading flat;
%     set(cb,'ytick',ticks);
%     set(cb,'yticklabel',num2str(sign(ticks).*2.^abs(ticks)));
%     colormap(CM)
%     xlabel([' eddies of max age ',num2str(I.minage),' are excluded']);
%     title(['Net births/deaths -', sens{ss}]);
%     fnameN=['./',sens{ss},'net_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
%     hold on; plot(long,lat)
    %%
    print(figD, '-dpng',['-r',num2str(rez)],fnameD )
%     print(figDE, '-dpng',['-r',num2str(rez)],fnameDE )
%     print(figB, '-dpng',['-r',num2str(rez)],fnameB )
%     print(figNET, '-dpng',['-r',num2str(rez)],fnameN )
%     
end





















%% load rossby radius
load('/scratch/uni/ifmto/u300065/Ro_one.mat');
dirIn='/scratch/uni/ifmto/u241194/DAILY/EULERIAN/MEANS/';
fileS=[dirIn,'SALT_1995.nc'];
lat=ncread(fileS,'U_lat_2D');
lon=ncread(fileS,'U_lon_2D');
latr=10000*round(10^DIM.round*lat(:))/10^DIM.round;
lonr=round(10^DIM.round*lon(:))/10^DIM.round;
LALO=latr+lonr;
[a,b,c]=unique(LALO);
%
IDX=nan(size(DIM.GLA));
Ro1_rs=nan(size(DIM.GLA));
XXlin=numel(DIM.GLA);

%% reshape
parfor ii=1:XXlin
    tic
    disp_progress(ii,XXlin,10000);
    la=DIM.GLA(ii); %#ok<PFBNS>
    lo=DIM.GLO(ii);
    lalo=10000*la+lo;
    IDX(ii)=nanmax([nan,b(lalo==a)]); %#ok<PFBNS>
end
%
Ro1_rs(~isnan(IDX))=Ro1(IDX(~isnan(IDX)));
save(['/scratch/uni/ifmto/u300065/Ro_one_',num2str(DIM.Ydim),'x',num2str(DIM.Xdim)],'Ro1_rs');

%% get long 1st mode rossby wave pshase speed
day_sid=23.9344696*60*60;
om=2*pi/(day_sid);
F=2*om*sin(deg2rad(DIM.GLA));
beta=2*om*cos(deg2rad(DIM.GLA))/earthRadius;
C_r1=beta.*Ro1_rs.^2;

%% approx barotropic Ro_0^2
Ro0=sqrt(9.81*1000)./F;









