function P01_analyzeTracks
    DD = initialise;
    main(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    tracks = DD.path.tracks.files;
    parfor_progress(numel(tracks));
    parfor tt=1:numel(tracks)
        operateTrack(tracks(tt).fullname)
    end
    parfor_progress(0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function operateTrack(trackFile)
    parfor_progress;
    track = load(trackFile);
    track.analyzed = alterTrack(track.track);
    updateTrack(track,trackFile);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateTrack(track,trackFile) %#ok<INUSL>
    save(trackFile,'-struct','track');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analy = alterTrack(track)
    %%
    analy.dist       = distanceStuff(track);
    %%
    analy.daily.vel  = velocityStuff(analy.dist);
    %%
    analy.daily.geo  = geoStuff(analy);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[geo] = geoStuff(analy)    
   geo.lat = spline(analy.dist.time,analy.dist.lat,analy.daily.vel.t');
   geo.lon = spline(analy.dist.time,analy.dist.lon,analy.daily.vel.t');      
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
    dist.lat = extractdeepfield(track,'geo.lat');
    dist.lon = extractdeepfield(track,'geo.lon');
    %% get distance-from-birth components
    dist.y = zeroShift(deg2km(dist.lat)             );
    dist.x = zeroShift(deg2km(dist.lon).* cosd(dist.lat) );
    dist.time = extractdeepfield(track,'daynum');
    %% build spline cfit to distance vectors
    dist.fit.y = fit(dist.time',dist.y','smoothingspline');
    dist.fit.x = fit(dist.time',dist.x','smoothingspline');
end