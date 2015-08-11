%  --- Post-processing step 1 ---
% 
%  -(I) load track file
%  -(II) analyze track
% 	 -(a) build distance-from-birth-place (x,y)-vectors ([km]) at daily resolution, by interpolating the geo coordinates (smoothingspline).
% 	 -(b) build velocity-vectors by differentiating the vectors from (b).
% 	 -(c) also interpolate daily lat/lon vectors.
% 	 -(d) also interpolate daily scale (hori.) vectors.
% 	 -(e) extract geo-info for birth and death places.
% 	 -(f) also interpolate daily amplitude vectors.
%  -(III) save analyzed track to "ANALYZED"
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
    catch
        system(sprintf('mv %s %sCORRUPT',trackFile,trackFile))
        return
    end
    analyzed = analyzeTrack(track.track,trackFile);
    updateTrack(analyzed,trackFile);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function updateTrack(analyzed,trackFile) %#ok<INUSL>
    anaFile =  strrep(strrep(trackFile,'TRACKS','ANALYZED'),'TRACK','ANA');
    if exist(anaFile,'file')
        save(anaFile,'-struct','analyzed','-append');
    else
        save(anaFile,'-struct','analyzed');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function analy = analyzeTrack(track,trackFile)
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
    analy.origFile                      = trackFile;
    %%
    analy.amp                           = amplitudeStuff(track);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function amp = amplitudeStuff(track)
    amp = extractdeepfield(track,'peak.amp.to_ellipse');
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
    if any(abs(diff(analy.dist.lon))>300)
        geo.lon = wrapTo360(spline(analy.time,wrapTo180(analy.dist.lon),analy.daily.time'));
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
    lo = dist.lon;
    %% get distance-from-birth components
    if any(abs(diff(lo))>300)
        lo = wrapTo180(lo);
    end
    dist.x = deg2km(zeroShift(lo)).* cosd(dist.lat);
    dist.y = deg2km(zeroShift(dist.lat));
    %% time
    time = extractdeepfield(track,'daynum');
    %% build spline cfit to distance vectors
    dist.fit.y = fit(time',dist.y','smoothingspline');
    dist.fit.x = fit(time',dist.x','smoothingspline');
end