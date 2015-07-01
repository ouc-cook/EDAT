function [win,lonlat]=GetWindow3(file,mapin)
    disp('assuming identical lon/lat for all files!!!')
    %% get data
    % only need lon and lat
    patt.lat=mapin.keys.lat;
    patt.lon=mapin.keys.lon;
    [lonlat,unreadable]=GetFields(file,patt);    
    if unreadable.is; error(['cant read ' file]); end
    %% find win mask
    [win,triplemap]=FindWindowMask(lonlat,mapin);
    %% full size
    [win.fullsize.y, win.fullsize.x]=size(lonlat.lon);
    %% find rectangle enclosing all applicable data
    [win]=FindRectangle(win,lonlat.lon,triplemap);
    %% append 1/10 of map for tracking if conti in x
    [win]=ZonalProblem(win);
    %%
    [win.geo]=getGeoLims(win,lonlat);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [geo]=getGeoLims(w,lonlat)
    rs=@(x) reshape(x,1,[]);
    geo.south = min(rs(lonlat.lat(w.flag)));
    geo.north = max(rs(lonlat.lat(w.flag)));
    geo.west  = min(rs(lonlat.lon(w.flag)));
    geo.east  = max(rs(lonlat.lon(w.flag)));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [w]=ZonalProblem(w)
    [w.iy,w.ix] = raise_1d_to_2d(w.fullsize.y,w.idx);
    if strcmp(w.type,'zonCross') || strcmp(w.type,'globe')
        w.seam=true;
        if strcmp(w.type,'globe')
            xadd = round(w.dim.x/10);
            w.ix = w.ix(:,[1:end 1:xadd]);
            w.iy = w.iy(:,[1:end 1:xadd]);
            w.idx = w.idx(:,[1:end 1:xadd]);
        end
    else
        w.seam=false;
    end
    [w.dimPlus.y, w.dimPlus.x] = size(w.ix);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [win,trip]=FindWindowMask(fields,M)
    %% init
    trip2any = @(lola) any(reshape(lola,size(lola,1),[],3),3);
    glo      = fields.lon;
    trip.lon = [glo-360 glo glo+360];
    trip.lat = repmat(fields.lat,1,3);
    trip.idx = repmat(reshape(1:numel(glo),size(glo)),1,3);
    %% meridional
    bool.la = (trip.lat >= M.south) & (trip.lat <= M.north);
    %% zonal
    switch sign(M.east - M.west)
        case 1  % normal
            bool.lo = (trip.lon >= M.west) & (trip.lon <= M.east);
        case -1 % stitch
            bool.lo = (trip.lon <= M.west) & (trip.lon >= M.east);
        case 0  % zon all
            bool.lo = true(size(trip.lon));
    end
    %% combined
    win.flag  = trip2any(bool.lo) & trip2any(bool.la);
    trip.flag = (bool.lo) & (bool.la);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [win]=FindRectangle(win,lon,trip)
    %% sum flag in both dirs
    cols  = sum(win.flag,1);
    cols3 = sum(trip.flag,1);
    rows  = sum(win.flag,2);
    %% find zonal edges
    x.x             = length(cols);
    x.a.Zero        = find(cols   == 0,1,'first');
    x.b.Zero        = find(cols   == 0,1,'last');
    x.a.nonZero     = find(cols   ~= 0,1,'first');
    x.b.nonZero     = find(cols   ~= 0,1,'last');
    T.a.nonZero = find(cols3  ~= 0,1,'first');
    T.b.nonZero = find(cols3  ~= 0,1,'last');
    if T.b.nonZero - T.a.nonZero + 1 > x.x
        T.b.nonZero = T.a.nonZero + x.x - 1; % full X
    end
    %% merid
    y.a.nonZero     = find(rows   ~= 0,1,'first');
    y.b.nonZero     = find(rows   ~= 0,1,'last');
    %% size in
    win.dim.x = T.b.nonZero     - T.a.nonZero     + 1;
    win.dim.y = y.b.nonZero     - y.a.nonZero     + 1;
    %% limits
    win.limits=getLimits(x.x,T,rows);
    %% idx
    win.idx = trip.idx(y.a.nonZero:y.b.nonZero,T.a.nonZero:T.b.nonZero);
    %% type
    win.type = detectType(lon,win,cols,x);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function limits=getLimits(X,T,rows)
    limits.west=mod(T.a.nonZero,X);
    limits.east=mod(T.b.nonZero,X);
    limits.east(limits.east==0) = X; % full X case
    limits.north=find(rows,1,'last');
    limits.south=find(rows,1,'first');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function type=detectType(lon,win,cols,x)
    mapIsGlobe=checkWhetherMapInSpansGlobe(lon,win.flag);
    mapFlaggedFullyInX = all(cols~=0);
    if mapFlaggedFullyInX
        [type]=fullXCase(mapIsGlobe);
    else % zonal cut
        [type]=nonFullXCase(x,cols);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function yes=checkWhetherMapInSpansGlobe(lon,flag)
    yes=false;
    maxdel = max(max(diff(lon,1,2) ,[] ,1));
    lonRange.min    = min(lon(flag));
    lonRange.max    = max(lon(flag));
    if lonRange.max - lonRange.min + maxdel >=  360
        yes=true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [type]=fullXCase(mapIsGlobe)
    if mapIsGlobe % continuous in x
        type='globe';
    else % non-continuous in x but full map in x
        type='normal';
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [type]=nonFullXCase(x,cols)
    regularWindowOnMap          =   (x.a.Zero==1 && x.b.Zero==x.x);
    boxCrossesZonalBndry        =   (x.a.nonZero==1 && x.b.nonZero==x.x && any(cols==0));
    boxBeginsAtWesternEdgeOfMap =   (x.a.nonZero==1 && x.b.nonZero~=x.x && x.b.Zero==x.x);
    boxEndsOnEasternEdge        =   (x.a.nonZero~=1 && x.b.nonZero==x.x && x.a.Zero==1);
    %%
    if regularWindowOnMap
        type='normal';
    elseif boxCrossesZonalBndry
        type='zonCross';
    elseif boxBeginsAtWesternEdgeOfMap
        type='beginsAtWesternBndry';
    elseif boxEndsOnEasternEdge
        type='beginsAtEasternBndry';
    else
        error('map problems')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


