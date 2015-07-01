%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-Apr-2014 17:39:11
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S09_tracksNew
	DD=initialise([],mfilename);
	%%	set ticks here!
	%     ticks.rez=200;
	ticks.rez=get(0,'ScreenPixelsPerInch');
	%           ticks.rez=42;
	ticks.width=297/25.4*ticks.rez/3;
	ticks.height=ticks.width * DD.map.out.Y/DD.map.out.X;
	%         ticks.height=ticks.width/sqrt(2); % Din a4
	ticks.y= 0;
	ticks.x= 0;
	ticks.age=[1,2*365,10];
	%     ticks.isoper=[DD.thresh.shape.iq,1,10];
	ticks.isoper=[.6,1,10];
	ticks.radius=[50,250,11];
	ticks.radiusToRo=[0.5,5,6];
	ticks.amp=[1,20,7];
	%ticks.visits=[0,max([maps.AntiCycs.visitsSingleEddy(:); maps.Cycs.visitsSingleEddy(:)]),5];
	ticks.visits=[1,20,11];
	ticks.visitsunique=[1,10,10];
	ticks.dist=[-1500;500;11];
	%ticks.dist=[-100;50;16];
	ticks.disttot=[1;3000;5];
	ticks.vel=[-30;20;6];
	ticks.axis=[DD.map.out.west DD.map.out.east DD.map.out.south DD.map.out.north];
	ticks.lat=[ticks.axis(3:4),5];
	ticks.minMax=cell2mat(extractfield( load([DD.path.analyzed.name, 'vecs.mat']), 'minMax'));
	
	%% main
	overmain(ticks,DD)
	%%
	conclude(DD);
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
	root=DD.path.analyzedTracks.AC.name;
	OUT.ACs={DD.path.analyzedTracks.AC.files.name};
	Tac=disp_progress('init','collecting all ACs');
	for ff=1:numel(OUT.ACs)
		Tac=disp_progress('calc',Tac,numel(OUT.ACs),50);
		OUT.tracks.AntiCycs(ff)={[root OUT.ACs{ff}]};
	end
	%%
	root=DD.path.analyzedTracks.C.name;
	OUT.Cs={DD.path.analyzedTracks.C.files.name};
	Tc=disp_progress('init','collecting all Cs');
	for ff=1:numel(OUT.Cs)
		Tc=disp_progress('calc',Tc,numel(OUT.Cs),50);
		OUT.tracks.Cycs(ff)={[root OUT.Cs{ff}]};
	end
	%% get vectors
	disp(['loading vectors'])
	OUT.vecs=load([DD.path.analyzed.name, 'vecs.mat']);
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
	set(gca,'ytick',ticks.y);
	set(gca,'xtick',ticks.x);
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
	xlabel(['Eddies that died younger ',num2str(DD.thresh.life),' days are excluded'])
	if coast
		drawcoast;
	end
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

