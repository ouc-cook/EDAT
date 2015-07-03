% save one file window.mat which includes all info about geometry of data
function window = constructGeoFile(DD)
    %% get sample window
    sampleFile = DD.path.raw.files(1).fullname;
    [window]   = GetWindow3(sampleFile,DD.map.in);
    %% read geo info
    keys.lat = DD.map.in.keys.lat;
    keys.lon = DD.map.in.keys.lon;
    [raw_fields] = GetFields(sampleFile,keys);
    %% cut and append lat/lon to window struct
    [window] = mergeStruct2(window,cutSlice(raw_fields,window.idx));
    %% get distance fields
    [window.dy,window.dx] = getDyDx(window.lat,window.lon);
    %% save
    DD.map.window = window;
    DD.map.windowFile = [DD.path.root 'window.mat'];
    save(DD.map.windowFile,'window');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dy,dx]=getDyDx(lat,lon)
    betweenNodesX = @(lalo) (lalo(:,2:end) + lalo(:,1:end-1))/2; %
    betweenNodesY = @(lalo) (lalo(2:end,:) + lalo(1:end-1,:))/2;
    copyBndryX    = @(X) X(:,[1 1:end end]);
    copyBndryY    = @(Y) Y([1 1:end end],:);
    deg2m         = @(degs) deg2km(degs) * 1e3;
    %% y
    dy = deg2m(abs(diff(lat,1,1)));
    %% x
    dlon = abs(diff(lon,1,2));
    dlon(dlon>180) = abs(dlon(dlon>180) - 360);
    dx = deg2m(dlon) .* cosd(betweenNodesX(lat));
    %% mean back to nodes
    dx=copyBndryX(betweenNodesX(dx));
    dy=copyBndryY(betweenNodesY(dy));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%