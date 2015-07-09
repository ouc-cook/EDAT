function P01_analyzeTracks
    DD = initialise();
    main(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    tracks = DD.path.tracks.files;
    parfor tt=1:numel(tracks)
        operateTrack(tracks(tt).fullname)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function operateTrack(trackFile)
    track = load(trackFile);
    track.analyzed = alterTrack(track.track);
    updateTrack(track,trackFile)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateTrack(track,trackFile) %#ok<INUSL>
    save(trackFile,'-struct','track');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analy = alterTrack(track)
    %%
    analy.dist = distanceStuff(track);
    %%
    analy.vel  = velocityStuff(analy.dist);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[vel] = velocityStuff(dist)
    kmPd2mPs = @(x) x*1000/24/60/60;
    vel.t  = (dist.time(1):1:dist.time(end))';
    vel.u = kmPd2mPs(differentiate(dist.fit.x, vel.t));
    vel.v = kmPd2mPs(differentiate(dist.fit.y, vel.t));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dist]=distanceStuff(track)
    zeroShift=@(x) x-x(1);
    lat = extractdeepfield(track,'geo.lat');
    lon = extractdeepfield(track,'geo.lon');
    %% get distance-from-birth components
    dist.y = zeroShift(deg2km(lat)             );
    dist.x = zeroShift(deg2km(lon).* cosd(lat) );
    dist.time = extractdeepfield(track,'daynum');
    %% build spline cfit to distance vectors
    dist.fit.y = fit(dist.time',dist.y','smoothingspline');
    dist.fit.x = fit(dist.time',dist.x','smoothingspline');
end