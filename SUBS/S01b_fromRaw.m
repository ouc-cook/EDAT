%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% integrates over depth to calculate
% -Brunt Väisälä frequency
% -Rossby Radius
% -Rossby wave first baroclinic phase speed

% TODO redo ALL !!!
function S01b_fromRaw
    %% set up
    [DD]=set_up;
    %% spmd
    main(DD)
    %% update DD
    save_info(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    Calculations(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD]=set_up
    %% init
    DD=initialise([],mfilename);
    %% get window according to user input
    [DD.TS.window,~]=GetWindow(DD.path.Rossby.Nfile,DD.map.in,DD.map.in.keys);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Calculations(DD)
    CK=initCK(DD);
    %% get Brunt-Väisälä
    CK.N=nc_varget(DD.path.Rossby.Nfile,'N',  CK.dim.start3d ,CK.dim.len3d);
    %% integrate first baroclinic rossby radius
    [CK.rossby.Ro1]=calcRossbyRadius(CK);
    %% rossby wave phase speed
    [CK.rossby.c1]=calcC_one(CK);
    %% append 10th 
    if strcmp(DD.map.window.type,'globe')
        xadd=round(DD.map.window.fullsize(2)/10);
        CK.corio.beta=CK.corio.beta(:,[1:end,1:xadd]);
        CK.corio.f=CK.corio.f(:,[1:end,1:xadd]);
        CK.rossby.Ro1=CK.rossby.Ro1(:,[1:end,1:xadd]);
        CK.rossby.c1=CK.rossby.c1(:,[1:end,1:xadd]);
        CK.N=CK.N(:,[1:end,1:xadd]);
    end
    %% save
    disp('saving..')
    file_out=[DD.path.Rossby.name,'BVRf_all.mat'];
    save(file_out,'-struct','CK');
    %%
    file_out=[DD.path.Rossby.name 'RossbyPhaseSpeed.mat'];
    data=CK.rossby.c1;
    save(file_out,'data');
    %%
    file_out=[DD.path.Rossby.name 'RossbyRadius.mat'];
    data=CK.rossby.Ro1; %#ok<*NASGU>
    save(file_out,'data');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function R=	calcRossbyRadius(CK)
    disp(['integrating Rossby Radius'])
    [~,YY,XX]=size(CK.N);
    M.depthdiff=repmat(diff(CK.DEPTH),[1 YY XX]);
    Nmid=(CK.N(1:end-1,:,:) + CK.N(2:end,:,:))/2;
    R=abs(double((squeeze(nansum(M.depthdiff.*Nmid,1))./CK.corio.f)/pi));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [c1]=calcC_one(CK)
    %    c=-beta/(k^2+(1/L_r)^2) approx -beta*L^2
    disp(['applying long rossby wave disp rel for c1'])
    c1=-CK.corio.beta.*CK.rossby.Ro1.^2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CK,DD]=initCK(DD)
    CK.dim=ncArrayDims(DD);
    disp('getting depth..')
    CK.DEPTH=nc_varget(DD.path.Rossby.Nfile,DD.map.in.keys.z);
    disp('getting geo info..')
    [CK.lat,CK.lon]=LatLon(DD,CK.dim);
    disp('getting coriolis stuff..')
    [CK.corio]=Corio(CK);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [corio]=Corio(CK)
    day_sid=23.9344696*60*60;
    om=2*pi/(day_sid); % frequency earth
    corio.f=2*om*sind(CK.lat);
    corio.beta=2*om/earthRadius*cosd(CK.lat);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lat,lon]=LatLon(DD,dim)
    lat=nc_varget(DD.path.Rossby.Nfile,DD.map.in.keys.lat,dim.start2d, dim.len2d);
    lon=nc_varget(DD.path.Rossby.Nfile,DD.map.in.keys.lon,dim.start2d, dim.len2d);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dim=ncArrayDims(DD)
    j_start = DD.TS.window.limits.south-1;
    j_len = DD.TS.window.dim.Y;
    i_start = DD.TS.window.limits.west-1;
    i_len = DD.TS.window.dim.X;
    k_start = 0;
    k_len = inf;
    dim.start3d = [k_start j_start  i_start];
    dim.len3d = 	[k_len j_len i_len];
    dim.start2d = [j_start  i_start];
    dim.len2d = 	[j_len i_len];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%