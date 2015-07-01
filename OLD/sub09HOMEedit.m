function sub09_trackstuff
    load S09main II DD T    
    try
        load trackinit
    catch me
        disp(me.message)
        trackinit(DD);
    end
    %%
    senses=DD.FieldKeys.senses;
    catsen=@(f) [TR.(senses{1}).cats.(f) TR.(senses{2}).cats.(f) ];
    t2l=@(t) linspace(t(1),t(2),t(3));
    
    %%
    rad=catsen('radiusmean')/1000;
    U  =catsen('U')*100;
    age=catsen('age');
    lat=abs(catsen('lat'));
    %%
    rightyscalenum=5;
    age(end+1:end+rightyscalenum)=max(age)-0;
    lat(end+1:end+rightyscalenum)=t2l([min(lat) max(lat) rightyscalenum]);
    rad(end+1:end+rightyscalenum)=t2l([min(rad) max(rad) rightyscalenum]);
    U(end+1:end+rightyscalenum)=10;
    %%
    [~,sml2lrg] = (sort(rad))  ;
    age=age(fliplr(sml2lrg));
    lat=lat(fliplr(sml2lrg));
    rad=rad(fliplr(sml2lrg));
    U=U(fliplr(sml2lrg));
    %%
    zerage = age<=0  ;
    age(zerage)=[];
    lat(zerage)=[];
    rad(zerage)=[];
    U(zerage)=[];
    %%
    clf
    hs=scatter(age,lat,rad,U);
    axis tight
    set(gca,'XAxisLocation','bottom')
    set(gca,...
        'ytick',t2l(T.lat),...
        'xtick',t2l(T.age));
    cb=colorbar;
    cb1 = findobj(gcf,'Type','axes','Tag','Colorbar');
    cbIm = findobj(cb1,'Type','image');
    alpha(cbIm,0.5)
    set(cb,'location','north','xtick',t2l(T.vel),'xlim',T.vel([1 2]))
    doublemap([T.vel(1) 0 T.vel(2)],II.aut,II.win,[.9 1 .9],20)
    h1=gca;
    h1pos = get(h1,'Position'); % store position of first axes
    h2 = axes('Position',h1pos,...
        'XAxisLocation','top',...
        'YAxisLocation','right',...
        'Color','none',...
        'ytick',linspace(0,1,rightyscalenum),...
        'xtick',[],...
        'yticklabel',round(t2l([min(rad) max(rad) rightyscalenum])));
    ylabel(h2,'radius [km]')
    ylabel(h1,'lat  [{\circ}]')
    xlabel(h1,'age [d]')
    xlabel(h2,'zon. vel.  [cm/s]')
    
    set(get(gcf,'children'),'clipping','off')
    set(get(hs,'children'),'clipping','off')
    
    
    savefig(DD.path.plots,T.rez,T.width,T.height,['sct-ageLatRadU'],'dpdf');
    
    
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trackinit(DD)
	tsenses=fieldnames(DD.path.analyzedTracks)';
	senses=DD.FieldKeys.senses;
	lims2array=@(lims) lims(labindex,1):lims(labindex,2);
	ss=2
	
	tsen=tsenses{ss};
	sen = senses{ss};
	root=DD.path.analyzedTracks.(tsen).name;
	eds= DD.path.analyzedTracks.(tsen).files;
	
	tsen=tsenses{1};
	rootB=DD.path.analyzedTracks.(tsen).name;
	
	eds=dir([root '*.mat']) 
    
	
	
	
	
	getfirst=@(x) x(1);
	%%
	figure(10)
	for ss= 3:1:numel(eds)
% 		SI(ss)=load([root eds(ss).name]);
% 		S=SI(ss);
% 		x=S.age*24*60*60;
% 		y=cumsum(S.distInM);	
% 		STD(ss)=std(S.distInM);
% 		lat(ss)=mean(S.lat);
%        ym(ss)=max(S.distInM);
% 		p=polyfit(x,y,1);
% 		u(ss)=p(1);
% 		[~,R(ss)]=(polyfit(x,y,1));
% 		[Y,delta] = polyval(p,x,R(ss));
% delt(ss)=mean(delta);
% 		
% 		% 		hold on
% % plot(x,y,'r',x,Y)
% 		len(ss)=numel(x);
% % 		ra(ss)=(nanmean(S.peakampto_ellipse))	;
% 		ra(ss)=(nanmean(S.radiusmean	))	;
        
        
        if max(abs(SI(ss).distInM))>1e6
           ss 
        end
        
        
        
    end
	
   
    sibug
    
    for si=1:7
       y=extractdeepfield(sibug(si).eddy.trck,'geo.lat') 
       x=extractdeepfield(sibug(si).eddy.trck,'geo.lon') 
       hold on
       plot(x,y,'*','color',rand(1,3))
    end
    
    
	%%
	ra=ra-min(ra);
	ra=ra/max(ra)
	%%
	figure(1)
	clf
	takes=3:1:numel(u)
	scatter(abs(u(takes)),abs(lat(takes)),(ra(takes)).^2*100,len(takes))
 	set(gca,'xlim',[-.1 .5])
	colorbar
	set(gca,'clim',[10 50])
	%%
	figure(2)
	clf
	takes=3:1:numel(u)
	scatter(len(takes),abs(lat(takes)),abs(u(takes))*300,(STD(takes)))
 	set(gca,'xlim',[-.1 .5])
	colorbar
axis tight
		
end
