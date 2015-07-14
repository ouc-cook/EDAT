function [win,lonlat]=GetWindow3(file,mapIn)
    %% get lon and lat
    keyPattern.lat = mapIn.keys.lat;
    keyPattern.lon = mapIn.keys.lon;
    [lonlat] = GetFields(file,keyPattern);
    %% find win mask
    [win,triplemap] = FindWindowMask(lonlat,mapIn);
    %% full size
    [win.fullsize.y, win.fullsize.x] = size(lonlat.lon);
    %% find rectangle enclosing all applicable data
    [win] = FindRectangle(win,lonlat.lon,triplemap);
    %% append 1/10 of map for tracking if conti in x
    [win] = ZonalProblem(win);
    %%
    [win.geo] = getGeoLims(win,lonlat);
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
% append 3 copies of the fields zonally in order to allow for windows
% that cross the west/east boundary (the 'seam') of the input maps.
% trip: resp. tripple maps
% relevant: indices within desired window (boolean)
function [win,trip] = FindWindowMask(fields,M)
    %% init
    trip2any = @(in) any(reshape(in,size(in,1),[],3),3); % check for any of the 3 possibilties
    if M.south > M.north , error('flip lat limits! wrong way arround!'),end
    glo      = fields.lon;
    trip.lon = [glo-360 glo glo+360];
    trip.lat = repmat(fields.lat,1,3);
    trip.idx = repmat(reshape(1:numel(glo),size(glo)),1,3); % 1d indeces
    %% meridional
    relevant.la = (trip.lat >= M.south) & (trip.lat <= M.north);
    %% zonal
    switch sign(M.east - M.west)
        case 1  % normal
            relevant.lo = (trip.lon >= M.west) & (trip.lon <= M.east);
        case -1 % stitch
            relevant.lo = (trip.lon <= M.west) & (trip.lon >= M.east);
        case 0  % zon all
            relevant.lo = true(size(trip.lon));
    end
    %% boolean for single map
    win.flag  = trip2any(relevant.lo) & trip2any(relevant.la);
    %% boolean for tripple map (needed again later)
    trip.flag = (relevant.lo) & (relevant.la);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [win]=FindRectangle(win,lon,trip)
    %% sum flag in both dirs
    cols  = sum(win.flag,1); % number of rows for each column
    cols3 = sum(trip.flag,1);
    rows  = sum(win.flag,2); % number of columns for each row
    %% find zonal edges
    X.num             = length(cols);
    X.a.Zero        = find(cols   == 0,1,'first');
    X.b.Zero        = find(cols   == 0,1,'last');
    X.a.nonZero     = find(cols   ~= 0,1,'first');
    X.b.nonZero     = find(cols   ~= 0,1,'last');
    Xtrip.a.nonZero = find(cols3  ~= 0,1,'first');
    Xtrip.b.nonZero = find(cols3  ~= 0,1,'last');
    if Xtrip.b.nonZero - Xtrip.a.nonZero + 1 > X.num
        Xtrip.b.nonZero = Xtrip.a.nonZero + X.num - 1; % full X
    end
    %% merid
    Y.a.nonZero     = find(rows   ~= 0,1,'first');
    Y.b.nonZero     = find(rows   ~= 0,1,'last');
    %% size in
    win.dim.x = Xtrip.b.nonZero     - Xtrip.a.nonZero     + 1;
    win.dim.y = Y.b.nonZero         - Y.a.nonZero         + 1;
    %% limits
    win.limits = getLimits(X.num,Xtrip,rows);
    %% idx
    win.idx = trip.idx(Y.a.nonZero:Y.b.nonZero,Xtrip.a.nonZero:Xtrip.b.nonZero);
    %% type
    win.type = detectType(lon,win,cols,X);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function limits = getLimits(Xnum,Xtrip,rows)
    %% mod by Xnum to get relevant column for single map
    limits.west = mod(Xtrip.a.nonZero,Xnum);
    limits.east = mod(Xtrip.b.nonZero,Xnum);
    limits.east(limits.east==0) = Xnum; % full X case
    %%
    limits.north = find(rows,1,'last');
    limits.south = find(rows,1,'first');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function type = detectType(lon,win,cols,x)
    mapIsGlobe = checkWhetherMapInSpansGlobe(lon,win);
    mapFlaggedFullyInX = all(cols~=0);
    if mapFlaggedFullyInX
        [type]=fullXCase(mapIsGlobe);
    else % zonal cut
        [type]=nonFullXCase(x,cols);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function does = checkWhetherMapInSpansGlobe(lon,win)
    does = false;
    lonDiff = median(median(diff(lon,1,2))); % look for average lon diff
    lonRange.min    = min(lon(win.flag));
    lonRange.max    = max(lon(win.flag));
    if lonRange.max - lonRange.min + lonDiff >=  360
        does = true;
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
function [type]=nonFullXCase(X,cols)
    regularWindowOnMap          =   (X.a.Zero==1 && X.b.Zero==X.num);
    boxCrossesZonalBndry        =   (X.a.nonZero==1 && X.b.nonZero==X.num && any(cols==0));
    boxBeginsAtWesternEdgeOfMap =   (X.a.nonZero==1 && X.b.nonZero~=X.num && X.b.Zero==X.num);
    boxEndsOnEasternEdge        =   (X.a.nonZero~=1 && X.b.nonZero==X.num && X.a.Zero==1);
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


