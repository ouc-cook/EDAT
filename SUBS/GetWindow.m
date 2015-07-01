function [window,lonlat]=GetWindow(file,mapin,filePattern)
    disp('assuming identical lon/lat for all files!!!')
    %% get data
    % only need lon and lat
    patt.lat=filePattern.lat;
    patt.lon=filePattern.lon;
    [lonlat,unreadable]=GetFields(file,patt);
    if unreadable.is; error(['cant read ' file]); end
    %% find window mask
    window=FindWindowMask(lonlat,mapin);
    %% full size
    window.fullsize=size(lonlat.lon);
    %% find rectangle enclosing all applicable data
    [window.limits, window.type]=FindRectangle(window.flag);
    %% size
    window.size=WriteSize(window);   
end
function S=WriteSize(w)
    switch w.type
        case 'zonCross'
            S.X = w.limits.east + w.fullsize(2)+1 - w.limits.west;
        otherwise
            S.X = w.limits.east-w.limits.west +1;
    end
    S.Y = w.limits.north-w.limits.south +1;
end
function window=FindWindowMask(grids,M)
    %% tag all grid points fullfilling all desired lat/lon limits
    if M.east>M.west
        window.flag= grids.lon>=M.west & grids.lon<=M.east & grids.lat>=M.south & grids.lat<=M.north ;
    elseif M.west>M.east  %crossing 180 meridian
        window.flag=((grids.lon>=M.west & grids.lon<=180) | (grids.lon>=-180 & grids.lon<=M.east)) & grids.lat>=M.south & grids.lat<=M.north ;
    end
end
function [limits,type]=FindRectangle(flag)
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
        %% continuous in x
        limits.west=1;
        limits.east=length(cols);
        type='globe';
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
