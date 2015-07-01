function simpleTrackPlot
    DD = initialise([],mfilename);
    save DD
    addpath(genpath('./'))
    %     load DD
    DDII = getfield(load('DDII.mat'),'DD')
    senses = DD.FieldKeys.senses;
    ss=2;
    SSs=[-1 1];
    sen = senses{ss};
    %%
     xx = [20 80];
    yy = [20 50];
    %%
    kk = 0;
    tracks.I = dir2([DD.path.tracks.name]);
    tracks.I(1:2)  = [];
    tracks.II = dir2([DDII.path.tracks.name]);
    tracks.II(1:2)  = [];

    void = loadtracks(tracks.I);
    %     TRACKS.II = loadtracks(tracks.II);
    TRACKS.I  = getfield(load('TRACKSI.mat'),'TRACKS');
    TRACKS.II = getfield(load('TRACKSII.mat'),'TRACKS');
    %     TRACKS.II = loadtracks(tracks.II);


    TT = DD.time.from.num:DD.time.delta_t:DD.time.till.num;

    colors.I = [1 0 0];
    colors.II = [0 0 0];
    LS.I = '-';
    LS.II = '--';

    %%
    for  tt = TT
        kk=kk+1;
        main(tt,kk,DD,DDII,xx,yy,SSs,ss,sen,TRACKS,colors,LS);
    end

end

function main(tt,kk,DDI,DDII,xx,yy,SSs,ss,sen,TRACKS,colors,LS)
    clf
    clc;

    fprintf('day %d/%d\n',kk,ceil((DDI.time.till.num-DDI.time.from.num)/DDI.time.delta_t));

    cut = load([DDI.path.cuts.name DDI.path.cuts.files(kk).name]);
    eddy.I =load([DDI.path.eddies.name DDI.path.eddies.files(kk).name]);
    eddy.II =load([DDII.path.eddies.name DDII.path.eddies.files(kk).name]);
    ssh = cut.fields.ssh(yy(1):yy(2),xx(1):xx(2));
    lon = cut.fields.lon(yy(1):yy(2),xx(1):xx(2));
    lat = cut.fields.lat(yy(1):yy(2),xx(1):xx(2));
    %%
    plotssh(lon,lat,ssh)
    %%c
    ploteddies(eddy.I,lon,lat,sen,xx,yy,colors.I,LS.I)
    ploteddies(eddy.II,lon,lat,sen,xx,yy,colors.II,LS.II)
    %%
    plottracks(TRACKS.I,tt,lon,lat,SSs(ss),xx,yy,colors.I,LS.I);
    plottracks(TRACKS.II,tt,lon,lat,SSs(ss),xx,yy,colors.II,LS.II);
    %%
    %     title(datestr(tt),'fontsize',18,'interpreter','latex');
    set(gca,'xtick', 40:.25: 80,'fontsize',2)
    set(gca,'ytick',-50:.25:-30,'fontsize',2)
    %     set(gca,'
    set(gca,'xticklabel','')
    set(gca,'yticklabel','')
    set(gca,'layer','top')
    grid on
    set(gcf,'visible','off','renderer','opengl')
    axis tight
    %%
    text(60.8,-31.2,datestr(tt,'mm/dd'),'fontsize',22)


    saveas(gcf,sprintf('%03d.png',kk))

end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotssh(lon,lat,ssh)
    pcolor(lon,lat,ssh);
    shading flat
    shading interp
    hold on;
    %     colormap([bone(30);flipud(hot(30))]);
    colormap(parula(50));
    caxis([-.7,.4])
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ploteddies(eddy,lon,lat,sen,xx,yy,col,LS)
    for ee = 1:numel(eddy.(sen))
        coor = eddy.(sen)(ee).coor.exact;
        x = coor.x - xx(1) + 1;
        y = coor.y - yy(1) + 1;
        lo = interp2(lon,x,y);
        la = interp2(lat,x,y);
        plot(lo,la,'color',col,'linestyle',LS,'linewidth',1.2)
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plottracks(T,tt,lon,lat,senN,xx,yy,col,LS)
    for jj = 1:numel(T)
        %         fprintf('plotting track %d/%d\n',jj,numel(T));
        dateA =  T(jj).d.track(1).daynum;
        dateB =  T(jj).d.track(end).daynum;

        if dateA <= tt && dateB >= tt && T(jj).d.track(1).sense.num == senN
            track = T(jj).d.track;
            tdn = cat(1,track.daynum);
            toplot = tdn <= tt   ;
            x = extractdeepfield(track(toplot),'trackref.x')- xx(1) + 1;
            y = extractdeepfield(track(toplot),'trackref.y')- yy(1) + 1;
            lo = interp2(lon,x,y);
            la = interp2(lat,x,y);
            plot(lo,la,'color',col,'linewidth',2.2,'linestyle',':');
        end
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TRACKS = loadtracks(tracks)
    if ~exist('TRACKSI.mat','file')
        TRACKS(numel(tracks)) = struct;
        for jj = 1:numel(tracks)
            clc;
            fprintf('loading %d/%d\n',jj,numel(tracks));
            TRACKS(jj).d = load(tracks(jj).fullname);
        end
        save TRACKSI TRACKS
    else
        load TRACKSI
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
