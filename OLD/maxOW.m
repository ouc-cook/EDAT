%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxOW
    %% init
    DD=initialise([],mfilename);
    DD=maxOWsetUp(DD);
    main(DD);
    %% post process
    %     maxOWpostProc
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)   ;dF
    DD=maxOWPrep(DD);
%     save DD
    %    maxOWrho
    %     maxOWrhoMean
    maxOWcalc
    %     maxOWprocessInit
    %     maxOWprocMeanOW
    %     maxOWprocCalc
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DD=maxOWPrep(DD);dF
    DD.f=funcs;
    ws = DD.TSow.window.size;
    FileIn = DD.path.TSow.files(1);
    keys = DD.TS.keys;
    raw.depth = nc_varget(FileIn.salt,keys.depth);
    raw.lat = nc_varget(FileIn.temp, keys.lat);
    raw.lon = nc_varget(FileIn.temp, keys.lon);
    [raw.dy,raw.dx] = getdydx( raw.lat, raw.lon);
    raw.corio = coriolisStuff(raw.lat);
    DD.Dim.ws=ws;
    DD.raw=raw;
    %% geo
    nc_varput(DD.path.TSow.geo,'depth',raw.depth);
    nc_varput(DD.path.TSow.geo,'lat',raw.lat);
    nc_varput(DD.path.TSow.geo,'lon',raw.lon);
   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = coriolisStuff(lat);dF
    OmegaTw = 2*angularFreqEarth;
    %% f
    out.f = OmegaTw*sind(lat);
    %% beta
    out.beta = OmegaTw/earthRadius*cosd(lat);
    %% gravity
    g = sw_g(lat,zeros(size(lat)));
    %% g/f
    out.GOverF = g./out.f;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dy,dx] = getdydx(lat,lon);dF
    %% grid increment sizes
    dy = deg2rad(abs(diff(double(lat),1,1)))*earthRadius;
    dx = deg2rad(abs(diff(double(lon),1,2)))*earthRadius.*cosd(lat(:,1:end-1));
    %% append one line/row to have identical size as other fields
    dy = dy([1:end end],:);
    dx = dx(:,[1:end end]);
    %% correct 360° crossings
    seamcrossflag = dx>100*median(dx(:));
    dx(seamcrossflag) = abs(dx(seamcrossflag) - 2*pi*earthRadius.*cosd(lat(seamcrossflag)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=funcs;dF
    f.oneDit = @(md) reshape(md,[],1);
    f.mDit = @(od,ws) reshape(od,[ws(1),ws(2),ws(3)]);
    f.locCo = @(x) getLocalPart(codistributed(f.oneDit(x)));
    f.yx2zyx = @(yx,Z) f.oneDit(repmat(permute(yx,[3,1,2]),[Z,1,1]));
    f.ncvp = @(file,field,array,Ds,De) nc_varput(file,field,array,Ds,De);
    %%
    f.ncvg = @(file,field) nc_varget(file,field);
    f.nansumNcvg = @(A,file,field) nansum([A,f.locCo(f.ncvg(file,field))],2);
    f.ncv=@(d,field) nc_varget(d,field);
    f.ncvOne = @(A) getLocalPart(codistributed(A,codistributor1d(1)));
    f.repinZ = @(A,z) repmat(permute(A,[3,1,2]),[z,1,1]);
    f.ncVP = @(file,OW,field)  nc_varput(file,field,single(OW));
    f.vc2mstr=@(ow,dim) gcat(ow,dim,1);
    f.getHP = @(cf,f) f.ncvOne(f.ncv(cf,'density'));
    f.slMstrPrt = @(p) p{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
