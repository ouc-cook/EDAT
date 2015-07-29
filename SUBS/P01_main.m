function P01_main(DD,tracks,lims)
    T = disp_progress('init','altering tracks');
    spmd(DD.threads.num)
        for ff = lims(labindex,1):lims(labindex,2)
            T = disp_progress('draw',T,diff(lims(labindex,:))+1);
            operateTrack(tracks(ff).fullname);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function operateTrack(trackFile)
  
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
    [analy.dist,analy.time]             = distanceStuff(track);
    %%
    [analy.daily.vel,analy.daily.time]  = velocityStuff(analy.dist,analy.time);
    %%
    analy.daily.geo                     = geoStuff(analy);
    %%
    analy.daily.scale                   = scaleStuff(track,analy);
    %%
    analy.birthdeath                    = birthdeathPlaceStuff(track);
    %%
    analy.daily.age                     = ageStuff(track);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function age = ageStuff(track)
    age = track(1).age:1:track(end).age;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% linear indices of window.mat geometry
function   bd = birthdeathPlaceStuff(track)
    bd.birth.lat = track(1).geo.lat;
    bd.birth.lon = track(1).geo.lon;
    bd.death.lat = track(end).geo.lat;
    bd.death.lon = track(end).geo.lon;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[geo] = geoStuff(analy)
    geo.lat = spline(analy.time,analy.dist.lat,analy.daily.time');
    geo.lon = spline(analy.time,analy.dist.lon,analy.daily.time');
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[scale] = scaleStuff(track,analy)
    scale = extractdeepfield(track,'radius.mean');
    scale = spline(analy.time,scale,analy.daily.time');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[vel,dailyTime] = velocityStuff(dist,time)
    kmPd2mPs = @(x) x*1000/24/60/60;
    dailyTime  = (time(1):1:time(end))';
    vel.u = kmPd2mPs(differentiate(dist.fit.x, dailyTime));
    vel.v = kmPd2mPs(differentiate(dist.fit.y, dailyTime));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dist,time] = distanceStuff(track)
    zeroShift=@(x) x-x(1);
    dist.lat = extractdeepfield(track,'geo.lat');
    dist.lon = extractdeepfield(track,'geo.lon');
    %% get distance-from-birth components
    dist.y = deg2km(zeroShift(dist.lat)                  );
    dist.x = deg2km(zeroShift(wrapTo360(dist.lon)).* cosd(dist.lat) );
    time = extractdeepfield(track,'daynum');
    %% build spline cfit to distance vectors
    dist.fit.y = fit(time',dist.y','smoothingspline');
    dist.fit.x = fit(time',dist.x','smoothingspline');
end