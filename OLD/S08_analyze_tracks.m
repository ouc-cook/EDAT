%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 08-Apr-2014 19:50:46
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEEDS COMPLETE REWRITE! way too complicated
function S08_analyze_tracks
    DD=initialise([],mfilename);
    save DD
    %     load DD
    DD.map.window = getfieldload(DD.path.windowFile,'window');
    DD.threads.tracks=thread_distro(DD.threads.num,numel(DD.path.tracks.files));
    main(DD);
    seq_body(DD);
    %     conclude(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    %% get stuff
    [map,MM]=initAll(DD);
    %%
    spmd(DD.threads.num)
        [MM,map]=spmd_block(DD,map,MM);
    end
    save('ANAmainSave.mat');
    %% collect
    MinMax=globalExtr(MM{1}); %#ok<*NASGU>
    save([DD.path.analyzed.name,'MinMax.mat'],'-struct','MinMax');
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
        
        if numel(TT.eddy.track)<2
            continue
        end
        
        % TEMP TODO
        for ee=1:numel(TT.eddy.track)
            if isfield(TT.eddy.track(ee).chelt,'A')
                TT.eddy.track(ee).chelt.amp = TT.eddy.track(ee).chelt.A;
                TT.eddy.track(ee).chelt.efoldAmp = TT.eddy.track(ee).chelt.efoldA;
                TT.eddy.track(ee).chelt = rmfield(TT.eddy.track(ee).chelt, {'A','efoldA'});
            end
            TT.eddy.track(ee).chelt = orderfields(TT.eddy.track(ee).chelt);
        end
        %% mapstuff prep
        senii=(TT.sense+3)/2;
        sen=DD.FieldKeys.senses{senii};
        [map.(sen),TT.velPP]=MeanStdStuff(TT.eddy,map.(sen),DD);
        if isempty(map)
            continue % TODO
        end
        %% resort tracks for output
        [MinMax]=resortTracks(DD,MinMax,TT,senii);
        
    end
    %% gather
    labBarrier;
    save(sprintf('ANAspmdCatch%02d.mat',labindex));
    labBarrier;
    
    MinMax=gcat(MinMax,1,1);
    map=gcat(map,1,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [map,velpp]=MeanStdStuff(eddy,map,DD)
    
    [map.strctr, eddy]=TRstructure(map,eddy);
    if isempty(eddy.track)
        map = [];
        velpp = [];
        return % TODO
    end % out of bounds
    [NEW.age]=TRage(map,eddy);
    [NEW.dist,eddy]   = TRdist(map,eddy);
    [NEW.vel,velpp]   = TRvel(map,eddy);
    NEW.radius=TRradius(map,eddy);
    NEW.amp=TRamp(map,eddy);
    [NEW.visits.all,NEW.visits.single]=TRvisits(map);
    NEW.iq=TRiq(map,eddy);
    %% combo old map with new data
    map=comboMS(map,NEW,DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ACs,Cs] = netVels(DD,map)
    
    tmp = load(DD.path.meanU.file);
    velmean = tmp.means.small.zonal;
    
    ACs =	full(map.AntiCycs.vel.zonal.mean) -velmean;
    Cs  =	full(map.Cycs.vel.zonal.mean)     -velmean;
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
    map.zonMean = zonmeans(map,DD);
    %% build net vels
    %     TODO
    %         if DD.switchs.netUstuff
    [map.AntiCycs.vel.net.mean,map.Cycs.vel.net.mean] = netVels(DD,map);
    %         end
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
        try
            TT.(collapsedField) =  extractdeepfield(track,sub);
        catch
            TT.(collapsedField) =  extractdeepfield(track,'isoper'); % TODO
        end
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
    TT.eddy.track(end)=[];    % kill trailing erronuous position
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
    idx=map.strctr.idx;
    iq=protoInit(map.proto);
    try
        ampN=extractdeepfield(eddy.track,'iq');
    catch
        ampN=extractdeepfield(eddy.track,'isoper');
    end
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
        %% get v(t) = dx/dt
        success = true;
        try
            pp.(a).x=spline(pp.timeaxis,position);
            pp.(a).x_t=fnder(pp.(a).x,1); % vel pp
            pp.(a).v=ppval(pp.(a).x_t, pp.timeaxis);
        catch void
            success = false;
            vel = [];
            pp = [];
            return
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
    %% traj from birth
    newValue=eddy.dist.num.traj.fromBirth;
    [dist.traj.fromBirth]=uniqMedianStd(idx,newValue,dist.traj.fromBirth);
    %% traj till death
    newValue=eddy.dist.num.traj.tillDeath;
    [dist.traj.tillDeath]=uniqMedianStd(idx,newValue,dist.traj.tillDeath);
    %% zonal from birth
    newValue=eddy.dist.num.zonal.fromBirth;
    [dist.zonal.fromBirth]=uniqMedianStd(idx,newValue,dist.zonal.fromBirth);
    %% zonal till death
    newValue=eddy.dist.num.zonal.tillDeath;
    [dist.zonal.tillDeath]=uniqMedianStd(idx,newValue,dist.zonal.tillDeath);
    %% meridional from birth
    newValue=eddy.dist.num.merid.fromBirth;
    [dist.merid.fromBirth]=uniqMedianStd(idx,newValue,dist.merid.fromBirth);
    %% meridional till death
    newValue=eddy.dist.num.merid.tillDeath;
    [dist.merid.tillDeath]=uniqMedianStd(idx,newValue,dist.merid.tillDeath);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [count,singlecount]=TRvisits(map)
    count=sparse(map.proto.zeros);
    singlecount=sparse(map.proto.zeros);
    idx=map.strctr.idx;
    [sidx]=unique(idx);
    %% the eddy counts +1 at every timestep at current position
    count(sidx) =  histc(idx,sidx);
    %% the eddy can tag each position only once
    singlecount(sidx)=1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% others
function [TT,MinMax]=getStats(TT,MinMax,cf)
    %% local
    TT.max.(cf)=nanmax(TT.(cf));
    TT.min.(cf)=nanmin(TT.(cf));
    TT.median.(cf)=nanmedian(TT.(cf));
    TT.std.(cf)=nanstd(TT.(cf));
    %% global updates
    if TT.max.(cf) > MinMax.max.(cf), MinMax.max.(cf)=TT.max.(cf); end
    if TT.min.(cf) < MinMax.min.(cf), MinMax.min.(cf)=TT.min.(cf); end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [map,MinMax]=initAll(DD)
    map.AntiCycs = initmap(DD);
    map.Cycs     = initmap(DD);
    for subfield       = DD.FieldKeys.trackPlots'; sub=subfield{1};
        collapsedField = strrep(sub,'.','');
        MinMax.max.(collapsedField)=-inf;
        MinMax.min.(collapsedField)=inf;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Ro=loadRossby(DD)
    map=initmap(DD);
    Ro.large.radius=getfield(load([DD.path.Rossby.name 'RossbyRadius.mat']),'data');
    Ro.large.radius(Ro.large.radius==0)=nan;
    Ro.small.radius=map.proto.nan;
    %%
    Ro.large.phaseSpeed=getfield(load([DD.path.Rossby.name 'RossbyPhaseSpeed.mat']),'data');
    Ro.large.phaseSpeed(Ro.large.phaseSpeed==0)=nan;
    Ro.small.phaseSpeed=map.proto.nan;
    %% nanmean to smaller map
    lin=map.idx;
    T=disp_progress('init','reallocating rossby stuff indices to output map');
    [slin,linOrdr]=sort(lin);
    slind=find([1;diff(slin);1]);
    %%
    nm=@(source,sidx)  nanmean(source(sidx));
    for ii=2:numel(slind)
        T=disp_progress('show',T,numel(slind)-1,10);
        a=slind(ii-1);  b=slind(ii)-1;  tidx=slin(a);
        Ro.small.radius(tidx)       = nm(Ro.large.radius,    linOrdr(a:b));
        Ro.small.phaseSpeed(tidx)   = nm(Ro.large.phaseSpeed,linOrdr(a:b));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Global=globalExtr(MinMax)
    %% collect high-scores for all tracks from threads
    for cf=fieldnames(MinMax(1).max)'; cf=cf{1};
        dataAll=extractdeepfield(MinMax,['max.' cf]);
        Global.max.(cf) = max(dataAll);
        Global.min.(cf) = min(dataAll);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function zonMean=zonmeans(M,DD)
    zonMean=M;
    for sense=DD.FieldKeys.senses'; sen=sense{1};
        N=M.(sen).visits.all;
        for Field=DD.FieldKeys.MeanStdFields'; field=Field{1};
            wms=weightedZonMean(cell2mat(extractdeepfield(M.(sen),field)),N);
            fields = textscan(field,'%s','Delimiter','.');
            zonMean.(sen)=setfield(zonMean.(sen),fields{1}{:},wms);
        end
    end
    if DD.switchs.RossbyStuff
        %%
        zonMean.Rossby.small.radius=nanmean(M.Rossby.small.radius,2);
        zonMean.Rossby.large.radius=nanmean(M.Rossby.large.radius,2);
        %%
        zonMean.Rossby.small.phaseSpeed=nanmean(M.Rossby.small.phaseSpeed,2);
        zonMean.Rossby.large.phaseSpeed=nanmean(M.Rossby.large.phaseSpeed,2);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OUT=weightedZonMean(MS,weight)
    warning('off','MATLAB:divideByZero') %#ok<*RMWRN>
    weight(weight==0)=nan;
    OUT.mean=nansum(MS.mean.*weight,2)./nansum(weight,2);
    OUT.std=nansum(MS.std.*weight,2)./nansum(weight,2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dist]=setupDist(map)
    A={'traj';'merid';'zonal'};
    B={'fromBirth';'tillDeath'};
    for a=A'
        for b=B'
            [dist.(a{1}).(b{1})]=protoInit(map.proto);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [d,drct]=diststuff(geo)
    %      d2k=@(laloA,laloB)  deg2km(distance(laloA,laloB));
    d2mR=@(degs,direc)  deg2km(degs).*direc*1000;
    geo=[geo(1,:); geo];
    LA=geo(:,1);
    LO=geo(:,2);
    latmean = nanmean(LA);
    lonmean = 42; % irrelevant
    %%
    [d.traj.deg, drct.traj]=distance(geo(1:end-1,:),geo(2:end,:));
    d.traj.m=deg2km(d.traj.deg)*1000;
    d.traj.fromBirth = cumsum(d.traj.m);
    d.traj.tillDeath =  d.traj.fromBirth(end) - d.traj.fromBirth ;
    %%
    [d.zonal.deg, drct.zonal]=distance('rh',latmean,LO(1:end-1),latmean,LO(2:end));
    drct.zonal(drct.zonal<=180 & drct.zonal >= 0) = 1;
    drct.zonal(drct.zonal> 180 & drct.zonal <= 360) = -1;
    d.zonal.m=d2mR(d.zonal.deg,drct.zonal);
    d.zonal.fromBirth = cumsum(d.zonal.m);
    d.zonal.tillDeath =  d.zonal.fromBirth(end) - d.zonal.fromBirth ;
    %%
    [d.merid.deg, drct.merid]=distance(LA(1:end-1),lonmean,LA(2:end),lonmean);
    drct.merid(drct.merid<=90 & drct.merid >= 270) = 1;
    drct.merid (drct.merid > 90 & drct.merid < 270) = -1;
    d.merid.m=d2mR(d.merid.deg,drct.merid);
    d.merid.fromBirth = cumsum(d.merid.m);
    d.merid.tillDeath =  d.merid.fromBirth(end) - d.merid.fromBirth ;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [param]=protoInit(proto,type)
    if nargin < 2, type='nan'; end
    param.mean=sparse(proto.(type));
    param.std=sparse(proto.(type));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function old=comboMS(old,new,DD)
    subFields=DD.FieldKeys.MeanStdFields;
    xtrctMS=@(S,F) cell2mat(extractdeepfield(S,[F]));
    for ff=1:numel(subFields)
        %%	 extract current field to mean/std level
        value.new=xtrctMS(new,subFields{ff});
        value.old=xtrctMS(old,subFields{ff});
        %% combo update
        combo.mean=ComboMean(new.visits.all,old.visits.all,value.new.mean,value.old.mean);
        combo.std=ComboStd(new.visits.all,old.visits.all,value.new.std,value.old.std);
        %% set to updated values
        subsubFields = textscan(subFields{ff},'%s','Delimiter','.');
        meanfields={[subsubFields{1};'mean']};
        stdfields={[subsubFields{1};'std']};
        old=setfield(old,meanfields{1}{:},combo.mean);
        old=setfield(old,stdfields{1}{:},combo.std);
    end
    old.visits.all=old.visits.all + new.visits.all;
    old.visits.single=old.visits.single + new.visits.single;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ALL=comboAllMaps(map,DD)
    subfieldstrings=DD.FieldKeys.MeanStdFields;
    for sense=[{'AntiCycs'},{'Cycs'}];
        sen=sense{1};
        ALL.(sen)=map(1).(sen);
        T=disp_progress('init',['combining results from all threads - ',sen,' ']);
        for tt=1:numel(map) %threads
            T=disp_progress('calc',T,DD.threads.num,DD.threads.num);
            new =  map(tt).(sen);
            if tt>1
                for ff=1:numel(subfieldstrings)
                    %%	 extract current field to mean/std level
                    value.new=cell2mat(extractdeepfield(new,[subfieldstrings{ff}]));
                    value.old=cell2mat(extractdeepfield(old,[subfieldstrings{ff}]));
                    %% nan2zero
                    value.new.mean(isnan(value.new.mean))=0;
                    value.old.mean(isnan(value.old.mean))=0;
                    value.new.std(isnan(value.new.std))=0;
                    value.old.std(isnan(value.old.std))=0;
                    %% combo update
                    combo.mean=ComboMean(new.visits.all,old.visits.all,value.new.mean,value.old.mean);
                    combo.std=ComboStd(new.visits.all,old.visits.all,value.new.std,value.old.std);
                    %% set to updated values
                    fields = textscan(subfieldstrings{ff},'%s','Delimiter','.');
                    meanfields={[fields{1};'mean']};
                    stdfields={[fields{1};'std']};
                    ALL.(sen)=setfield(ALL.(sen),meanfields{1}{:},combo.mean);
                    ALL.(sen)=setfield(ALL.(sen),stdfields{1}{:},combo.std);
                end
                ALL.(sen).visits.all=ALL.(sen).visits.all + new.visits.all;
                ALL.(sen).visits.single=ALL.(sen).visits.single+ new.visits.single;
            end
            old=ALL.(sen);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function map=initmap(DD)
    map=load([DD.path.root,'protoMaps.mat']);
    subfieldstrings=DD.FieldKeys.MeanStdFields;
    [MSproto]=protoInit(map.proto);
    for ff=1:numel(subfieldstrings)
        fields = textscan(subfieldstrings{ff},'%s','Delimiter','.');
        meanfields={[fields{1};'mean']};
        stdfields={[fields{1};'std']};
        map=setfield(map,meanfields{1}{:},MSproto.mean);
        map=setfield(map,stdfields{1}{:},MSproto.std);
    end
    map.visits.single=map.proto.zeros;
    map.visits.all=map.proto.zeros;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [targ]=uniqMedianStd(idx,source,targ)
    [uni,~,b]= unique(idx);
    for uu=1:numel(uni)
        targ.mean(uni(uu))=nanmedian(source(b==uu));
        targ.std(uni(uu))=nanstd(source(b==uu));
    end
end
