%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 08-Apr-2014 19:50:46
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S08b_subsampleU
    DD=initialise([],mfilename);

    DD.threads.tracks=thread_distro(DD.threads.num,numel(DD.path.tracks.files));
    main(DD);
    seq_body(DD);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    %% get stuff
    [map,MM]=initAll(DD);
    %%
    spmd(DD.threads.num)
        [MM,map]=spmd_block(DD,map,MM);
    end
    %% collect
    tmpsave(comboAllMaps(map{1},DD));
end
function tmpsave(map) %#ok<INUSD>
    save spmdMap
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MinMax,map]=spmd_block(DD,map,MinMax)
    T=disp_progress('init','analyzing tracks');
    JJ=DD.threads.tracks(labindex,1):DD.threads.tracks(labindex,2);
    for jj=JJ;
        T=disp_progress('calc',T,numel(JJ),100);
        %% get track
        [TT]=getTrack(DD,jj); if isempty(TT),continue;end

        %% mapstuff prep
        senii=(TT.sense+3)/2;
        sen=DD.FieldKeys.senses{senii};
        [map.(sen),TT.velPP]=MeanStdStuff(TT.eddy,map.(sen),DD);

    end
    %% gather
    MinMax=gcat(MinMax,1,1);
    map=gcat(map,1,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [map,velpp]=MeanStdStuff(eddy,map,DD)

    [map.strctr, eddy]=TRstructure(map,eddy);
    if isempty(eddy.track),return;end % out of bounds
    [NEW.age]=TRage(map,eddy);
    [NEW.dist,eddy]=TRdist(map,eddy);
    [NEW.vel,velpp]=TRvel(map,eddy);
    NEW.radius=TRradius(map,eddy);
    NEW.amp=TRamp(map,eddy);
    [NEW.visits.all,NEW.visits.single]=TRvisits(map);
    NEW.iq=TRiq(map,eddy);
    %% combo old map with new data
    map=comboMS(map,NEW,DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ACs,Cs]=netVels(DD,map)
    velmean=reshape(extractdeepfield(load(DD.path.meanU.file),...
        'means.small.zonal'),DD.map.out.Y,DD.map.out.X);
    ACs=	map.AntiCycs.vel.zonal.mean -velmean;
    Cs =	map.Cycs.vel.zonal.mean		 -velmean;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function seq_body(DD)
    load spmdMap
    %% get rossby radius
    if DD.switchs.RossbyStuff
        map.Rossby=loadRossby(DD);
        %% build radius/rossbyRadius ratio
        map.AntiCycs.radius.toRo=map.AntiCycs.radius.mean.mean./map.Rossby.small.radius;
        map.Cycs.radius.toRo=map.Cycs.radius.mean.mean./map.Rossby.small.radius;
    end
    %% build zonal means
    map.zonMean=zonmeans(map,DD);
    %% build net vels
    if DD.switchs.netUstuff
        [map.AntiCycs.vel.net.mean,map.Cycs.vel.net.mean]=netVels(DD,map);
    end
    %% save
    save([DD.path.analyzed.name,'maps.mat'],'-struct','map');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function MinMax=resortTracks(DD,MinMax,TT,senii)
    subfields = DD.FieldKeys.trackPlots;
    track = TT.eddy.track;
    TT.lat      = extractdeepfield(track,'geo.lat');
    TT.lon      = extractdeepfield(track,'geo.lon');
    TT.trackref = extractdeepfield(track,'trackref.lin');
    for subfield = subfields'; sub=subfield{1};
        %% nicer for plots
        collapsedField=strrep(sub,'.','');
        TT.(collapsedField) =  extractdeepfield(track,sub);
        %% get statistics for track
        [TT,MinMax]=getStats(TT,MinMax,collapsedField);
    end

    %% save
    sendir=DD.FieldKeys.senses;
    outfile=[DD.path.analyzedTracks.(sendir{senii}).name,TT.fname];
    %% save
    save(outfile,'-struct','TT');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TT]=getTrack(DD,jj)
    TT.fname=DD.path.tracks.files(jj).name;
    TT.filename = [DD.path.tracks.name  TT.fname];
    try
        TT.eddy=load(TT.filename);
    catch corrupt
        warning(corrupt.identifier,corrupt.getReport)
        disp('skipping!')
        TT=[]; return
    end



    TT.eddy.track(end)=[];



    TT.sense=TT.eddy.track(1).sense.num;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[strctr, eddy]=TRstructure(map,eddy)
    CoV=extractdeepfield(eddy,'track.trackref.lin');
    strctr.idx=map.idx(CoV)	;
    strctr.idxLargeMap=CoV	;
    %% delete out of bounds values
    outofbounds=isnan(strctr.idx);
    strctr.idx(outofbounds) = [];
    strctr.idxLargeMap(outofbounds) = [];
    eddy.track(outofbounds) = [];
    tracklen=numel(eddy.track);
    strctr.length=(1:tracklen);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [age]=TRage(map,eddy)
    [age]=protoInit(map.proto);
    idx=map.strctr.idx;
    ageNow=cat(1,eddy.track.age);
    [age]=uniqMedianStd(idx,ageNow,age);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	iq=TRiq(map,eddy)
    A={'iq'};
    idx=map.strctr.idx;
    a=A{1};
    iq=protoInit(map.proto);
    ampN=extractdeepfield(eddy.track,'iq');
    iq=uniqMedianStd(idx,ampN,iq);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	amp=TRamp(map,eddy)
    A={'to_mean';'to_contour';'to_ellipse'};
    idx=map.strctr.idx;
    for jj=1:3;
        a=A{jj};
        amp.(a)=protoInit(map.proto);
        ampN=extractdeepfield(eddy.track,['peak.amp.' a]);
        amp.(a)=uniqMedianStd(idx,ampN,amp.(a));
    end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	radius=TRradius(map,eddy)
    A={'mean';'meridional';'zonal'};
    B={'Le';'L';'Leff'};
    area2L=@(ar) sqrt(ar/pi);
    idx=map.strctr.idx;
    for jj=1:3;
        a=A{jj};
        radius.(a)=protoInit(map.proto);
        radiusNa=extractdeepfield(eddy.track,['radius.' a]);
        radius.(a)=uniqMedianStd(idx,radiusNa, radius.(a));
        b=B{jj};
        radius.(b)=protoInit(map.proto);

        radiusNb=area2L(extractdeepfield(eddy.track,['chelt.area.' b]));
        radius.(b)=uniqMedianStd(idx,radiusNb, radius.(b));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[vel,pp]=TRvel(map,eddy)
    noBndr=@(v) v(2:end-1);
    idx=noBndr(map.strctr.idx);
    A={'traj';'merid';'zonal'};
    for jj=1:3;
        a=A{jj};
        %% init
        [vel.(a)]=protoInit(map.proto);
        %% calc
        position=cumsum(eddy.dist.num.(a).m);
        pp.timeaxis = (cat(1,eddy.track.age)) * 60*60*24; % day2sec
        % TODO has to wait for available license
        while true
            try
                %% get v(t) = dx/dt
                pp.(a).x=spline(pp.timeaxis,position);
                pp.(a).x_t=fnder(pp.(a).x,1); % vel pp
                pp.(a).v=ppval(pp.(a).x_t, pp.timeaxis);
            catch er
                disp(er.message)
                sleep(10)
                continue
            end
            break
        end
        velN=noBndr(ppval(pp.(a).x_t, pp.timeaxis)); % discard 1st and last value frmo cubic spline
        vel.(a)=uniqMedianStd(idx,velN,vel.(a));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[dist,eddy]=TRdist(map,eddy)
    %% set up
    [dist]=setupDist(map);
    %% calc distances
    [eddy.dist.num,eddy.dist.drct]=diststuff(field2mat(eddy.track,'geo')');
    idx=map.strctr.idx;
    %%
    tl = {'velPP';'lat';'lon'};
    toLoad(numel(tl)).name=struct;
    [toLoad(:).name] = deal(tl{:});
    %%
    parfor yy = yearA:yearB
        doYear(yy,senses,DD,toLoad);
    end
    %%
    kk=0;
    for yy = yearA:yearB
        kk=kk+1;
        drawYears(DD,yy,kk,yearB,yearA);
    end
    ylabel('-u')
    xlabel('latitude')
    title(sprintf('yearly subsamples %d - %d',yearA,yearB));
    grid minor
    outfname = 'Usubsampled',
    savefig(DD.path.plots,72,400,300,outfname,'dpdf',DD2info(DD),14);
end
% -------------------------------------------------------------------------
function drawYears(DD,yy,kk,yearB,yearA)
    track = getfield(load(sprintf('%ssubVelYear%d.mat',DD.path.analyzed.name,yy)),'tout');
    latround = round(track.lat);
    laU = unique(latround);
    velDraw = nan(size(laU));
    cc=1;
    for la = laU
        todrawidx = latround == la;
        if sum(todrawidx)>100 && abs(la)>10
            velDraw(cc) = nanmean(track.vel(todrawidx));
        end
        cc=cc+1;
    end
    plot(laU,-velDraw,'color',rainbow(1,1,1,kk,yearB-yearA+1))
    hold on
    axis tight
end
% -------------------------------------------------------------------------
function doYear(yy,senses,DD,toLoad)
    fprintf('year %d',yy);
    outfname = sprintf('%ssubVelYear%d.mat',DD.path.analyzed.name,yy);
    if exist(outfname,'file')
        return
    end
    %%
    pattern = ['*TRACK*-' num2str(yy) '*_id*'];
    TRACKSa = dir2([DD.path.analyzedTracks.(senses{1}).name pattern]);
    TRACKSb = dir2([DD.path.analyzedTracks.(senses{2}).name pattern]);
    TRACKS = [TRACKSa(3:end); TRACKSb(3:end)];
    %     TRACKS = [TRACKSa(3:10); TRACKSb(3:10)];
    track(numel(TRACKS)).data = struct;
    %%
    for tt = 1:numel(TRACKS)
        tmp = load(TRACKS(tt).fullname,toLoad(:).name);
        tmp.vel = tmp.velPP.zonal.v';
        track(tt).data = rmfield(tmp,'velPP');
    end
    %%
    tmp = cat(2,track.data);
    tout.vel = cat(2,tmp.vel);
    tout.lat = cat(2,tmp.lat);
    tout.lon = cat(2,tmp.lon); %#ok<STRNU>
    %% save
    save(outfname,'tout')
end
