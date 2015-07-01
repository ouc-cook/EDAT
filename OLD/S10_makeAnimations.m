%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-Apr-2014 17:39:11
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S10_makeAnimations    
    DD=initialise([],mfilename);
    ticks.rez=get(0,'ScreenPixelsPerInch');
    ticks.width=297/25.4*ticks.rez*1;
    ticks.height=ticks.width * DD.map.out.Y/DD.map.out.X;
    ticks.y= 0;
    ticks.x= 0;
    ticks.age=[1,3*365,10];
    ticks.isoper=[.6,1,10];
    ticks.radius=[20,150,9];
    ticks.radiusToRo=[0.2,5,11];
    ticks.amp=[1,20,7];
    ticks.visits=[1,20,11];
    ticks.visitsunique=[1,3,3];
    ticks.dist=[-1500;1000;21];
    ticks.disttot=[1;2000;10];
    ticks.vel=[-30;20;6];
    ticks.axis=[DD.map.out.west DD.map.out.east DD.map.out.south DD.map.out.north];
    ticks.lat=[ticks.axis(3:4),5];
    ticks.minMax=cell2mat(extractfield( load([DD.path.analyzed.name, 'vecs.mat']), 'minMax'));
    DD.frms=1000;
    animas(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function animas(DD)
    file1=[DD.path.eddies.name DD.path.eddies.files(1).name];
    
    grid=load(cell2mat(extractdeepfield(load(file1),'filename.cut')));
    d.LON=grid.grids.lon;
    d.LAT=grid.grids.lat;
    d.lon=grid.grids.lon;
    d.lat=grid.grids.lat;
    d.climssh.min=nanmin(grid.grids.ssh(:));
    d.climssh.max=nanmax(grid.grids.ssh(:));
    d.p=[DD.path.plots 'mpngs/'];
    mkdirp(d.p);
    frms=DD.frms;
    range=round(linspace(1,numel(DD.path.eddies.files),frms));
    for cc=1:numel(range)
        ee=range(cc);
        savepng4mov(d,ee,DD)
    end
    fps=max([1 round(frms/60)]);
    pn=pwd;
    cd(d.p)
    system(['mencoder "mf://flat*.jpeg" -mf fps=' num2str(fps) ' -o flat.avi -ovc lavc -lavcopts vcodec=ljpeg'])
    %     system(['mencoder "mf://surf*.png" -mf fps=' num2str(fps) ' -o surf.avi -ovc lavc -lavcopts vcodec=ljpeg'])
    cd(pn)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savepng4mov(d,ee,DD)

    d.file=[DD.path.eddies.name DD.path.eddies.files(ee).name];
    if exist([ d.p sprintf('flat%06d.png',ee)],'file')
        return
    end
    [~,fn,~] = fileparts(d.file);
    d.dtnm=datenum(fn(7:14),'yyyymmdd');
    ed=load(d.file);
    try
        grd=load(cell2mat(extractdeepfield(load(d.file),'filename.cut')));
    catch
        return
    end
    ssh=grd.grids.ssh;
    [Y,X]=size(ssh);    %#ok<NASGU>
  figure(1)  
  
    %%
     clf  %  pcolor(d.lon,d.lat,ssh);
    %     pcolor(ssh);
    surf(ssh(100:600,100:500),'FaceColor','interp','FaceLighting','phong');
    view(2)
    camlight left
    set(gcf,'Renderer','zbuffer')

    shading flat
    axis tight
    caxis([d.climssh.min d.climssh.max]);
    hold on
    sen={'cyclones','anticyclones'};
    col=[1 1 1; .2 .2 .2];
    for ss=1:2
        s=sen{ss};
        for cc=1:numel(ed.(s))
%             id=ed.(s)(cc).ID; %#ok<NASGU>
%             peak=ed.(s)(cc).trackref;
            lo=ed.(s)(cc).coordinates.exact.x;
            la=ed.(s)(cc).coordinates.exact.y;
            za=smooth(ssh(drop_2d_to_1d(round(la),round(lo),Y)));
            plot3(lo-100,la-100,za+10,'--','color',col(ss,:),'linewidth',1.5);
            %             plot3(peak.x,peak.y,5,'*');
        end
    end
    set(gca,'xticklabel',[],'yticklabel',[])
%     title([num2mstr(ee)])
    xlabel(datestr(d.dtnm))
    tit=DD.path.eddies.files(ee).name(1:end-4)   ; 
    savefig('./',300,2000,2400,'tmp',0,'dpng')
       system(['pdfcrop --margins ''-60 -45 -40 -45'' tmp.pdf ' tit '.pdf'])
%     savefig2png4mov(d.p,100,800,600,sprintf('flat%06d',ee))
%  shrinkpdf EDDIE_19940102_+00s+70n-80w+00e.pdf && mv EDDIE_19940102_+00s+70n-80w+00e_shrunk.pdf ../PLOTS/EDDIE_19940102_+00s+70n-80w+00e_raw.pdf

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
