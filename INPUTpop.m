function DD=INPUTpop
    
    %% dirs
    [~,DD.path.OutDirBaseName]=fileparts(pwd);
    DD.path.raw.name='/scratch/uni/ifmto/u241194/DAILY/EULERIAN/SSH/';
    
    %% map in keys
    DD.map.in.fname    = 'SSH_GLB_t.t0.1_42l_CORE.yyyymmdd.nc';
    DD.map.in.keys.lat = 'U_LAT_2D';
    DD.map.in.keys.lon = 'U_LON_2D';
%     DD.map.in.keys.rho = 'density';
    DD.map.in.keys.ssh = 'SSH';
    DD.map.in.keys.time= 'TIME'; % TODO?
%     DD.map.in.keys.N   = 'N';
    
    %% parameters
    DD.parameters.ssh_unitFactor = 100; % eg 100 if SSH data in cm, 1/10 if in deka m etc..
       
end


%     DD.path.OkuboWeiss.name='/scratch/uni/ifmto/u300065/FINAL/okuboWeiss/';

%     DD.path.UV.name='/scratch/uni/ifmto/u300065/TempSaltUV/';
%     DD.path.full3d.name='/scratch/uni/ifmto/u300065/MONTHLY/';

%     DD.map.full3d.fname='GLB_t0.1_42l_CORE.yyyymm.tar';
%     DD.map.in.fname='rho_yyyymmdd.nc';
%     DD.map.in.LatLonDepthFile=[DD.path.raw.name 'LatLonDepth.nc'];


%     DD.map.in.keys.U='UVEL';
%     DD.map.in.keys.V='VVEL';
%     DD.map.in.keys.x='XT';
%     DD.map.in.keys.y='YT';
%     DD.map.in.keys.z='w_dep';


%     DD.parameters.meanUtop = 800; % depth from which to take mean U top
%     DD.parameters.meanUbot = 1000; % depth from which to take mean U bottom
%     DD.parameters.meanUunit=100; %

%     DD.parameters.zLevel = 5; % 0 for SSH