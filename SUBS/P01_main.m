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
    try
        track = load(trackFile);
%         if isfield(track,'analyzed')
%             return
%         end
        track.analyzed = alterTrack(track.track);
        updateTrack(track,trackFile);
    catch
        system(sprintf('mv %s %sCORRUPT',trackFile,trackFile))
    end
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
    if diff(abs(analy.dist.lon))>300
        figure(4) % TODO
        hold on
        geo.lon = wrapTo360(spline(analy.time,wrapTo180(analy.dist.lon),analy.daily.time'));
        plot(geo.lon)
    else
        geo.lon = spline(analy.time,analy.dist.lon,analy.daily.time');
    end
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
    dist.y = deg2km(zeroShift(dist.lat)                             );
    dist.x = deg2km(zeroShift(wrapTo360(dist.lon)).* cosd(dist.lat) );
    time = extractdeepfield(track,'daynum');
    %% build spline cfit to distance vectors
    dist.fit.y = fit(time',dist.y','smoothingspline');
    dist.fit.x = fit(time',dist.x','smoothingspline');
end