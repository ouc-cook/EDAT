function S03_main(DD,rossby,files,lims)
    T = disp_progress('init','filtering contours! takes even much longer!');
    spmd(DD.threads.num)
        for ff = lims(labindex,1):lims(labindex,2)
            T = disp_progress('show',T,diff(lims(labindex,:))+1);
            spmdBlock(DD,files(ff),rossby)
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmdBlock(DD,fileff,rossby)
    [EE,skip] = work_day(DD,fileff,rossby);
    %%
    if skip,disp(['skipping ' EE.filename.eddy ]);   return;end
    %% save
    save_eddies(EE);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [EE,skip] = work_day(DD,file,rossby)
    skip = false;
    EE.filename.cont = file.filenames;
    EE.filename.cut  = strrep(EE.filename.cont,DD.pattern.prefix.conts,DD.pattern.prefix.cuts);
    EE.filename.eddy = strrep(EE.filename.cont,DD.pattern.prefix.conts,DD.pattern.prefix.eddies);
    %% check for exisiting data
    if exist(EE.filename.eddy,'file') && ~DD.overwrite, skip = true; return; end
    %% load data
    cut  = load(EE.filename.cut ); % get ssh data
    cont = load(EE.filename.cont); % get contours
    %% put all eddies into a struct: ee(number of eddies).fields
    contours = eddies2struct(cont.all,DD.thresh.corners);
    %% remember date
    [contours(:).daynum] = deal(file.daynums);
    %% avoid out of bounds integer coor close to boundaries
    [cut.dim.y,cut.dim.x] = size(cut.fields.sshAnom);
    contours = CleanEddies(contours,cut);
    %% find them
    EE = find_eddies(EE,contours,rossby,cut,DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function EE = find_eddies(EE,contours,rossby,cut,DD)
    %% senses
    senN = [-1 1];
    for ii = 1:2
        sen = DD.FieldKeys.senses{ii};
        [EE.(sen),EE.pass.(sen)] = walkThroughContsVertically(contours,rossby,cut,DD,senN(ii));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pass: struct(numberOfContours).logicalsForSuccessOfAllTests
% eddies: struct of contours that qualified ie eddies. all necessary info stored within
function [eddies, pass] = walkThroughContsVertically(contours,rossby,cut,DD,sense)
    %% init
    pp = 0;
    pass = initPass(numel(contours))    ;
    [eddyType,Zloop] = determineSense(DD.FieldKeys.senses,sense,numel(contours));
    %% loop
    for kk = Zloop % direc. dep. on sense. note: ee is sorted vertically
        [pass(kk),eddy_out] = run_eddy_checks(pass(kk),contours(kk),rossby,cut,DD,sense);
        if all(struct2array(pass(kk)))
            pp = pp + 1;
            [eddies(pp),cut] = eddiesFoundOp(eddy_out,DD.map.window,cut);
        end
    end
    %% catch
    if pp == 0
        error('no %s made it through the filters...',eddyType)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% note: this function returns an altered "cut"
function [eddy,cut] = eddiesFoundOp(eddy,window,cut)
    %% flag respective overlap too
    if strcmp(window.type,'globe')
        eddy.mask = flagOverlap(eddy.mask,window);
    end
    %% nan out ssh where eddy was found
    cut.fields.sshAnom(eddy.mask) = nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mask = flagOverlap(mask,window)
    [yi,xi] = find(mask);
    [xi,yi] = wrapDoubles(window,xi,yi);
    mask(drop_2d_to_1d(yi,xi,window.dim.y)) = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% include resp. twin corrdinates
function [xiAlt,yiAlt] = wrapDoubles(window,xi,yi)
    xiAlt = [xi; xi - window.dim.x; xi + window.dim.x];
    yiAlt = repmat(yi,3,1);
    overShoot = xiAlt<1 | xiAlt>window.dimPlus.x;
    xiAlt(overShoot)=[];
    yiAlt(overShoot)=[];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eddyType,Zloop] = determineSense(senseKeys,sense,NumEds)
    switch sense
        case - 1
            eddyType = senseKeys{1}; % anti cyclones
            Zloop = 1:1:NumEds;
        case 1
            eddyType = senseKeys{2}; %  cyclones
            Zloop = NumEds:-1:1;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,ee] = run_eddy_checks(pass,ee,rossby,cut,DD,direction)
    window = DD.map.window;
    
    %% pre-nan-check
    pass.rim = CR_RimNan(ee.coor.int, window.dim.y, cut.fields.sshAnom);
    if ~pass.rim, return, end;
    
    %% closed ring check
    [pass.CR_ClosedRing] = CR_ClosedRing(ee);
    if ~pass.CR_ClosedRing, return, end;
    
    %% pre filter 'thin 1dimensional' eddies (performance)
    pass.CR_2deddy = CR_2deddy(ee.coor.int);
    if ~pass.CR_2deddy, return, end;
    
    %% get sub map around eddy
    [zoom,pass.winlim] = cutMaskOperation(ee.coor,DD.parameters.zoomIncreaseFac,window,cut.fields);
    if ~pass.winlim, return, end;
    
    %% check for nans within eddy
    [pass.CR_Nan] = CR_Nan(zoom);
    if ~pass.CR_Nan, return, end;
    
    %% check for correct sense
    [pass.CR_sense,ee.sense] = CR_sense(zoom,direction,ee.level);
    if ~pass.CR_sense, return, end;
    
    %% calc contour circumference in [SI]
    [ee.circum.si,ee.fourierCont] = eddyCircumference(zoom);
    
    %% calculate area with respect to contour
    [ee.area,pass.Area] = getArea(ee,DD.thresh.maxRadiusOverRossbyL,DD.thresh.minRossbyRadius,rossby);
    if ~pass.Area, return, end;
    
    %% filter eddies not circle-like enough
    [pass.CR_Shape,ee.iq] = CR_Shape(ee,DD.thresh.shape.iq);
    if ~pass.CR_Shape, return, end;
    
    %% get peak position and amplitude w.r.t contour
    [pass.CR_AmpPeak,ee.peak,zoom.ssh_BasePos] = CR_AmpPeak(ee,zoom,DD.thresh.amp);
    if ~pass.CR_AmpPeak, return, end;
    
    %% get profiles
    [ee.profiles] = eddyProfiles(ee,zoom,DD.parameters.fourierOrder);   
    
    %% success! append more stuff
    ee = appendFurtherParameters(ee,zoom,cut,DD,rossby.c);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [ee,zoom] = appendFurtherParameters(ee,zoom,cut,DD,rossbyC)
    
    %% get radius according to max UV ie min vort
    [ee.radius] = eddyRadiusFromUV(ee);
    
    %% get ideal ellipse contour
    zoom.mask.ellipse = eddyEllipse(ee);
    
    %% get effective amplitude relative to ellipse;
    ee.peak.amp.to_ellipse = eddyAmp2Ellipse(ee.peak.z,zoom.fields.sshAnom,zoom.mask.ellipse);
    
    %% append mask to ee in cut coor
    [ee.mask] = sparse(eddyPackMask(zoom.mask.filled,zoom.limits,cut.dim));
    
    %% get center of 'volume'
    [ee.CoV] = CenterOfVolume(zoom.ssh_BasePos,zoom.limits,cut.dim.y);
    
    %% get area centroid
    [ee.CoA] = CenterOfVolume(double(logical(zoom.ssh_BasePos)),zoom.limits,cut.dim.y);
    
    %% get trackref
    ee.trackref = getTrackRef(ee,DD.parameters.trackingRef);
    
    %% get coordinates
    ee.geo = geocoor(zoom, ee.trackref);
    
    %% append 'age'
    ee.age = 0;
    
    %% append projected location
    [ee.projLocsMask] = ProjectedLocations(rossbyC,cut,DD,ee.trackref);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [zoom,pass] = cutMaskOperation(coor,enlargeFac,window,cutFields)
    %% get coor for zoom cut
    [zoom,pass] = get_window_limits(coor,enlargeFac,window);
    %% cut out rectangle encompassing eddy range only for further calcs
    zoom.fields = eddyCut_init( window,cutFields,zoom);
    %% generate logical masks defining eddy interiour and outline
    zoom.mask = eddyCut_mask(zoom);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RoL = getLocalRossyRadius(rossbyL,coor)
    [Y,X] = size(rossbyL);
    x = round(coor.x);
    y = round(coor.y);
    x(x<1) = 1;
    x(x>X) = X;
    y(y<1) = 1;
    y(y>Y) = Y;
    RoL = nanmedian(rossbyL(drop_2d_to_1d(y,x,Y)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,sense] = CR_sense(zoom,direc,level)
    pass = false;
    sense = struct;
    %% water column up: seeking anti cyclones; down: cyclones
    switch direc
        case -1
            sense.str = 'AntiCyclonic'; % TODO
            sense.num = -1;
            if all(zoom.fields.sshAnom(zoom.mask.inside) >= level )
                pass = true;
            end
        case 1
            sense.str = 'Cyclonic';
            sense.num = 1;
            if all(zoom.fields.sshAnom(zoom.mask.inside) <= level )
                pass = true;
            end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check for land/other eddy
function pass = CR_RimNan(coor, Y, ssh)
    pass = true;
    if any(isnan(ssh(drop_2d_to_1d(coor.y, coor.x, Y)))), pass = false; end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,peak,baseHill] = CR_AmpPeak(ee,z,thresh)
    pass = false;
    peak.mean_ssh = mean(z.fields.sshAnom(z.mask.filled));
    %% make current level zero level and zero out everything else
    baseHill = poslin(-ee.sense.num*(z.fields.sshAnom - ee.level));
    baseHill(~z.mask.filled) = 0;
    %% amplitude
    [peak.amp.to_contour,peak.lin] = max(baseHill(:));
    [peak.z.y,peak.z.x] = raise_1d_to_2d(z.dim.y, peak.lin);
    peak.amp.to_mean = z.fields.sshAnom(peak.lin) - peak.mean_ssh;
    %% coor in full map
    peak.y = peak.z.y + z.limits.y(1) - 1;
    peak.x = peak.z.x + z.limits.x(1) - 1;
    %% pass check
    if peak.amp.to_contour >= thresh,	pass = true; 	end
    %% avoid peaks on bndry
    if any([peak.z.y==[1 z.dim.y] peak.z.x==[1 z.dim.x]]), pass = false;end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IQ: isoperimetric quotient
function [pass,IQ] = CR_Shape(ee,thresh)
    getIQ = @(area,circum) 4*pi*area/circum^2;
    %%
    IQ = getIQ(ee.area.intrp,ee.circum.si);
    if IQ >= thresh, pass = true; else pass = false; end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass] = CR_2deddy(coor)
    if (max(coor.x) - min(coor.x)<2) || (max(coor.y) - min(coor.y)<2)
        pass = false;
    else
        pass = true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass] = CR_Nan(z)
    pass = true;
    ssh = z.fields.sshAnom(z.mask.filled);
    %% check for nans or emptiness
    if any(isnan(ssh(:))) || ~any(z.mask.inside(:))
        pass = false;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass] = CR_ClosedRing(ee)
    x = ee.coor.int.x;
    y = ee.coor.int.y;
    pass = true;
    if abs(x(1) - x(end))>1 || abs(y(1) - y(end))>1;
        pass = false;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [mask,trackref] = ProjectedLocations(rossbyU,cut,DD,trackref)
    %% get rossby wave phase speed
    rU = rossbyU(trackref.lin);
    %% get projected distance for one day (rossbySpeedFactor * dt*rU  as in chelton 2011)
    oneDayInSecs = 24*60^2;
    dist.east = DD.parameters.minProjecDist / 7;
    dist.y    = dist.east;
    dist.ro   = abs(rU * oneDayInSecs * DD.parameters.rossbySpeedFactor);
    dist.west = max([dist.ro, dist.east]); % not less than dist.east, see chelton 11
    %% correct for time-step
    for field = fieldnames(dist)'; field = field{1};
        dist.(field) = dist.(field) * DD.time.delta_t; % in days!
    end
    %% get major/minor semi-axes [m]
    ax.maj = (dist.east + dist.west)/2;
    ax.min = dist.y;
    %% get dx/dy at that eddy pos
    dx = DD.map.window.dx(trackref.lin);
    dy = DD.map.window.dy(trackref.lin);
    %% get major/minor semi-axes [increments]
    ax.majinc = ceil(ax.maj/dx);
    ax.mininc = ceil(ax.min/dy);
    %% translate dist to increments
    dist.eastInc = (ceil(dist.east/dx));
    dist.westInc = (ceil(dist.west/dx));
    dist.yInc = (ceil(dist.y/dy));
    %% get positions of params
    xi.f2 = (trackref.x);
    yi.f2 = (trackref.y);
    xi.center = round(xi.f2 - (ax.majinc - dist.eastInc));
    yi.center = round(yi.f2);
    %% build x vector (major axis >= minor axis always!)
    fullcirc = linspace(0,2*pi,4*numel( - dist.westInc:dist.eastInc));
    ellip.x = round(ax.majinc * cos(fullcirc)) + xi.center;
    ellip.y = round(ax.mininc * sin(fullcirc)) + yi.center;
    ellip.lin = unique(drop_2d_to_1d(ellip.y,ellip.x,cut.dim.y));
    %% take care of out of bounds values (only applicable to zonally non continous case. this shouldnt happen in global case)
    ellip.x(ellip.x<1) = 1;
    ellip.x(ellip.x>cut.dim.x) = cut.dim.x;
    ellip.y(ellip.y<1) = 1;
    ellip.y(ellip.y>cut.dim.y) = cut.dim.y;
    xi.center(xi.center<1) = 1;
    xi.center(xi.center>cut.dim.x) = cut.dim.x;
    yi.center(yi.center<1) = 1;
    yi.center(yi.center>cut.dim.y) = cut.dim.y;
    %% build boundary mask
    maskLogical = false(struct2array(cut.dim));
    maskLogical(drop_2d_to_1d(ellip.y,ellip.x,cut.dim.y)) = true;
    maskLogical = sparse(imfill(maskLogical,double([yi.center xi.center]),4));
    %% flag respective overlap too
    if strcmp(DD.map.window.type,'globe')
        maskLogical =flagOverlap(maskLogical, DD.map.window.dim.x );
    end
    %% output
    mask.lin = find(maskLogical);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TR = getTrackRef(ee,tr)
    switch tr
        case 'centroid'
            TR = ee.CoA;
        case 'CenterOfVolume'
            TR = ee.CoV;
        case 'peak'
            TR = ee.peak;
        otherwise
            error('chose tracking reference among centroid, CenterOfVolume or peak!')
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% saving takes long time. therefor save temp file first to avoid corrupt
% files after system crashes
function save_eddies(EE)
    [pathstr, ~, ~] = fileparts(EE.filename.eddy);
    tempn = sprintf('%s%s.mat',pathstr,tempname);
    save(tempn,'-v7','-struct','EE'); % saving takes long time..
    system(['mv ' tempn ' ' EE.filename.eddy]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [area,pass] = getArea(ee,scaleThresh,minLr,rossby)
    %% area
    f = ee.fourierCont;
    x = feval(f.x,f.II) *1000;
    y = feval(f.y,f.II) *1000;
    area.intrp = polyarea(x,y);
    %%
    Lr = getLocalRossyRadius(rossby.Lr,ee.coor.int);
    %% check for threshold
    Lr(Lr<minLr) = minLr;    % correct for min value
    area.RadiusOverRossbyL = sqrt(area.intrp/pi)/Lr;
    pass = true;
    if area.RadiusOverRossbyL > scaleThresh
        pass = false;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[mask_out] = eddyPackMask(mask_in,limits,dims)
    mask_out = false(dims.y,dims.x);
    mask_out(limits.y(1):limits.y(2),limits.x(1):limits.x(2)) = mask_in;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% amplitude from peak to hypothetical ellipse
function [amp] = eddyAmp2Ellipse(peak,sshAnom,elli)
    %% mean amplitude with respect to ellipse contour
    ii = 0:0.1:2*pi;
    sshElli = interp2(sshAnom,elli.x(ii),elli.y(ii));
    amp = abs(sshAnom(peak.y,peak.x) - mean(sshElli));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ellipse] = eddyEllipse(ee)
    %% get center, minor and major axis for ellipse
    xa = ee.radius.coor.xwest;
    xb = ee.radius.coor.xeast;
    ya = ee.radius.coor.ysouth;
    yb = ee.radius.coor.ynorth;
    xm = (mean([xa,xb]));
    ym = (mean([ya,yb]));
    axisX = ((xb - xa))/2;
    axisY = ((yb - ya))/2;
    %% get ellipse coor's
    ellipse.x = @(ang) axisX*cos(ang) + xm;
    ellipse.y = @(ang) axisY*sin(ang) + ym;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [outIdx] = avoidLand(ssh,peak)
    land = reshape(isnan([nan reshape(ssh,1,[]) nan]),1,[]);
    ii = [1 1:numel(ssh) numel(ssh)];
    a = ii(find( ii <= peak & land,1,'last') + 1) ;
    b = ii(find( ii >= peak & land,1,'first') - 1) ;
    outIdx = a:b;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [F] = eddyProfiles(ee,z,fourierOrder)
    F.fit.type  = sprintf('fourier%d',fourierOrder);
    %% detect meridional and zonal profiles shifted to baselevel of current level
    offset_term = ee.peak.amp.to_contour*ee.sense.num - ee.level;
    %%	zonal cut
    cutX = - ee.sense.num*(z.fields.sshAnom(ee.peak.z.y,:) + offset_term);
    [water.x] = avoidLand(cutX,ee.peak.z.x);
    prof.x.sshAnom = (cutX(water.x));
    prof.x.dist = z.fields.km_x(ee.peak.z.y,water.x)*1000 ;
    %% meridional cut
    cutY = - ee.sense.num * (z.fields.sshAnom(:,ee.peak.z.x) + offset_term);
    water.y = avoidLand(cutY,ee.peak.z.y);
    prof.y.sshAnom = (cutY(water.y));
    prof.y.dist = z.fields.km_y(water.y,ee.peak.z.x)*1000 ;
    %%	cranck up resolution
    XY = {'x','y'};
    for ii = 1:2,   xy = XY{ii};
        %% build spline function of profile
        F.spline.(xy)		  = spline(prof.(xy).dist',prof.(xy).sshAnom');
        %% build distance vector from south to north/ west to east starting at 0 [m]
        F.dist.(xy)    = linspace(prof.(xy).dist(1), prof.(xy).dist(end),1000)';
        %% build index vector (with respect to original geometry)
        F.idx.(xy)     = linspace(water.(xy)(1), water.(xy)(end),1000)';
        %% build fourier fit function to splined ssh vector
        sshSpline = ppval(F.spline.(xy), F.dist.(xy));
        F.fit.(xy).sshAnom = fit(F.dist.(xy),sshSpline ,F.fit.type);
    end
    %% howto
    F.readme.buildSplineSsh = 'ppval(F.spline.x, F.dist.x)';
    F.readme.buildFitSsh = 'feval(F.fit.x.sshAnom, F.spline.x.dist)';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [radius] = eddyRadiusFromUV(ee)
    %% find indeces in fit vector of zero crossings of second diff to ssh around peak
    [x] = findSigmaIdx(ee.peak.z,ee.profiles,'x');
    [y] = findSigmaIdx(ee.peak.z,ee.profiles,'y');
    %% calc radius
    radius.zonal = diff(x.dis([x.sigmaIdx - .5]))/2;
    radius.meridional = diff(y.dis([y.sigmaIdx - .5]))/2;
    radius.mean = mean([radius.zonal;radius.meridional]);
    %% coor's on original grid
    radius.coor.xwest  =  interp1(x.idx,x.sigmaIdx(1));
    radius.coor.xeast  =  interp1(x.idx,x.sigmaIdx(2));
    radius.coor.ysouth =  interp1(y.idx,y.sigmaIdx(1));
    radius.coor.ynorth =  interp1(y.idx,y.sigmaIdx(2));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% note that all profiles are 'high pressure' regardless of sense or
% hemisphere here
function [P] = findSigmaIdx(peak,prof,yx)
    %% functions to make out changes in sign in vectors
    signJump.east = @(X) logical(diff(sign(X([1:end end]))));
    signJump.west = @(X) logical(diff(sign(X([1   1:end]))));
    %% get data
    FsshAnom = prof.fit.(yx).sshAnom;   % cfit function
    P.dis = prof.dist.(yx);             % distance [m]
    P.idx = prof.idx.(yx);              % index starting at 1
    intrpLen = length(P.idx);         % eg 1000
    P.sshAnom = feval(FsshAnom, P.dis);  % ssh
    %%
    [P.UV,P.dUV]  = differentiate(FsshAnom,P.dis);   %first and second differential to sshAnom
    P.UV  = P.UV  * 1e8;  % magnify (value irrelevant here)
    P.dUV = P.dUV *1e13;
    %% find best pos in long index vector for peak
    [~,P.peakLow] = min(abs(P.idx - double(peak.(yx)))); % index of peak in high res coors determined directly from low res
    %% better guess for index of peak directly from change in sign of ssh_x in smooth fitted data
    idxL = (1:intrpLen)';
    switch sign(P.UV(P.peakLow))
        case  1 % slightly right of peak
            P.peakHigh = find(signJump.east(P.UV) &  idxL >= P.peakLow ,1,'first');
        case -1 % slightly left of peak
            P.peakHigh = find(signJump.west(P.UV) &  idxL <= P.peakLow ,1,'last' );
    end
    %% either left bndry or idx left of peak where dVdx crosses x-axis and slope of SSH is uphill
    F.a = P.idx < peak.(yx);
    F.b = signJump.west(P.dUV);
    F.c = P.UV > 0;
    P.sigmaIdx(1) = max([ 1  find(F.a & F.b & F.c, 1, 'last') ]) + .5;
    %% respectively for downhill side
    F.a = P.idx > peak.(yx);
    F.b = signJump.east(P.dUV); % right side of idx
    F.c = P.UV < 0;
    P.sigmaIdx(2) = min([ numel(P.idx) find(F.a & F.b & F.c, 1, 'first')]) - .5;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [geo] = geocoor(zoom,trackref)
    geo.lat = interp2(zoom.fields.lat,trackref.xz,trackref.yz);
    if zoom.fields.lon(1,1) > zoom.fields.lon(1,end)
        zoom.fields.lon = wrapTo180(zoom.fields.lon);
        geo.lon = wrapTo360(interp2(zoom.fields.lon,trackref.xz,trackref.yz));
    else
        geo.lon = interp2(zoom.fields.lon,trackref.xz,trackref.yz);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CoV] = CenterOfVolume(ssh,limits,Y)
    %% get center of volume  formula:   COVs = \frac{1}{M} \sum_{i = 1}^n m_i \vec{x}_i,
    [XI,YI] = meshgrid(1:size(ssh,2), 1:size(ssh,1));
    y = sum(nansum(ssh.*YI));
    x = sum(nansum(ssh.*XI));
    yz = (y/nansum(ssh(:)));
    xz = (x/nansum(ssh(:)));
    y = yz + double(limits.y(1)) - 1;
    x = xz + double(limits.x(1)) - 1;
    CoV.xz = xz; % in zoom
    CoV.yz = yz;
    CoV.x = x; % in original geom
    CoV.y = y;
    CoV.lin = drop_2d_to_1d(y,x,Y);
    CoV.linz = drop_2d_to_1d(yz,xz,size(ssh,1));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [circum,f] = contourLengthIntrp(fopt,x,y)
    f.ii = linspace(0,2*pi,numel(x))';
    f.II = linspace(0,2*pi,360)';
    %% spline eddy boundary to 360 pieces to guess circumference
    f.x = fit(f.ii,x,'smoothingspline',fopt);
    f.y = fit(f.ii,y,'smoothingspline',fopt);
    circum = sum(hypot(diff(feval(f.x,f.II)),diff(feval(f.y,f.II)))) * 1000; % [m]
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [circum,f] = eddyCircumference(z)
    load fopt fopt
    ilin = z.coor.int.lin;
    x = z.fields.km_x(ilin);
    y = z.fields.km_y(ilin);
    [circum,f] = contourLengthIntrp(fopt,x,y);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mask = eddyCut_mask(zoom)
    %% init
    dummymask = false(size(zoom.fields.sshAnom));
    [queryY,queryX] = find(~dummymask);
    queryLin = drop_2d_to_1d(queryY,queryX,size(dummymask,1));
    rimIntLin = drop_2d_to_1d(zoom.coor.int.y,zoom.coor.int.x,size(dummymask,1));
    %% inside
    querypoints = [queryX,queryY];
    node = struct2array(zoom.coor.exact);
    
    insideLin = queryLin(inpoly(querypoints,node)); % MAIN BOTTLENECK!!!!!
    
    mask.inside = dummymask;
    mask.inside(insideLin) = true;
    %% on rim
    mask.rim_only = dummymask;
    mask.rim_only(rimIntLin) = true;
    %% full (with rim)
    mask.filled = mask.rim_only | mask.inside;
    %% dims
    [mask.dim.y, mask.dim.x] = size(dummymask);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fields_out = eddyCut_init(win,ssh,z)
    ya = z.limits.y(1);
    yb = z.limits.y(2);
    xa = z.limits.x(1);
    xb = z.limits.x(2);
    %% cut all fields
    cutfield=@(X) X(ya:yb,xa:xb);
    fields_out.lat = cutfield(win.lat);
    fields_out.lon = cutfield(win.lon);
    fields_out.dx  = cutfield(win.dx);
    fields_out.dy  = cutfield(win.dy);
    fields_out.sshAnom = cutfield(ssh.sshAnom);
    %% distances (dont change to cumsum(DX). doesnt work for -180<->180 cases)
    temp = cumsum(mod(diff(fields_out.lon(:,[[1 1:end]]),1,2),360),2);
    fields_out.km_x = deg2km(temp .* cosd(fields_out.lat));
    %%
    fields_out.km_y = deg2km(cumsum(diff(fields_out.lat([1 1:end],:),1,1),1));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [z,pass] = get_window_limits(coor,enlargeFac,map)
    pass = true(2,1);
    z.coor = coor;
    %% output
    z.limits.x(1) = min(coor.int.x);
    z.limits.y(1) = min(coor.int.y);
    z.limits.x(2) = max(coor.int.x);
    z.limits.y(2) = max(coor.int.y);
    %% enlarge window for cases in which contour represents only part of eddy
    [z.limits,z.M] = enlarge_window(z.limits,enlargeFac,map.dimPlus) ;
    %%
    z.dim.x = diff(z.limits.x) + 1;
    z.dim.y = diff(z.limits.y) + 1;
    z.coor.int.x = z.coor.int.x - z.limits.x(1) + 1;
    z.coor.int.y = z.coor.int.y - z.limits.y(1) + 1;
    z.coor.int.lin = drop_2d_to_1d(z.coor.int.y,z.coor.int.x,z.dim.y)	;
    z.coor.exact.x = z.coor.exact.x - double(z.limits.x(1)) + 1;
    z.coor.exact.y = z.coor.exact.y - double(z.limits.y(1)) + 1;
    %%
    if strcmp(map.type,'globe')
        %% in global case dismiss eddies touching zonal boundaries (another copy of these eddies exists that is not touching boundaries, due to the zonal appendage in S00b
        pass(1) = z.limits.x(1) ~= 1;
        pass(2) = z.limits.x(2) ~= map.dimPlus.x;
    end
    %%
    pass = all(pass);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [inout,M] = enlarge_window(inout,factor,dim)
    half_width = round((diff(inout.x) + 1)*(factor - 1)/2);
    half_height = round((diff(inout.y) + 1)*(factor - 1)/2);
    inout.x(1) = max([1 inout.x(1) - half_width]);
    inout.x(2) = min([dim.x inout.x(2) + half_width]);
    inout.y(1) = max([1 inout.y(1) - half_height]);
    inout.y(2) = min([dim.y inout.y(2) + half_height]);
    [M.x,M.y] = meshgrid(inout.x(1):inout.x(end),inout.y(1):inout.y(end));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eds] = eddies2struct(conts,thresh)
    if nargin<2
        thresh.min = 1;
        thresh.max = inf;
    end
    eds = struct;
    ii = 1;cc = 0;
    while ii<size(conts,1);
        len = conts(ii,2);% contourc saves the length of each contour before appending the next
        if len >= thresh.min && len <= thresh.max
            cc = cc + 1;
            eds(cc).level = conts(ii,1);
            eds(cc).circum.length = len;
            eds(cc).coor.exact.x = conts(1 + ii:ii + eds(cc).circum.length,1);
            eds(cc).coor.exact.y = conts(1 + ii:ii + eds(cc).circum.length,2);
            eds(cc).coor.int.x = int32(eds(cc).coor.exact.x);
            eds(cc).coor.int.y = int32(eds(cc).coor.exact.y);
        end
        ii = ii + len + 1; % jump to next eddy for next iteration
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ee] = CleanEddies(ee,cut)
    for jj = 1:numel(ee)
        x = ee(jj).coor.int.x;
        y = ee(jj).coor.int.y;
        %%
        x(x>cut.dim.x) = cut.dim.x;
        y(y>cut.dim.y) = cut.dim.y;
        x(x<1) = 1;
        y(y<1) = 1;
        %%
        ee(jj).coor.int.x = x;
        ee(jj).coor.int.y = y;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  pass = initPass(len)
    pass(len).rim = 0;
    pass(len).CR_ClosedRing = 0;
    pass(len).CR_2deddy = 0;
    pass(len).winlim = 0;
    pass(len).CR_Nan = 0;
    pass(len).CR_sense = 0;
    pass(len).Area = 0;
    pass(len).CR_Shape = 0;
    pass(len).CR_AmpPeak = 0;
    pass(len).CR_radius = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end