%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04 - Apr - 2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% walks through all the contours and decides whether they qualify
function S04_filter_eddies
    %% init
    
    DD = initialise('conts',mfilename);
    DD.map.window = getfieldload(DD.path.windowFile,'window');
    
    % TODO
    fopt = fitoptions('Method','Smooth','SmoothingParam',0.99);
    save fopt fopt
    
    
    rossby = getRossbyPhaseSpeedAndRadius(DD);
    %% spmd
    main(DD,rossby);
    %% update infofile
    %     conclude(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,rossby)
    if DD.debugmode
        spmd_body(DD,rossby)
    else
        spmd(DD.threads.num)
            spmd_body(DD,rossby)
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(DD,rossby)
    [JJ] = SetThreadVar(DD);
    Td = disp_progress('init','filtering contours');
    for jj = 1:numel(JJ)
        Td = disp_progress('disp',Td,numel(JJ));
        %%
        [EE,skip] = work_day(DD,JJ(jj),rossby);
        %%
        if skip,disp(['skipping ' EE.filename.self ]);   continue;end
        %% save
        save_eddies(EE);
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [EE,skip] = work_day(DD,JJ,rossby)
    %% check for exisiting data
    skip = false;
    EE.filename.cont = JJ.files;
    EE.filename.cut = [DD.path.cuts.name, DD.pattern.prefix.cuts, JJ.protos];
    EE.filename.self = [DD.path.eddies.name, DD.pattern.prefix.eddies ,JJ.protos];
    if exist(EE.filename.self,'file') && ~DD.overwrite, skip = true; return; end
    %% load data
    try % TODO
        cut = load(EE.filename.cut);   % get ssh data
        cont = load(EE.filename.cont); % get contours
    catch failed
        skip = catchCase(failed,EE.filename.cont);
        return;
    end
    
    if numel(cont.all)==0
        
        return % TODO
    end
    
    %% put all eddies into a struct: ee(number of eddies).characteristica
    ee = eddies2struct(cont.all,DD.thresh.corners);
    %% remember date
    [ee(:).daynum] = deal(JJ.daynums);
    %% avoid out of bounds integer coor close to boundaries
    [cut.dim.y,cut.dim.x] = size(cut.fields.ssh);
    [ee_clean] = CleanEddies(ee,cut);
    %% find them
    EE = find_eddies(EE,ee_clean,rossby,cut,DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function skip = catchCase(failed,fname)
    fprintf('cannot read %s! \n',fname)
    %     system(['rm ' fname])
    disp(failed.message);
    save(sprintf('S04fail - %s.mat',datestr(now,'mmddHHMM')));
    skip = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function EE = find_eddies(EE,ee,rossby,cut,DD)
    %% senses
    senN = [-1 1];
    for ii = 1:2
        sen = DD.FieldKeys.senses{ii};
        [EE.(sen),EE.pass.(sen)] = walkThroughContsVertically(ee,rossby,cut,DD,senN(ii));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eddies, pass] = walkThroughContsVertically(ee,rossby,cut,DD,sense)
    pp = 0;
    pass = initPass(numel(ee))    ;
    %% init
    [eddyType,Zloop] = determineSense(DD.FieldKeys.senses,sense,numel(ee));
    %% loop
    %     Tv = disp_progress('init','running through contours vertically');
    for kk = Zloop % dir dep. on sense. note: ee is sorted vertically
        %         Tv = disp_progress('disp',Tv,numel(Zloop),3);
        [pass(kk),ee_out] = run_eddy_checks(pass(kk),ee(kk),rossby,cut,DD,sense);
        if all(struct2array(pass(kk))), pp = pp + 1;
            [eddies(pp),cut]=eddiesFoundOp(ee_out,DD.map,cut);
        end
    end
    %% catch
    if pp == 0
        error('no %s made it through the filter...',eddyType)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eddy,cut]=eddiesFoundOp(eddy,map,cut)
    %% flag respective overlap too
    if strcmp(map.window.type,'globe')
        eddy.mask = flagOvrlp(eddy.mask,map.window.dim.x);
    end
    %% nan out ssh where eddy was found
    cut.fields.ssh(eddy.mask) = nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mask = flagOvrlp(mask,X)
    [Y,~]=size(mask);
    [yi,xi] = find(mask);
    [xi,yi] = wrapDoubles(X,xi,yi);
    mask(drop_2d_to_1d(yi,xi,Y)) = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xiAlt,yiAlt] = wrapDoubles(X,xi,yi)
    xiAlt = [xi; xi - X; xi + X];
    yiAlt = repmat(yi,3,1);
    overShoot = xiAlt<1 | xiAlt>X;
    xiAlt(overShoot)=[];
    yiAlt(overShoot)=[];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [eddyType,Zloop] = determineSense(senseKeys,sense,NumEds)
    switch sense
        case - 1
            eddyType = senseKeys{1}; % anti cycs
            Zloop = 1:NumEds;
        case 1
            eddyType = senseKeys{2}; %  cycs
            Zloop = NumEds: - 1:1;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,ee] = run_eddy_checks(pass,ee,rossby,cut,DD,direction)
    MAP = DD.map.window;
    %% pre-nan-check
    pass.rim = CR_RimNan(ee.coor.int, MAP.dim.y, cut.fields.ssh);
    if ~pass.rim, return, end;
    %% closed ring check
    [pass.CR_ClosedRing] = CR_ClosedRing(ee);
    if ~pass.CR_ClosedRing, return, end;
    %% pre filter 'thin 1dimensional' eddies
    pass.CR_2dEDDy = CR_2dEDDy(ee.coor.int);
    if ~pass.CR_2dEDDy, return, end;
    %% get coor for zoom cut
    
    winincrease=6;  % TODO
    
    [zoom,pass.winlim] = get_window_limits(ee.coor,winincrease,MAP);
    if ~pass.winlim, return, end;
    %% cut out rectangle encompassing eddy range only for further calcs
    zoom.fields = EDDyCut_init(MAP,cut.fields,zoom);
    %% generate logical masks defining eddy interiour and outline
    zoom.mask = EDDyCut_mask(zoom);
    %% check for nans matlab.matwithin eddy
    [pass.CR_Nan] = CR_Nan(zoom);
    if ~pass.CR_Nan, return, end;
    if ~any(zoom.mask.inside),pass.CR_Nan = false; return; end
    %% check for correct sense
    [pass.CR_sense,ee.sense] = CR_sense(zoom,direction,ee.level);
    if ~pass.CR_sense, return, end;
    
    
    %% calc contour circumference in [SI]
    [ee.circum.si,ee.fourierCont] = EDDyCircumference(zoom);
    
    %% calculate area with respect to contour
    RoL = getLocalRossyRadius(rossby.Lr,ee.coor.int);
    [ee.area,pass.Area] = Area(ee,zoom,RoL,DD.thresh.maxRadiusOverRossbyL,DD.thresh.minRossbyRadius);
    if ~pass.Area && DD.switchs.maxRadiusOverRossbyL, return, end;
    
    %% filter eddies not circle - like enough
    [pass.CR_Shape,ee.iq, ee.cheltshape] = CR_Shape(zoom,ee,DD.thresh.shape,DD.switchs);
    if ~pass.CR_Shape, return, end;
    %% get peak position and amplitude w.r.t contour
    [pass.CR_AmpPeak,ee.peak,zoom.ssh_BasePos] = CR_AmpPeak(ee,zoom,DD.thresh.amp);
    if ~pass.CR_AmpPeak, return, end;
    %% CHELT OP
    
    ee.chelt = cheltStuff(ee,zoom);
    
    %% get profiles
    [ee.profiles,pass.CR_radius,f] = EDDyProfiles(ee,zoom,DD.parameters.fourierOrder); %#ok<ASGLU>
    if ~pass.CR_radius, return, end;
    %% get radius according to max UV ie min vort
    [ee.radius,pass.CR_radius] = EDDyRadiusFromUV(ee.peak.z, ee.profiles,DD.thresh.radius);
    if ~pass.CR_radius, return, end;
    %% get ideal ellipse contour
    zoom.mask.ellipse = EDDyEllipse(ee,zoom.mask);
    %% get effective amplitude relative to ellipse;
    ee.peak.amp.to_ellipse = EDDyAmp2Ellipse(ee,zoom);
    %% append mask to ee in cut coor
    [ee.mask] = sparse(EDDyPackMask(zoom.mask.filled,zoom.limits,cut.dim));
    %% get center of 'volume'
    [ee.volume] = CenterOfVolume(zoom,ee.area.total,cut.dim.y);
    %% get area centroid (chelton style)
    [ee.centroid] = AreaCentroid(zoom,cut.dim.y);
    %% get coor
    [ee.geo] = geocoor(zoom,ee.volume);
    %% append 'age'
    ee.age = 0;
    %% get trackref
    ee.trackref = getTrackRef(ee,DD.parameters.trackingRef);
    %% append projected location
    if (DD.switchs.distlimit && DD.switchs.RossbyStuff)
        [ee.projLocsMask] = ProjectedLocations(rossby.c,cut,DD,ee.trackref);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [ch]=cheltStuff(ee,zoom)
    load fopt
    ch.amp = ee.peak.amp.to_contour;
    ch.efoldAmp =   ch.amp*exp(-1);   % hmax - (1 - e-1)A = h+ A/e  | ch2011 p208
    C = contourc(zoom.ssh_BasePos,[ ch.efoldAmp  ch.efoldAmp])   ;
    [ch.ee] = CleanEddies(eddies2struct(C'),zoom);
    %% collect new indices
    xi = extractdeepfield(ch.ee,'coor.int.x');
    yi = extractdeepfield(ch.ee,'coor.int.y');
    ilin = drop_2d_to_1d(yi,xi,zoom.dim.y);
    %% in km
    x = zoom.fields.km_x(ilin) ;
    y = zoom.fields.km_y(ilin) ;
    %% get interped function
    r = @(x) reshape(x,[],1); % need vertical vector
    [~,f] = contourLengthIntrp(fopt,r(x),r(y));
    %% intrped and in m
    x =  feval(f.x,f.II) *1000;
    y =  feval(f.y,f.II) *1000;
    %% L's accord. to chelton
    ch.area.Le   = polyarea(x,y);
    ch.area.L    = ch.area.Le/sqrt(2);
    ch.area.Leff = ee.area.intrp;
    
    %
    %     s The right panel shows meridional proﬁles of the
    % average (solid line) and the interquartile range of the distribution of Ls (gray shading) in 1° latitude bins. The long dashed line is the meridional proﬁle of the average of the e-
    % folding scale Le of a Gaussian approximation of each eddy (see Appendix B.3). The short dashed line represents the 0.4° feature resolution limitation of the SSH ﬁelds of the
    % AVISO Reference Series for the zonal direction (see Appendix A.3) and the dotted line is the meridional proﬁle of the average Rossby radius of deformation from Chelton et al.
    % (1998).
    
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
            if all(zoom.fields.ssh(zoom.mask.inside) >= level )
                pass = true;
            end
        case 1
            sense.str = 'Cyclonic';
            sense.num = 1;
            if all(zoom.fields.ssh(zoom.mask.inside) <= level )
                pass = true;
            end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function pass = CR_RimNan(coor, Y, ssh)
    pass = true;
    if any(isnan(ssh(drop_2d_to_1d(coor.y, coor.x, Y)))), pass = false; end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,peak,base] = CR_AmpPeak(ee,z,thresh)
    pass = false;
    peak.mean_ssh = mean(z.fields.ssh(z.mask.filled));
    %% make current level zero level and zero out everything else
    base = poslin( - ee.sense.num*(z.fields.ssh - ee.level));  % TODO, make more exact
    base(~z.mask.filled) = 0;
    %% amplitude
    [peak.amp.to_contour,peak.lin] = max(base(:));
    [peak.z.y,peak.z.x] = raise_1d_to_2d(z.dim.y, peak.lin);
    peak.amp.to_mean = z.fields.ssh(peak.lin) - peak.mean_ssh;
    %% coor in full map
    peak.y = peak.z.y + z.limits.y(1) - 1;
    peak.x = peak.z.x + z.limits.x(1) - 1;
    %% pass check
    if peak.amp.to_contour >= thresh,	pass = true; 	end
    %% avoid peaks on bndry
    if any([peak.z.y==[1 z.dim.y] peak.z.x==[1 z.dim.x]]), pass = false;end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,IQ,chelt] = CR_Shape(z,ee,thresh,switchs)
    [passes.iq,IQ] = IsopQuo(ee,thresh.iq);
    [passes.chelt,chelt] = chelton_shape(z,ee);
    if switchs.IQ && ~switchs.chelt
        pass = passes.iq;
    elseif switchs.chelt && ~switchs.IQ
        pass = passes.chelt;
    elseif switchs.chelt && switchs.IQ
        pass = passes.chelt && passes.iq;
    else
        error('choose at least one shape method (IQ or chelton method in input_vars switchs section)') %#ok<*ERTAG>
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,chelt] = chelton_shape(z,ee)
    %% get max dist(all2all)
    f = ee.fourierCont;
    x = f.x(f.ii);
    y = f.y(f.ii);
    xiy = x + 1i*y;
    [A,B] = meshgrid(xiy,xiy);
    maxDist = max(max(abs(A - B)))*1000;
    %% mean latitude of eddy
    medlat = abs(nanmean(reshape(z.mask.rim_only.*z.fields.lat,1,[]))) ;
    %%
    if medlat> 25
        chelt = 1 - maxDist/4e5;
    else
        chelt = 1 - maxDist/(8e5*(25 - medlat)/25 + 4e5); % equiv. 1200km @ equator
    end
    if chelt >= 0, pass = true; else pass = false; end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass,iq] = IsopQuo(ee,thresh)
    %% isoperimetric quotient
    getIQ = @(area,circum) 4*pi*area/circum^2;
    iq = getIQ(ee.area.intrp,ee.circum.si);
    %%
    if iq >= thresh, pass = true; else pass = false; end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass] = CR_2dEDDy(coor)
    if (max(coor.x) - min(coor.x)<2) || (max(coor.y) - min(coor.y)<2)
        pass = false;
    else
        pass = true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass] = CR_Nan(z)
    ssh = z.fields.ssh(z.mask.filled);
    if ~any(isnan(ssh(:))), pass = true; else pass = false; end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pass] = CR_ClosedRing(ee)
    x = ee.coor.int.x;
    y = ee.coor.int.y;
    if abs(x(1) - x(end))>1 || abs(y(1) - y(end))>1;
        pass = false;
    else
        pass = true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% others
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RS = getRossbyPhaseSpeedAndRadius(DD)
    if DD.switchs.RossbyStuff
        RS.Lr = getfield(load([DD.path.Rossby.name 'RossbyRadius.mat']),'data');
        RS.c  = getfield(load([DD.path.Rossby.name 'RossbyPhaseSpeed.mat']),'data');
        % TODO docu:
        RS.c(abs(RS.c) > DD.thresh.phase) = sign(RS.c(abs(RS.c) > DD.thresh.phase)) * abs(DD.thresh.phase);
    else
        warning('No Rossby Radius available. Ignoring upper constraint on eddy scale!') %#ok<*WNTAG>
        RS.c  = [];
        RS.Lr = [];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [centroid] = AreaCentroid(zoom,Y)
    %% factor each grid cell equally (compare to CenterOfVolume())
    ssh = double(logical(zoom.ssh_BasePos));
    %% get centroid:   COVs = \frac{1}{A} \sum_{i = 1}^n 1 \vec{x}_i,
    [XI,YI] = meshgrid(1:size(ssh,2), 1:size(ssh,1));
    y = sum(nansum(ssh.*YI));
    x = sum(nansum(ssh.*XI));
    yz = (y/nansum(ssh(:)));
    xz = (x/nansum(ssh(:)));
    y = yz + double(zoom.limits.y(1)) - 1;
    x = xz + double(zoom.limits.x(1)) - 1;
    centroid.xz = xz;
    centroid.yz = yz;
    centroid.x = x;
    centroid.y = y;
    centroid.lin = drop_2d_to_1d(y,x,Y);
    centroid.linz = drop_2d_to_1d(yz,xz,size(ssh,1));
end
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
    %% get major/minor semi - axes [m]
    ax.maj = (dist.east + dist.west)/2;
    ax.min = dist.y;
    %% get dx/dy at that eddy pos
    dx = DD.map.window.dx(trackref.lin);
    dy = DD.map.window.dy(trackref.lin);
    %% get major/minor semi - axes [increments]
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
    mask.logical = false(struct2array(cut.dim));
    mask.logical(drop_2d_to_1d(ellip.y,ellip.x,cut.dim.y)) = true;
    mask.logical = sparse(imfill(mask.logical,double([yi.center xi.center]),4));
    %% flag respective overlap too
    if strcmp(DD.map.window.type,'globe')
        mask.logical =flagOvrlp(mask.logical, DD.map.window.dim.x );
    end
    mask.lin = find(mask.logical);
    mask  =  rmfield(mask,'logical'); % redundant
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TR = getTrackRef(ee,tr)
    switch tr
        case 'centroid'
            TR = ee.centroid;
        case 'CenterOfVolume'
            TR = ee.volume.center;
        case 'peak'
            TR = ee.peak;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_eddies(EE)
    [pathstr, ~, ~] = fileparts(EE.filename.self);
    
    tempname = sprintf('%s/temp-labid-%02d_eddie.mat',pathstr,labindex);
    
    save(tempname,'-v7','-struct','EE');
    system(['mv ' tempname ' ' EE.filename.self]);
    %save(EE.filename.self,'-struct','EE')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [area,pass] = Area(ee,z,rossbyL,scaleThresh,minLr)
    %% TODO reundant
    area = struct;
    area.pixels = (z.fields.dx.*z.fields.dy).*(z.mask.inside + z.mask.rim_only/2);  % include 'half of rim'
    area.total = sum(area.pixels(:));
    
    %% better
    f = ee.fourierCont;
    x =  feval(f.x,f.II) *1000;
    y =  feval(f.y,f.II) *1000;
    area.intrp = polyarea(x,y);
    
    %%
    rossbyL(rossbyL<minLr) = minLr;    % correct for min value
    area.RadiusOverRossbyL = sqrt(area.intrp/pi)/rossbyL;
    if area.RadiusOverRossbyL > scaleThresh
        pass = false;
    else
        pass = true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function	[mask_out] = EDDyPackMask(mask_in,limits,dims)
    mask_out = false(dims.y,dims.x);
    mask_out(limits.y(1):limits.y(2),limits.x(1):limits.x(2)) = mask_in;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [amp] = EDDyAmp2Ellipse(ee,zoom)
    %% mean amplitude with respect to ellipse contour
    halfstep = @(data,y,x,dy,dx) mean([data(y,x) data(y + dy*2,x + dx*2)]);
    xa = double(ee.radius.coor.xwest);
    xb = double(ee.radius.coor.xeast);
    ya = double(ee.radius.coor.ysouth);
    yb = double(ee.radius.coor.ynorth);
    cx = double(ee.peak.z.x);
    cy = double(ee.peak.z.y);
    clear ssh
    ssh.west = halfstep(zoom.fields.ssh,cy,xa,0,.5);
    ssh.east = halfstep(zoom.fields.ssh,cy,xb,0, - .5);
    ssh.south = halfstep(zoom.fields.ssh,ya,cx,.5,0);
    ssh.north = halfstep(zoom.fields.ssh,yb,cx, - .5,0);
    ssh.mean = mean(struct2array(ssh));
    amp = abs(zoom.fields.ssh(ee.peak.z.y,ee.peak.z.x) - ssh.mean);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ellipse] = EDDyEllipse(ee,mask)
    %% get center, minor and major axis for ellipse
    xa = ee.radius.coor.xwest;
    xb = ee.radius.coor.xeast;
    ya = ee.radius.coor.ysouth;
    yb = ee.radius.coor.ynorth;
    xm = (mean([xa,xb]));
    ym = (mean([ya,yb]));
    axisX = (double(xb - xa))/2;
    axisY = (double(yb - ya))/2;
    %% init ellipse mask
    ellipse = false(mask.dim.y,mask.dim.x);
    %% get ellipse coor
    linsdeg = (linspace(0,2*pi,2*sum(struct2array(mask.dim))));
    ellipseX = round(axisX*cos(linsdeg) + xm);
    ellipseY = round(axisY*sin(linsdeg) + ym);
    ellipseX(ellipseX>mask.dim.x) = mask.dim.x;
    ellipseY(ellipseY>mask.dim.y) = mask.dim.y;
    ellipseX(ellipseX<1) = 1;
    ellipseY(ellipseY<1) = 1;
    xlin = unique(drop_2d_to_1d(ellipseY,ellipseX,mask.dim.y));
    %% draw into mask
    ellipse(xlin) = true;
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
function [s,pass,f] = EDDyProfiles(ee,z,fourierOrder)
    %% detect meridional and zonal profiles shifted to baselevel of current level
    offset_term = ee.peak.amp.to_contour*ee.sense.num - ee.level;
    %%	zonal cut
    ssh = - ee.sense.num*(z.fields.ssh(ee.peak.z.y,:) + offset_term);
    [water.x] = avoidLand(ssh,ee.peak.z.x);
    prof.x.ssh = (ssh(water.x));
    prof.x.ddis = z.fields.dx(ee.peak.z.y,water.x) ;
    prof.x.dist = z.fields.km_x(ee.peak.z.y,water.x)*1000 ;  % TODO make all SI in the first place
    %% meridional cut
    ssh = - ee.sense.num * (z.fields.ssh(:,ee.peak.z.x) + offset_term);
    water.y = avoidLand(ssh,ee.peak.z.y);
    prof.y.ssh = (ssh(water.y));
    prof.y.ddis = z.fields.dy(water.y,ee.peak.z.x) ;
    prof.y.dist = z.fields.km_y(water.y,ee.peak.z.x)*1000 ;
    %
    %%	cranck up res
    pass = true;
    try
        for xyc = {'x','y'};xy = xyc{1};
            s.(xy).dist = linspace(prof.(xy).dist(1), prof.(xy).dist(end),100)';
            s.(xy).idx = linspace(water.(xy)(1), water.(xy)(end),100)';
            f.(xy)		 = spline(prof.(xy).dist',prof.(xy).ssh');
            s.(xy).ssh = (ppval(f.(xy), s.(xy).dist));
        end
    catch me %#ok<NASGU>
        %         disp(me.message) % non unique data site.. probably at weird land situations TODO!!
        pass = false;
        s = [];f = [];
        return
    end
    %% intrp versions
    fs = @(diflevel,arg,val) diffCentered(diflevel,arg,val)';
    f.fit.type  = sprintf('fourier%d',fourierOrder);
    
    f.fit.x.ssh = fourierFit_WaitForLicense(s.x.dist, (s.x.ssh),f.fit.type);
    f.fit.y.ssh = fourierFit_WaitForLicense(s.y.dist, (s.y.ssh),f.fit.type);
    %%
    for xyc = {'x','y'};		xy = xyc{1};
        s.fit.(xy).sshf = feval(f.fit.(xy).ssh, s.(xy).dist);
        s.fit.(xy).UV = fs(1,s.(xy).dist,s.fit.(xy).sshf);
        s.fit.(xy).UVd = fs(2,s.(xy).dist,s.fit.(xy).sshf);
    end
    %     s.fit.type=f.fit.type;
    %%
    %             [~,pex] = min(abs(s.x.idx - double(ee.peak.z.x)));
    %             [~,pey] = min(abs(s.y.idx - double(ee.peak.z.y)));%
    %             figure('visible','off')
    %
    %             subplot(211)
    %             hold on
    %                 plot(s.x.dist,s.x.ssh,s.x.dist,s.FEight.x.sshf,s.x.dist,s.fit.x.sshf)
    %             plot(s.x.dist,s.x.ssh,s.x.dist,s.fit.x.sshf)
    %             axis tight
    %             ax = axis;
    %             plot(s.x.dist([pex pex]),ax([3 4]))
    %             subplot(212)
    %             hold on
    %             plot(s.y.dist,s.y.ssh,s.y.dist,s.FEight.y.sshf,s.y.dist,s.fit.y.sshf)
    %             plot(s.y.dist,s.y.ssh,s.y.dist,s.fit.y.sshf)
    %             axis tight
    %             ax = axis;
    %             plot(s.y.dist([pey pey]),ax([3 4]))
    %         saveas(gcf,[num2str(now),'.png'])
    %
    %     close all
    %%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [radius,pass] = EDDyRadiusFromUV(peak,prof,thresh)
    %%
    [x] = findSigma(peak,prof,'x');
    [y] = findSigma(peak,prof,'y');
    %%
    radius.zonal = diff(x.dis([x.sigma - .5]))/2;
    radius.meridional = diff(y.dis([y.sigma - .5]))/2;
    radius.mean = mean([radius.zonal;radius.meridional]);
    %% coors on ori grid
    halfidx = @(idx,sig) round(mean(idx([sig - .5 sig + .5])));
    radius.coor.xwest = halfidx(x.idx,x.sigma(1));
    radius.coor.xeast = halfidx(x.idx,x.sigma(2));
    radius.coor.ysouth = halfidx(y.idx,y.sigma(1));
    radius.coor.ynorth = halfidx(y.idx,y.sigma(2));
    
    if radius.mean >= thresh, pass = true; else pass = false; end
    
    %%
    
    %
    %     clf
    %     nrmc = @(x) (x - min(x))/max(x - min(x));
    %     figure(10000);clf;set(gcf,'visible','off');
    %     subplot(211)
    %     nrmdssh = nrmc(x.ssh);
    %     plot(x.idx,nrmdssh); hold on
    %     plot(x.idx([x.peakHigh x.peakHigh]),[0 1])
    %     plot(x.idx([x.peakLow x.peakLow]),[0 1],'r')
    %     subplot(212)
    %     nrmdssh = nrmc(y.ssh);
    %     plot(y.idx,nrmdssh); hold on
    %     plot(y.idx([y.peakHigh y.peakHigh]),[0 1])
    %     plot(y.idx([y.peakLow y.peakLow]),[0 1],'r')
    %     saveas(gcf,['AA',num2str(now),'.png'])
    %%
    
    %
    %     figure(1000)
    %     xy = 'y';
    %     nrmc = @(x) (x - min(x))/max(x - min(x));
    %     spl = @(x,abl) spline(1:abl,x,linspace(1,abl,100));
    %     pl = @(x,ab) plot(nrmc(spl(x(ab(1):ab(2)),diff(ab) + 1)));
    %     subplot(131)
    %     pl(prof.fit.(xy).sshf,y.sigma);hold on;	grid minor;axis off tight
    %     subplot(132)
    %     pl(prof.fit.(xy).UV,y.sigma	);hold on;	grid minor;axis off tight
    %     subplot(133)
    %     pl(prof.fit.(xy).UVd,y.sigma	);hold on;	grid minor;axis off tight
    %     figure(5000)
    %     subplot(131)
    %     plot(prof.fit.(xy).sshf);grid minor;axis  tight
    %     subplot(132)
    %     plot(prof.fit.(xy).UV	);grid minor;axis  tight
    %     subplot(133)
    %     plot(prof.fit.(xy).UVd	);grid minor;axis  tight
    %     %
    %%
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A] = findSigma(peak,prof,yx)
    % note that all profiles are 'high pressure' regardless of sense or
    % hemisphere here
    signJump.east = @(X) logical(diff(sign(X([1:end end]))));
    signJump.west = @(X) logical(diff(sign(X([1   1:end]))));
    %% x dir
    A.dUVdx = prof.fit.(yx).UVd ;
    A.UV = prof.fit.(yx).UV  ;
    A.ssh = prof.fit.(yx).sshf;
    A.dis = prof.(yx).dist   ;
    A.idx = prof.(yx).idx    ;
    A.intrpLen = length(A.idx);
    [~,A.peakLow] = min(abs(A.idx - double(peak.(yx)))); % index of peak in high res coors
    idxL = (1:length(A.ssh))';
    switch sign(A.UV(A.peakLow))
        case 1
            A.peakHigh = find(signJump.east(A.UV) &  idxL >= A.peakLow ,1,'first');
        case - 1
            A.peakHigh = find(signJump.west(A.UV) &  idxL <= A.peakLow ,1,'last' );
    end
    % either left bndry or idx left of peak where dVdx crosses x - axis and slope of SSH is uphill
    F.a = A.idx < peak.(yx);
    F.b = signJump.west(A.dUVdx);
    F.c = A.UV > 0;
    A.sigma(1) = max([ 1  find(F.a & F.b & F.c, 1, 'last') ]) + .5;
    % respectively for downhill side
    F.a = A.idx > peak.(yx);
    F.b = signJump.east(A.dUVdx); % right side of idx
    F.c = A.UV < 0;
    A.sigma(2) = min([ numel(A.idx) find(F.a & F.b & F.c, 1, 'first')]) - .5;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [geo] = geocoor(zoom,volume)
    xz = volume.center.xz;
    yz = volume.center.yz;
    geo.lat = interp2(zoom.fields.lat,xz,yz);
    if zoom.fields.lon(1,1) > zoom.fields.lon(1,end)
        zoom.fields.lon = wrapTo180(zoom.fields.lon);
        geo.lon = wrapTo360(interp2(zoom.fields.lon,xz,yz));
    else
        geo.lon = interp2(zoom.fields.lon,xz,yz);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [volume] = CenterOfVolume(zoom,area,Y)
    %% get "volume" of eddy
    ssh = zoom.ssh_BasePos;
    volume.total = mean(ssh(:))*area;
    %% get center of volume  formula:   COVs = \frac{1}{M} \sum_{i = 1}^n m_i \vec{x}_i,
    [XI,YI] = meshgrid(1:size(ssh,2), 1:size(ssh,1));
    y = sum(nansum(ssh.*YI));
    x = sum(nansum(ssh.*XI));
    yz = (y/nansum(ssh(:)));
    xz = (x/nansum(ssh(:)));
    y = yz + double(zoom.limits.y(1)) - 1;
    x = xz + double(zoom.limits.x(1)) - 1;
    volume.center.xz = xz;
    volume.center.yz = yz;
    volume.center.x = x;
    volume.center.y = y;
    volume.center.lin = drop_2d_to_1d(y,x,Y);
    volume.center.linz = drop_2d_to_1d(yz,xz,size(ssh,1));
end


function [circum,f] = contourLengthIntrp(fopt,x,y)
    
    f.ii = linspace(0,2*pi,numel(x))';
    f.II = linspace(0,2*pi,360)';
    f.x = fit(f.ii,x,'smoothingspline',fopt);
    f.y = fit(f.ii,y,'smoothingspline',fopt);
    circum = sum(hypot(diff(feval(f.x,f.II)),diff(feval(f.y,f.II))));
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [circum,f] = EDDyCircumference(z)
    %%
    load  fopt
    ilin = z.coor.int.lin;
    x = z.fields.km_x(ilin);
    y = z.fields.km_y(ilin);
    
    [circum,f] = contourLengthIntrp(fopt,x,y);
    circum = circum * 1000;
    
    %     f.ii = linspace(0,2*pi,numel(x))';
    %     f.II = linspace(0,2*pi,360)';    %
    %     f.x = fit(f.ii,x,'smoothingspline',fopt);
    %     f.y = fit(f.ii,y,'smoothingspline',fopt);
    %     try % TODO   (license issues)
    %         foptions = ; % TODO
    %
    %     catch err
    %         disp(err.message)
    %
    %         f.x = fourierFit_WaitForLicense(f.ii,x,'smoothingspline',foptions);
    %         f.y = fourierFit_WaitForLicense(f.ii,y,'smoothingspline',foptions);
    %     end
    %
    %     circum = sum(hypot(diff(feval(f.x,f.II)),diff(feval(f.y,f.II)))) * 1000;
    
    % 	%%
    % 	clf
    % 	figure(1)
    % 	subplot(121)
    % 	plot(x,y,'r')
    % 	hold on
    % 	plot(f.x(f.II),f.y(f.II))
    % 	subplot(122)
    % 	hold on
    % 	plot(f.II(2:end),diff(f.x(f.II))','b',f.II(2:end),diff(f.y(f.II)),'r')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mask = EDDyCut_mask(zoom)
    %% init
    dummymask = false(size(zoom.fields.ssh));
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
    %% full
    mask.filled = mask.rim_only | mask.inside;
    %% dims
    [mask.dim.y, mask.dim.x] = size(dummymask);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fields_out = EDDyCut_init(win,ssh,z)
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
    fields_out.ssh = cutfield(ssh.ssh);
    %     fields_out.ssh = cutfield(ssh.L);
    %% distances (dont change to cumsum(DX). doesnt work for -180<->180 cases)
    fields_out.km_x = cumsum(mod(diff(fields_out.lon(:,[[1 1:end]]),1,2),360),2);
    fields_out.km_x = fields_out.km_x .* cosd(fields_out.lat);
    fields_out.km_x = deg2km(fields_out.km_x);
    %%
    fields_out.km_y = deg2km(cumsum(diff(fields_out.lat([1 1:end],:),1,1),1));
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [z,passout] = get_window_limits(coor,enlargeFac,map)
    pass = true(3,1);
    z.coor = coor;
    %% output
    z.limits.x(1) = min(coor.int.x);
    z.limits.y(1) = min(coor.int.y);
    z.limits.x(2) = max(coor.int.x);
    z.limits.y(2) = max(coor.int.y);
    %%
    if  exist('enlargeFac','var')
        try % TODO
            [z.limits,z.M] = enlarge_window(z.limits,enlargeFac,map.dimPlus) ; % TODO
        catch
            [z.limits,z.M] = enlarge_window(z.limits,enlargeFac,map.sizePlus) ;
        end
        %%
        z.dim.x = diff(z.limits.x) + 1;
        z.dim.y = diff(z.limits.y) + 1;
        z.coor.int.x = z.coor.int.x - z.limits.x(1) + 1;
        z.coor.int.y = z.coor.int.y - z.limits.y(1) + 1;
        z.coor.int.lin = drop_2d_to_1d(z.coor.int.y,z.coor.int.x,z.dim.y)	;
        z.coor.exact.x = z.coor.exact.x - double(z.limits.x(1)) + 1;
        z.coor.exact.y = z.coor.exact.y - double(z.limits.y(1)) + 1;
        %%
        if strcmp(map.type,'globe') && exist('map','var')
            %% in global case dismiss eddies touching zonal boundaries (another copy of these eddies exists that is not touching boundaries, due to the zonal appendage in S00b
            pass(1) = z.limits.x(1) ~= 1;
            pass(2) = z.limits.x(2) ~= map.dimPlus.x;
        end
    end
    passout = all(pass);
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
function [EE] = eddies2struct(CC,thresh)
    if  ~exist('thresh','var')
        thresh.min=1;
        thresh.max=inf;
    end
    EE=struct;
    ii = 1;cc = 0;
    while ii<size(CC,1);
        len = CC(ii,2);% contourc saves the length of each contour before appending the next
        if len >= thresh.min && len <= thresh.max
            cc = cc + 1;
            EE(cc).level = CC(ii,1);
            EE(cc).circum.length = len;
            EE(cc).coor.exact.x = CC(1 + ii:ii + EE(cc).circum.length,1);
            EE(cc).coor.exact.y = CC(1 + ii:ii + EE(cc).circum.length,2);
            EE(cc).coor.int.x = int32(EE(cc).coor.exact.x);
            EE(cc).coor.int.y = int32(EE(cc).coor.exact.y);
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
    pass(len).CR_2dEDDy = 0;
    pass(len).winlim = 0;
    pass(len).CR_Nan = 0;
    pass(len).CR_sense = 0;
    pass(len).Area = 0;
    pass(len).CR_Shape = 0;
    pass(len).CR_AmpPeak = 0;
    pass(len).CR_radius = 0;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end