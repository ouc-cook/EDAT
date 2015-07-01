function sub09_mapStuff
    load S09main II DD T
    lo=wrapTo180(II.lo);
    la=II.la;
    [~,loMin] =min(min(lo));
    eurocen = @(M,loMin) M(:,[loMin:end,1:loMin-1]);
    lo = eurocen(lo,loMin);
    la = eurocen(la,loMin);
    %%
    mapsAll(II,DD,T,lo,la,eurocen,loMin);
    %%
    %         mapsDiff(II,DD,T,lo,la,eurocen,loMin,'../pop7II/');
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapsAll(II,DD,T,lo,la,eurocen,loMin)
    senses    = DD.FieldKeys.senses;
    sensesAlt =   {'anti-cyclones';'cyclones'};
    for ss=1:2
        sen=senses{ss};
        senAlt=sensesAlt{ss};
        %
        %         close all
        %         VV=II.maps.(sen).radius.mean.mean/1000;
        %         VV = eurocen(VV,loMin);
        %         pcolor(lo,la,VV);shading flat;
        %         colormap([hsv(14)]);
        %         clm=[20 160 8];
        %         decorate(clm,T,senAlt,'$\sigma$','km',0,1);
        %         axis([-180 180 -80 90]);
        % %         axis([-180 180 -80 10]);
        %         if ss==2
        %             colorbar('hide')
        %             set(gca,'yTickLabel','')
        %         end
        %         grid minor;
        %         sleep(1)
        %         savefig('./',T.rez,T.width,T.height,['MapSigma-' sen],'dpdf');
        %         sleep(1)
        %%
        
        clf
        VV.ac = eurocen(II.maps.AntiCycs.vel.zonal.mean,loMin);
        VV.c = eurocen(II.maps.Cycs.vel.zonal.mean,loMin);
        VV.mean = full((VV.c + VV.ac)*100)/2;
        VV1II = load('../pop1II/pop1IIVVmean.mat')
        VVdiff = VV1II.VV.mean - VV.mean;
        pcolor(lo,la,VVdiff);shading flat;
        CM = [autumn(100);flipud(winter(100))]
        colormap(CM)
        decorate([-20 20 11],T,senAlt,'Zonal velocity','cm/s',0,1);
        decorate([-10 10 5],T,senAlt,'Zonal velocity','cm/s',0,1);
        axis([-180 180 -80 90]);
        %         axis([40 65 -50 -25 ]);
        if ss==2
            colorbar('hide')
            set(gca,'yTickLabel','')
        end
        
        %        diffcolmap =  get(gcf,'colormap')
        grid minor;
        %        save diffMapUpopBoth diffcolmap
        cm = load('diffMapUpopBoth')
        colormap(cm.diffcolmap)
        
        %        savefig('./',T.rez,T.width,T.height,['velZonDiffPopMap'],'dpdf');
        savefig('./',T.rez,400,400,['velZonDiffPopMap'],'dpdf');
        
        %%
        
        
        
        
        
        
        close all
        VV=II.maps.(sen).vel.zonal.mean*100;
        
        
        VV = eurocen(VV,loMin);
        pcolor(lo,la,VV);shading flat;
        cw=jet(20);
        cm=[0 0 0];
        ce=(winter(4));
        colormap([cw;cm;ce(:,[1 3 2])])
        decorate([-20 5 6],T,senAlt,'Zonal velocity','cm/s',0,1);
        %      axis([-180 180 -40 -30]);
        axis([-180 180 -80 90]);
        %         axis([40 65 -50 -25 ]);
        if ss==2
            colorbar('hide')
            set(gca,'yTickLabel','')
        end
        grid minor;
        sleep(1)
        savefig('./',T.rez,T.width,T.height,['velZon-' sen],'dpdf');
        sleep(1)
        
        %%
        close all
        VV=II.maps.(sen).vel.net.mean*100;
        VV = eurocen(VV,loMin);
        pcolor(lo,la,VV);shading flat;
        cw=jet(20);
        cm=[0 0 0];
        ce=(winter(4));
        colormap([cw;cm;ce(:,[1 3 2])])
        decorate([-20 5 6],T,senAlt,'Net Zonal velocity','cm/s',0,1);
        axis([-180 180 -80 90]);
        
        %         axis([40 65 -50 -25 ]);
        if ss==2
            colorbar('hide')
            set(gca,'yTickLabel','')
        end
        grid minor;
        %%
        sleep(1)
        savefig('./',T.rez,T.width,T.height,['velZonNet-' sen],'dpdf');
        sleep(1)
        
        %         %%
        %         close all
        %         VV=II.maps.(sen).vel.zonal.mean*100;
        %         VV = eurocen(VV,loMin);
        %         pcolor(lo,la,VV);shading flat
        %         cw=jet(20);
        %         cm=[0 0 0];
        %         ce=(winter(4));
        %         colormap([cw;cm;ce(:,[1 3 2])])
        %         decorate([-20 5 6],T,sen,'Zonal velocity','cm/s',0,1);
        %         %         axis(T.axis)   %
        %         axis([-180 180 -70 70]);
        %         savefig(DD.path.plots,T.rez,T.width,T.height,['MapVel-' sen],'dpdf');
        %         %         CC.(sen).v=VV;
        %         %%
        %         close all
        %         VV=log(II.maps.(sen).age.mean);
        %         VV = eurocen(VV,loMin);
        %         pcolor(lo,la,VV);shading flat;colormap(jet)
        %         decorate([log(T.age([1 2])) T.age(3)],T,sen,'age','d',exp(1),0);
        %         %         axis(T.axis)   %
        %         axis([-180 180 -70 70]);
        %         savefig(DD.path.plots,T.rez,T.width,T.height,['MapAge-' sen],'dpdf')
        %         %%
        %         close all
        %         VV=(II.maps.(sen).visits.single);
        %         VV = eurocen(VV,loMin);
        %         VV(VV==0)=nan;
        %         pcolor(lo,la,VV);shading flat;colormap(jet(11))
        %         cb=decorate([0 27.5,11],T,sen,'Visits of unique eddy',' ',0,1);
        %         %      decorate(T.visitsunique,T,DD,sen,'Visits of unique eddy',' ',0,1,1);
        %         set(cb,'ytick',[0 5:5:25])
        %         set(cb,'yticklabel',[1 5:5:25])
        %         set(cb,'ylim',[0 27.5])
        %         %         axis(T.axis)   %
        %         axis([-180 180 -70 70]);
        %         savefig(DD.path.plots,T.rez,T.width,T.height,['MapVisitsUnique-' sen],'dpdf')
        %%
    end
    joinPdfs('MapSigma',senses,DD)
    joinPdfs('velZon',senses,DD)
    %
    close all
    VV=(II.maps.(senses{1}).visits.single);
    VV = eurocen(VV,loMin);
    VV(VV==0)=nan;
    VVV=repmat(VV,[1 1 2]);
    
    VV=(II.maps.(senses{2}).visits.single);
    VV = eurocen(VV,loMin);
    VV(VV==0)=nan;
    VVV(:,:,2)=VV;
    VV=sum(VVV,3);
    pcolor(lo,la,VV);shading flat;
    %         colormap(parula(21))
    colormap(jet(13))
    cb=decorate([0 65,11],T,sen,'Unique Visits',' ',0,1);
    %     title('unique visits (all)')
    set(cb,'ytick',[0 10:10:60])
    set(cb,'yticklabel',[1 10:10:60])
    set(cb,'ylim',[0 65])
    %         axis(T.axis)   %
    axis([-180 180 -80 10]);
    grid minor
    fn = ['MapVisitsBoth'];
    savefig(DD.path.plots,T.rez,T.width,T.height,fn,'dpdf');
    cpPdfTotexMT(fn)  ;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function joinPdfs(fname,senses,DD)
    system(['pdfjam --nup 2x1 -o c.pdf ' [fname '-' senses{1} '.pdf '] [fname '-' senses{2} '.pdf']])
    system(['pdfcrop c.pdf --margins "1 1 1 1" ' DD.path.plots fname '.pdf'])
    cpPdfTotexMT(fname);
    % system('rm *.pdf')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function cb=decorate(clm,ticks,tit,tit2,unit,logbase,decim)
    %%
    dec=10.^decim;
    %%
    %     axis(ticks.axis);
    set(gca,'ytick',ticks.y);
    set(gca,'xtick',ticks.x);
    %     colorbar('off');
    cb=colorbar('north','AxisLocation','out');
    cpos = cb.Position;
    cpos(4) = 0.3*cpos(4);
    cpos(2) = cpos(2) + 3*cpos(4);
    cb.Position = cpos;
    %%
    zticks=linspace(clm(1),clm(2),clm(3))';
    %%
    switch logbase
        case 0
            zticklabel=num2str(round(zticks*dec)/dec);
        otherwise
            ztl=logbase.^zticks;
            [zaehler,nenner]=rat(ztl);
            nenn=nenner(1);
            s=zaehler>=nenner;
            ztlA=round(10*zaehler(~s).*repmat(nenn,size(nenner(~s)))./nenner(~s))/10;
            zticklabelA=cellfun(@(c) [num2str(c),'/',num2str(nenn)], num2cell(ztlA),'uniformoutput',false);
            ztlB=round(dec.*zaehler(s)./nenner(s))/dec;
            zticklabelB=cellfun(@(c) num2str(c),num2cell(ztlB),'uniformoutput',false);
            zticklabel=[zticklabelA;zticklabelB];
    end
    %%
    caxis([zticks(1) zticks(end)])
    set(cb,'ytick',zticks);
    set(cb,'yticklabel',zticklabel);
    %     title([tit,' - ',tit2,' [',unit,']'])
    %%
    load coast;
    hold on;
    plot(long,lat);
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapsDiff(II,DD,T,lo,la,eurocen,loMin,compDir)
    senses=DD.FieldKeys.senses;
    compData = load([compDir 'S09main.mat'],'II', 'DD', 'T');
    
    
    
    RA.visits.ac = (II.maps.AntiCycs.visits.all);
    RA.visits.c  = (II.maps.Cycs.visits.all);
    RA.sigma.ac = full(II.maps.AntiCycs.radius.mean.mean);
    RA.sigma.c  = full(II.maps.Cycs.radius.mean.mean);
    RA.sigma.all= (RA.visits.ac .* RA.sigma.ac + RA.visits.c .* RA.sigma.c)./(RA.visits.c + RA.visits.ac);
    
    %     pcolor(RA.sigma.all/1000);shading flat;colorbar;axis tight;    caxis([10 200])
    
    RB.visits.ac = (compData.II.maps.AntiCycs.visits.all);
    RB.visits.c  = (compData.II.maps.Cycs.visits.all);
    RB.sigma.ac = full(compData.II.maps.AntiCycs.radius.mean.mean);
    RB.sigma.c  = full(compData.II.maps.Cycs.radius.mean.mean);
    RB.sigma.all= (RB.visits.ac .* RB.sigma.ac + RB.visits.c .* RB.sigma.c)./(RB.visits.c + RB.visits.ac);
    
    %     pcolor(RB.sigma.all/1000);shading flat;colorbar;axis tight;    caxis([10 200])
    
    figure('Color','white')
    load coast
    axesm miller
    axis off; framem on; gridm on;
    plotm(lat,long);
    hold on
    pcolorm(la,lo,RA.sigma.all -RB.sigma.all)
    tightmap
    
    
    
    for sense=senses';sen=sense{1};
        close all
        VV=(II.maps.(sen).visits.all);
        VV = eurocen(VV,loMin);
        VV(VV==0)=nan;
        VVcomp=(compData.II.maps.(sen).visits.all);
        VVcomp = eurocen(VVcomp,loMin);
        VVcomp(VVcomp==0)=nan;
        pcolor(lo,la,VV-VVcomp);shading flat;
        colormap([winter(3);flipud(autumn(2))])
        cb=decorate([-2.5 2.5,5],T,sen,['total visits: ',runA,'-',runB],' ',0,1);
        set(cb,'ytick',[-2 -1 0 1 2])
        set(cb,'yticklabel',[-2 -1 0 1 2])
        set(cb,'ylim',[-2 2])
        axis([-180 180 -70 70]);
        savefig(DD.path.plots,T.rez,T.width,T.height,['MapVisitsAll-' sen],'dpdf')
        
    end
end
















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function comp2chelt(II,aviCH)
% 	%%
% 	VV=full(II.maps.(sen).vel.zonal.mean*100);
% 	VVniko=full(aviCH.CC.(sen).v);
% 	VVrat=VV-VVniko ;
% 	LL=VVrat;
% 	wmax=median(min(LL));
% 	emax=median(max(LL));
% 	LL(LL>1 & LL<5)=1.1;
% 	LL(LL>5 & LL<10)=1.3;
% 	LL(LL>10 & LL<emax)=1.5;
% 	LL(LL<-1 & LL>-5)=-1.1;
% 	LL(LL<-5 & LL>-10)=-1.3;
% 	LL(LL<-10 & LL>-wmax)=-1.5;
% 	pcolor(lo,la,LL);shading flat;
% 	decorate([-log(100) 0 log(100)],T,DD,sen,'U(aviso) [CH-N]','cm/s',0,1,1);
% 	va=-1.6;vb=1.6;
% 	cb=colorbar;
% 	caxis([va vb])
% 	ct=va:.2:vb;
% 	ctl=cellfun(@(c) sprintf('%2.1f',c) ,num2cell(ct),'uniformoutput',false);
% 	ctl(1:3)={'','-10','-5'};
% 	ctl(end-2:end)={'5','10',''};
% 	cmaa=flipud([1 0 0; 0 0 1; 0 1 0]);
% 	cmbb=bone(4);
% 	CM=[cmaa;(spring(5));flipud(summer(5));flipud(cmbb(1:end-1,:))];
% 	%     CM=doublemap([va 0 vb],cma(:,[2 1 3]),cmb,[0 0 1],10);
% 	colormap(CM);
% 	set(cb,'ytick',ct,'yticklabel',ctl);
% 	axis(T.axis)   % axis([-180 180 -70 70]); ;
% 	savefig(DD.path.plots,T.rez,T.width,T.height,['CHmN_aviU-' sen],'dpdf');
%
% 	%%
% 	VV=II.maps.(sen).radius.mean.mean/1000;
% 	VVniko=aviNiko.CC.(sen).L;
% 	VVdiff=(full(VV-VVniko)./VV)*100 ;
% 	LL=log(abs(VVdiff)).*sign(VVdiff);
% 	pcolor(lo,la,LL);shading flat;
%
% 	decorate([-log(100) 0 log(100)],T,DD,sen,'$\sigma$ [$CH/N$ ratio]','%',0,1,1);
% 	cb=colorbar;
% 	caxis([-log(100) log(100)])
% 	ct=linspace(-log(100),log(100),9);
% 	ctl=exp(abs(ct)).*sign(ct);
% 	cma=flipud(jet(50));
% 	cma(:,1)=.5*cma(:,1) + .5*cma(:,3);
% 	CM=doublemap([[-log(100) 0 log(100)]],cma(:,[2 1 3]),flipud(jet(50)),[0 0 1],10);
% 	colormap(CM)
% 	set(cb,'ytick',ct,'yticklabel',round(ctl))
% 	axis(T.axis)   % axis([-180 180 -70 70]); ;
% 	savefig(DD.path.plots,T.rez,T.width,T.height,['CHoN_aviL-' sen],'dpdf');
%
% 	%%
% 	%       CC.(sen).L=VV;
% 	VV=II.maps.(sen).radius.mean.mean/1000;
% 	VVavi=aviCH.CC.(sen).L;
% 	VVrat=full(abs(VV./VVavi)) ;
% 	LL=log(VVrat);
% 	clf
% 	pcolor(lo,la,LL);shading flat;
% 	decorate([-1 0 1],T,DD,sen,'$\sigma$ [pop/aviso ratio]',' ',0,1,1);
%
% 	axis(T.axis)   % axis([-180 180 -70 70]); ;
% 	colormap(jet(5));
% 	cb=colorbar;
% 	ccc=linspace(log(1/4),log(1),5);
% 	ccc=[ccc diff(ccc([1 2]))];
% 	caxis(ccc([1 end]));
% 	ct=(ccc);
% 	ctl=rats(exp(ct)',5);
% 	set(cb,'ytick',ct,'yticklabel',ctl)
% 	savefig(DD.path.plots,T.rez,T.width,T.height,['POPoAVI_chL-' sen],'dpdf');
%
%
% 	VV=full(II.maps.(sen).vel.zonal.mean*100);
% 	VVavi=full(aviCH.CC.(sen).v);
% 	VVrat=VV-VVavi ;
% 	LL=VVrat;
% 	pcolor(lo,la,LL);shading flat;
% 	decorate([-log(100) 0 log(100)],T,DD,sen,'U(CH) [pop-aviso]','cm/s',0,1,1);
% 	va=-5;vb=5;
% 	cb=colorbar;
% 	caxis([va vb])
% 	ct=va:1:vb;
% 	ctl=cellfun(@(c) sprintf('%2.0f',c) ,num2cell(ct),'uniformoutput',false);
% 	%%
% 	cma=summer(50);
% 	cmb=flipud(autumn(50));
% 	CM=[cma;cmb(:,[ 1 2 2])];
% 	CM(:,[3])=cos(linspace(-pi*.8,pi*.8,100)').^2;
% 	colormap(CM)
% 	set(cb,'ytick',ct,'yticklabel',ctl)
% 	axis(T.axis)   % axis([-180 180 -70 70]); ;
% 	savefig(DD.path.plots,T.rez,T.width,T.height,['POPmAVI_chU-' sen],'dpdf');
%
% 	%%
% 	%     save CC CC
%
% end




%
%
% %% TODO
% 		try
% 			comp2chelt(II,aviCH)
% 		end
%
%
% %%
% % 		VV=(II.maps.(sen).radius.mean.mean./dxq);
% % 		a=full(floor(nanmin(VV(:))));
% 		b=full(ceil(nanmax(VV(:))));
% 		clm=[a b b-a+1];
% 		pcolor(lo,la,VV);shading flat;
% 		colormap(hsv(clm(3)-1));
% 		%      clm=[20 160 8];
% 		cb=decorate(clm,T,DD,sen,'radius/dx',' ',0,1,1);
% 		axis(T.axis)   % axis([-180 180 -70 70]); ;
% 		xl=(get(cb,'yticklabel'));
% 		xlc=cell(size(xl,1),1);
% 		for n=1:size(xl,1);
% 			xlc{n}=xl(n,:);
% 			if mod(n,10)~=0
% 				xlc{n}=' ';
% 			end
% 		end
% 		set(cb,'yticklabel',xlc)
% 		savefig(DD.path.plots,T.rez,T.width,T.height,['radOdx-' sen],'dpdf');

% 		clf
% 		logFive=@(x) log(x)/log(5);
% 		VVr=II.maps.(sen).radius.toRo/2;
% 		VVr(VVr<1e-3)=nan;VVr(VVr>1e3)=nan;
% 		VV=logFive(VVr);
% 		pcolor(lo,la,VV);shading flat;colormap([(hsv(8))])
% 		%         clm=T.radiusToRo;
% 		clm=[logFive([.125 8]) 9]; % base 5
% 		decorate(clm,T,DD,sen,'Radius/(2Lr)','km',5,1,1);
% 		axis(T.axis)   % axis([-180 180 -70 70]);
% 		savefig(DD.path.plots,T.rez,T.width,T.height,['MapRoLLog-' sen],'dpdf');
%%
% 		clf
% 		VV=II.maps.(sen).radius.toRo;
% 		VV(VV<1e-3)=nan;VV(VV>1e3)=nan;
% 		pcolor(lo,la,VV);shading flat;colormap(hsv(12))
% 		clm=[0 6 7];
% 		decorate(clm,T,DD,sen,'Radius/Lr','km',0,1,1);
% 		axis(T.axis)   % axis([-180 180 -70 70]);
% 		savefig(DD.path.plots,T.rez,T.width,T.height,['MapRoL-' sen],'dpdf');
%%
% 		clf
% 		VVs=II.maps.(sen).radius.mean.std;
% 		VVm=II.maps.(sen).radius.mean.mean;
% 		VV=((VVs./VVm)*100);
% 		VV(VV<0)=nan;
% 		VV=log10(VV);
% 		pcolor(lo,la,VV);shading flat;colormap(hsv(5))
% 		clm=[log10([1 100 ]) 6];
% 		decorate(clm,T,DD,sen,' scale: std/mean ','%',10,0,1);
% 		axis(T.axis)   % axis([-180 180 -70 70]);
% 		savefig(DD.path.plots,T.rez,T.width,T.height,['MapRadStdOMean-' sen],'dpdf');



























%
%     JJ=jet(100);
%     jj=JJ(10:end,:);
%     spmd(4)
%         sense=senses';
%         if labindex==1
%             sen=sense{1};
%             VV=II.maps.(sen).radius.mean.mean/1000;
%             VV = eurocen(VV,loMin);
%             pcolor(lo,la,VV);shading flat;
%             %             colormap([jet(21)]);
%             colormap(jj);
%             clm=[0 200 6];
%             decorate(clm,T,sen,'radius','km',0,1);
%             %         axis(T.axis)   %
%             axis([-180 180 -70 -20]);
%             set(gca,'ytick',linspace(-70,-20,6))
%             savefig(DD.path.plots,70,1000,250,['xMapRad-' sen],'dpdf');
%         end
%         if labindex==2
%             sen=sense{2};
%             VV=II.maps.(sen).radius.mean.mean/1000;
%             VV = eurocen(VV,loMin);
%             pcolor(lo,la,VV);shading flat;
%             colormap([jet(21)]);
%             colormap(jj);
%             clm=[0 200 6];
%             decorate(clm,T,sen,'radius','km',0,1);
%             %         axis(T.axis)   %
%             axis([-180 180 -70 -20]);
%             set(gca,'ytick',linspace(-70,-20,6))
%             savefig(DD.path.plots,70,1000,250,['xMapRad-' sen],'dpdf');
%         end
%         if labindex==1
%             sen=sense{1};
%             VV=II.maps.(sen).vel.zonal.mean;%.*cosd(la);
%             VV = abs(eurocen(VV,loMin));
%             pcolor(lo,la,VV);shading flat
%             cw=jet(21);
% %             colormap(cw)
%             colormap(jj);
%             decorate([0 .05 6],T,sen,'Zonal velocity','m/s',0,2);
%             %         axis(T.axis)   %
%             axis([-180 180 -70 -20]);
%             set(gca,'ytick',linspace(-70,-20,6))
%             savefig(DD.path.plots,70,1000,200,['xMapVel-' sen],'dpdf');
%         end
%
%         if labindex==2
%             sen=sense{2};
%             VV=II.maps.(sen).vel.zonal.mean.*cosd(la);
%             VV = abs(eurocen(VV,loMin));
%             pcolor(lo,la,VV);shading flat
%             cw=jet(21);
% %             colormap(cw)
%             colormap(jj);
%             decorate([0 .05 6],T,sen,'Zonal velocity','m/s',0,2);
%             %         axis(T.axis)   %
%             axis([-180 180 -70 -20]);
%             set(gca,'ytick',linspace(-70,-20,6))
%             savefig(DD.path.plots,70,1000,200,['xMapVel-' sen],'dpdf');
%         end
%     end
%
