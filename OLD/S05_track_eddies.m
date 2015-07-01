%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 17:04:31
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% inter-allocate different time steps to determine tracks of eddies
function S05_track_eddies
    %% init
    DD=initialise('eddies',mfilename);
     DD.map.window = getfieldload(DD.path.windowFile,'window');
    %% rm old files
    rmoldtracks(DD)
    %% parallel!
    init_threads(2);
    main(DD)
    %% update infofile
    conclude(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    if DD.debugmode
        spmd_body(DD)
    else
        spmd(2)
            spmd_body(DD)
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% main %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rmoldtracks(DD)
    if ~isempty(DD.path.tracks.files)
        if DD.overwrite
            system(['rm -r ' DD.path.tracks.name '*.mat']);
            sleep(5*60);
        else
            warning('mv old tracks first')
            sleep(5*60);
            system(['rm -r ' DD.path.tracks.name '*.mat']);
            sleep(5*60);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(DD)
    %% one thread do cycs, other acycs
    sen = DD.FieldKeys.senses{labindex};
    %% set up tracking procedure
    [tracks,OLD,phantoms] = set_up_init(DD,sen);
    numDays = DD.checks.passedTotal;
    %% start tracking
    T=disp_progress('init',['tracking ' sen]);
    for jj=2:numDays
        T=disp_progress('disp',T,numDays-1,numDays);
        %% set up current day
        [NEW]=set_up_today(DD,jj,sen);
        %% do calculations and archivings
        [OLD,tracks]=operate_day(OLD,NEW,tracks,DD,phantoms,sen);
    end
    %% write/kill dead
    archive_stillLiving(tracks, DD,sen);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [OLD,tracks]=operate_day(OLD,NEW,tracks,DD,phantoms,sen)
    %% in case of full globe only
    if phantoms
        [NEW]=kill_phantoms(NEW);
    end
    %% find minium distances between old and new time step eddies
    [MinDists]=EligibleMinDistsMtrx(OLD,NEW,DD);
    %% determine which ones are tracked/died/new
    TDB=tracked_dead_born(MinDists);
    %% append tracked to respective cell of temporary archive 'tracks'
    [tracks,NEW]=append_tracked(TDB,tracks,OLD,NEW);
    %% append new ones to end of temp archive
    [tracks,NEW]=append_born(TDB, tracks, OLD,NEW);
    %% write/kill dead
    [tracks]=archive_dead(TDB, tracks, OLD.eddies, DD,sen);
    %% swap
    OLD=NEW;

end
%%%%%%%%%%%%%%%%%%% subs %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tracks,NEW]=append_tracked(TDB,tracks,OLD,NEW)
    %% get
    ID.arch=cat(2,tracks.ID);
    flag.new=TDB      .inNew.tracked;
    idx.old=TDB.inNew.n2oi(flag.new); % get index in old data
    ID.old =cat(2,OLD.eddies(idx.old).ID); % get ID
    IDc=num2cell(ID.old);
    %% find position in archive
    [~,idx.arch] = ismember(ID.old,ID.arch);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    age = num2cell(cat(2,tracks(idx.arch).age) + NEW.time.delT); % get new age
    %% set
    [NEW.eddies(flag.new).ID] = deal(IDc{:}); % set ID accordingly for new data
    [NEW.eddies(flag.new).age] = deal(age{:}); % set age accordingly for new data
    [tracks(idx.arch).age]= deal(age{:});		% update age in archive
    %% append tracks into track cells
    idx.new=find(flag.new);
    for aa=1:length(idx.arch)
        aidx=idx.arch(aa);
        len=tracks(aidx).length+1;
        tracks(aidx).track{1}(len)=NEW.eddies(idx.new(aa));
        tracks(aidx).length=len;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [NEW]=set_up_today(DD,jj,sen)
    NEW.eddies=getfield(rmfield(read_fields(DD,jj,'eddies'),{'filename','pass'}),sen);
    %% get delta time
    NEW.time.daynum=DD.checks.passed(jj).daynums;
    NEW.time.delT=DD.checks.del_t(jj);
    [NEW.lon,NEW.lat]=get_geocoor(NEW.eddies);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tracks,OLD,phantoms]=set_up_init(DD,sen)
    %% determine whether double eddies might be present due to full lon
    phantoms=strcmp(DD.map.window.type,'globe');
    %% read eddies
    eddies=read_fields(DD,1,'eddies');
    [tracks,OLD.eddies]=init_day_one(eddies,sen);
    %% append geo-coor vectors for min_dist function
    [OLD.lon,OLD.lat]=get_geocoor(OLD.eddies);
    %% kill doubles from overlap
    if phantoms
        [OLD]=kill_phantoms(OLD);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function archive_stillLiving(tracks,DD,sen)
    age = cat(1,tracks(:).age);
    id = cat(1,tracks(:).ID);
    pass = age >= DD.thresh.life;
    %%  write to 'heap'
    if any(pass)
        lens = cat(2,tracks(pass).length); % so as not to include empty values
         ll=0;
        for pa = find(pass)';ll=ll+1;
            archive(tracks(pa).track{1}(1:lens(ll)), DD.path.tracks.name, id(pa),sen);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tracks]=archive_dead(TDB, tracks, old,DD,sen)
    %% collect all ID's in archive
    ArchIDs=cat(2,tracks.ID);
    %% all indeces in old set of dead eddies
    dead_idxs=TDB.inOld.dead;
    %% find which ones to write and kill
    AIdxdead = find(ismember(ArchIDs',cat(1,old(dead_idxs).ID)));
    age = cat(1,tracks(AIdxdead).age);
    id = cat(1,tracks(AIdxdead).ID);
    pass = age >= DD.thresh.life;
    %%  write to 'heap'
    if any(pass)
        lens=cat(2,tracks(AIdxdead(pass)).length); % so as not to include empty values
        ll=0;
        for pa=find(pass)'; ll=ll+1;
            archive(tracks(AIdxdead(pa)).track{1}(1:lens(ll)), DD.path.tracks.name,id(pa),sen);
        end
    end
    %% kill in 'stack'
    tracks(AIdxdead)=[];	% get rid of dead matter!
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function archive(track,path,id,sen)
    %% write out file (one per eddy)
    EoD=[sprintf('%07i',id)];
    filename=[ path 'TRACK' datestr(track(1).daynum,'yyyymmdd')...
        '-' datestr(track(end).daynum,'yyyymmdd') '_id' EoD  sprintf('-d%04d',track(end).age) sen '.mat'];
    track(end).filename=filename;
    track(end).sense=sen;    %#ok<*NASGU>
    save(filename,'track');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tracks,NEW]=append_born(TDB, tracks,OLD,NEW)
    maxID=max(max([cat(2,tracks.ID) NEW.eddies.ID  OLD.eddies.ID]));
    flag.born.inNew=(TDB.inNew.born);
    if any(flag.born.inNew)
        %% new Ids and new indices (appended to end of tracks)
        newIds=num2cell(maxID+1:maxID+sum(flag.born.inNew));
        newendIdxs=numel(tracks)+1:numel(tracks)+sum(flag.born.inNew);
        %% deal new ids to eddies
        [NEW.eddies(flag.born.inNew).age]=deal(0);
        [NEW.eddies(flag.born.inNew).ID]=deal(newIds{:});
        %% deal eddies to archive and pre alloc
        idx.born.inNew=find(flag.born.inNew);nn=0;
        for tt=newendIdxs; nn=nn+1;
            tracks(tt).track{1}(1)	=NEW.eddies(idx.born.inNew(nn));
            tracks(tt).track{1}(30)	=tracks(tt).track{1}(1);
        end
        %% set all ages 0
        [tracks(newendIdxs).age]=deal(0);
        %% deal new ids to tracks
        [tracks(newendIdxs).ID]=deal(newIds{:});
        %% init length
        [tracks(newendIdxs).length]=deal(1);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [tracks,new_eddies]=init_day_one(eddies,sen)
    new_eddies=getfield(rmfield(eddies,{'filename','pass'}),sen);
    %% set initial ID's etc
    ee=(1:numel(new_eddies));
    eec=num2cell(ee);
    [new_eddies(1,ee).ID]=deal(eec{:});
    %% store tracks in cells (to allow for arbitr. lengths)
    edsArray=arrayfun(@(x) ({{x}}),new_eddies(1,ee));
    [tracks(ee).track]=deal(edsArray{:});
    [tracks(ee).ID]=deal(eec{:});
    [tracks(ee).age]=deal(0);
    [tracks(ee).length]=deal(1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [TDB]=tracked_dead_born(MD)
    %% idx in old set of min dist claims by new set
    n2oi=MD.new2old.idx;
    %% idx in new set of min dist claims by old set
    o2ni=MD.old2new.idx;
    %% index in new set of claims by old set
    io=MD.old2new.idx(n2oi)';
    %% respective index in new (from new's perspective)
    in=(1:length(n2oi));
    %% min dist values of old set of n2oi
    do=MD.old2new.dist(n2oi)';
    %% respective min dist values in new set
    dn=MD.new2old.dist;
    %% matlab sets dims randomly sometimes for short vecs
    if size(do)~=size(dn), do=do'; end
    if size(io)~=size(in), io=io'; end
    %% agreement among new and old ie definitive tracking (with respect to new set)  NOTE: this also takes care of nan'ed dists from nanOutOfBounds() since nan~=nan !
    TDB.inNew.tracked = ((do == dn) & (io == in));
    %% flag for fresh eddies with respect to new set
    TDB.inNew.born = ~TDB.inNew.tracked;
    %% indeces of deceised eddies with respect to old set
    TDB.inOld.dead=~ismember(1:length(o2ni),n2oi(TDB.inNew.tracked));
    %% remember cross ref
    TDB.inNew.n2oi=n2oi;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out]=kill_phantoms(in)
    %% search for identical eddies
    lola = in.lon + 1i*in.lat; % 2d red
    [~,ui,~]=unique(lola);     % indeces of unique set
    %%
    for fn=fieldnames(in)'
        if size(in.(fn{1})) == size(lola) % field 'time' doesnt need to be corrected
            out.(fn{1}) = in.(fn{1})(ui);
        else
            out.(fn{1}) = in.(fn{1});
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function closeEnough=nanOutOfBounds(NEW,OLD,windowdim)
    %% last lin. index of non-overlapped grid
    maxLin=prod(struct2array(windowdim));
    %% get locations of new eddies
    newLin=extractfield(cat(1,NEW.trackref),'lin');
    %% get possible (future) indeces for old eddies
    oldEllipIncs=cell2mat(extractfield(OLD,'projLocsMask'));
    %% wrap overlap
    newLin = wrapOverlap(newLin,maxLin);
    for kk=1:numel(oldEllipIncs)
        oldEllipIncs(kk).lin = wrapOverlap(oldEllipIncs(kk).lin,maxLin);
    end
    %% build mask. rows -> new, cols -> old
    closeEnough=false(numel(oldEllipIncs),numel(newLin));
    for ii=1:numel(oldEllipIncs)
        closeEnough(ii,:)=ismember(newLin,oldEllipIncs(ii).lin');
    end
    %% ---------------------------
    function V=wrapOverlap(V,m)
        V(V>m) = V(V>m)-m;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pass=checkAmpAreaBounds(OLD,NEW,ampArea)
    %% get amp and area
    amp.old=extractdeepfield(OLD.eddies      ,'peak.amp.to_mean');
    amp.new=extractdeepfield(NEW.eddies      ,'peak.amp.to_mean');
    area.old=extractdeepfield(OLD.eddies      ,'area.intrp');
    area.new=extractdeepfield(NEW.eddies      ,'area.intrp');
    %% get factors between all new and all old
    [AMP.old,AMP.new]=ndgrid(amp.old,amp.new);
    [AREA.old,AREA.new]=ndgrid(area.old,area.new);
    AMPfac=AMP.old./AMP.new;
    AREAfac=AREA.old./AREA.new;
    %% check for thresholds
    pass=(AMPfac <= ampArea(2)) & (AMPfac >= ampArea(1))...
        & (AREAfac <= ampArea(2)) & (AREAfac >= ampArea(1));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [quo,pass]=checkDynamicIdentity(OLD,NEW,thresh)
    RAL=@(M) permute(abs(log10(M)),[3,1,2]);
    %%
    old.peak2ellip=extractdeepfield(OLD.eddies      ,'peak.amp.to_ellipse');
    old.dynRad=extractdeepfield(OLD.eddies      ,'radius.mean');
    new.peak2ellip=extractdeepfield(NEW.eddies      ,'peak.amp.to_ellipse');
    new.dynRad=extractdeepfield(NEW.eddies      ,'radius.mean');
    [P2E.new,P2E.old]=meshgrid(new.peak2ellip,old.peak2ellip);
    [dR.new,dR.old]=meshgrid(new.dynRad,old.dynRad);
    quo.peak2ellip=P2E.new./P2E.old;
    quo.dynRad=dR.new./dR.old;
    %%
    quo.combo=10.^(permute(max([RAL(quo.dynRad); RAL(quo.peak2ellip)],[],1),[2,3,1]));
    %%
    pass= quo.combo <= thresh;
    %     TODO explain
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [LOM,LAM,passLog]=nanUnPassed(LOM,LAM,pass)
    onesonly=@(M) M==1;
    for ff=fieldnames(pass)';f=ff{1};
        passLog.(f)=sum(pass.(f)(:))./numel(pass.(f));
    end
    pass.all=reshape(struct2array(pass),[size(LAM.new),numel(fieldnames(pass))]);
    pass.combo=onesonly(mean(pass.all,3));
    LOM.old(~pass.combo)=nan;
    LOM.new(~pass.combo)=nan;
    LAM.old(~pass.combo)=nan;
    LAM.new(~pass.combo)=nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MD]=EligibleMinDistsMtrx(OLD,NEW,DD)

    %% build geo loc matrices
    [LOM.new,LOM.old]=meshgrid(NEW.lon  ,OLD.lon  );
    [LAM.new,LAM.old]=meshgrid(NEW.lat  ,OLD.lat  );
    %%
    if  DD.switchs.IdentityCheck
        [~,pass.idc]=checkDynamicIdentity(OLD,NEW,DD.thresh.IdentityCheck);
    end
    %%
    if DD.switchs.AmpAreaCheck
        [pass.AmpArea]=checkAmpAreaBounds(OLD,NEW,DD.thresh.ampArea);
    end
    %%
    if DD.switchs.distlimit
        [pass.ellipseDist]=nanOutOfBounds(NEW.eddies ,OLD.eddies, DD.map.window.dim );
    end
    %%
    if exist('pass','var')
        [LOM,LAM,~]=nanUnPassed(LOM,LAM,pass);
    end
    %% calc distances between all from new to all from old
    DIST=distance(LAM.new,LOM.new,LAM.old,LOM.old);
    %% find min dists
    [MD.new2old.dist,MD.new2old.idx]=min(DIST,[],1);
    [MD.old2new.dist,MD.old2new.idx]=min(DIST,[],2);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lon, lat]=get_geocoor(eddies)
    lon=extractfield(cat(1,eddies.geo),'lon');
    lat=extractfield(cat(1,eddies.geo),'lat');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
