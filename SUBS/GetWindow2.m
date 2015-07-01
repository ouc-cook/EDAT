function [window,lonlat]=GetWindow2(file,mapin)
    disp('assuming identical lon/lat for all files!!!')
    %% get data
    % only need lon and lat
    patt.lat=mapin.keys.lat;
    patt.lon=mapin.keys.lon;
    [lonlat,unreadable]=GetFields(file,patt);
    if unreadable.is; error(['cant read ' file]); end
    %% find window mask
    window=FindWindowMask(lonlat,mapin);
    %% full size
    window.fullsize=size(lonlat.lon);
    %% find rectangle enclosing all applicable data
    [window.limits, window.type]=FindRectangle(window.flag,lonlat.lon);
    %% size
    window.size=WriteSize(window);
    %%
    [window.iy,window.ix,window.seam]=ZonalProblem(window);
     %% size    
[window.sizePlus.Y, window.sizePlus.X] = size(window.ix); 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x,seam]=ZonalProblem(w)
    %% full globe?
    seam=true;
    if strcmp(w.type,'globe')
        [y,x]=AppendIfFullZonal(w.limits,w.size);% longitude edge crossing has to be addressed
    else
        [y,x,seam]=nonXContinuousCase(w);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x,seam]=nonXContinuousCase(w)
    %% seam crossing?
    if strcmp(w.type,'zonCross') % ie not full globe but both seam ends are within desired window
        [y,x]=SeamCross(w.limits,w.size);
    else % desired piece is within global fields, not need for stitching
        seam=false;
        [y,x]=AllGood(w.limits);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x]=AppendIfFullZonal(l,s)
    xadd=round(s.X/10);
    [x,y]=meshgrid([1:s.X, 1:xadd],l.south:l.north);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [y,x]=SeamCross(l,s)
    %% stitch 2 pieces 2g4
    [x,y]=meshgrid( [l.west:s.X, 1:l.east] , l.south:l.north );
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [y,x]=AllGood(l)
    %% clear cut
    [x,y]=meshgrid(l.west:l.east,l.south:l.north);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S=WriteSize(w)
    switch w.type
        case 'zonCross'
            S.X = w.limits.east + w.fullsize(2)+1 - w.limits.west;
        otherwise
            S.X = w.limits.east-w.limits.west +1;
    end
    S.Y = w.limits.north-w.limits.south +1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function window=FindWindowMask(grids,M)
    %% tag all grid points fullfilling all desired lat/lon limits
    if M.east>M.west
        window.flag= grids.lon>=M.west & grids.lon<=M.east & grids.lat>=M.south & grids.lat<=M.north ;
    elseif M.west>=M.east  %crossing 180 meridian
        window.flag=((grids.lon>=M.west & grids.lon<=180) | (grids.lon>=-180 & grids.lon<=M.east)) & grids.lat>=M.south & grids.lat<=M.north ;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [limits,type]=FindRectangle(flag,lon)
    %% sum flag in both dirs
    cols=sum(flag,1);
    rows=sum(flag,2);
    %% find zonal edges
    X=length(cols);
    xa.z=find(cols==0,1,'first');
    xb.z=find(cols==0,1,'last');
    xa.nz=find(cols~=0,1,'first');
    xb.nz=find(cols~=0,1,'last');
    %% cases
    if all(cols~=0)
        %% check whether map.in spans globe
        lonRange.del=max(max(diff(lon,1,2) ,[],1));
        lonRange.min=min(lon(flag));
        lonRange.max=max(lon(flag));
        if lonRange.max - lonRange.min + lonRange.del >=  360
            %% continuous in x
            limits.west=1;
            limits.east=length(cols);
            type='globe';
        else
            %% non-continuous in x but full map in x
            limits.west=1;
            limits.east=length(cols);
            type='normal';
        end
    else
        if (xa.z==1 && xb.z==X)
            %% normal case
            limits.west=xa.nz;
            limits.east=xb.nz;
            type='normal';
        elseif (xa.nz==1 && xb.nz==X && any(cols==0))
            %% box crosses zonal bndry
            limits.west=xb.z+1;
            limits.east=xa.z-1;
            type='zonCross';
        elseif xa.nz==1 && xb.nz~=X && xb.z==X
            %% box begins at western edge of map
            limits.west=1;
            limits.east=xb.nz;
            type='beginsAtWesternBndry';
        elseif xa.nz~=1 && xb.nz==X && xa.z==1
            %% box ends on eastern edge
            limits.west=xa.nz;
            limits.east=X;
            type='beginsAtEasternBndry';
        else
            error('map problems')
        end
    end
    %% north/south
    limits.north=find(rows,1,'last');
    limits.south=find(rows,1,'first');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





