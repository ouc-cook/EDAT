function DD=INPUTpop
    %% dirs
    [~,DD.path.OutDirBaseName]=fileparts(pwd);
    DD.path.TempSalt.name='/scratch/uni/ifmto/u300065/TempSaltUV/';
    DD.path.UV.name='/scratch/uni/ifmto/u300065/TempSaltUV/';
    DD.path.full3d.name='/scratch/uni/ifmto/u300065/MONTHLY/';
    DD.path.raw.name='/scratch/uni/ifmto/u241194/DAILY/EULERIAN/SSH/';
    DD.path.OkuboWeiss.name='/scratch/uni/ifmto/u300065/FINAL/okuboWeiss/';
    %% map in keys
    DD.map.out.binSize = 1; % eg 1 for 1 degree
    DD.map.full3d.fname='GLB_t0.1_42l_CORE.yyyymm.tar';
    %     DD.map.in.fname='rho_yyyymmdd.nc';
    %     DD.map.in.LatLonDepthFile=[DD.path.raw.name 'LatLonDepth.nc'];
    DD.map.in.fname='SSH_GLB_t.t0.1_42l_CORE.yyyymmdd.nc';
    DD.map.in.keys.lat='U_LAT_2D';
    DD.map.in.keys.lon='U_LON_2D';
    %     DD.map.in.keys.lat='lat';
    %     DD.map.in.keys.lon='lon';
    DD.map.in.keys.rho='density';
    DD.map.in.keys.ssh='SSH';
    DD.map.in.keys.time='TIME';
    DD.map.in.keys.U='UVEL';
    DD.map.in.keys.V='VVEL';
    DD.map.in.keys.x='XT';
    DD.map.in.keys.y='YT';
    DD.map.in.keys.z='w_dep';
    DD.map.in.keys.N='N';
    DD.map.in.cdfName='new2.cdf';
    %% temp salt keys
    DD.TS.keys.lat='U_LAT_2D';
    DD.TS.keys.lon='U_LON_2D';
    DD.TS.keys.salt='SALT';
    DD.TS.keys.temp='TEMP';
    DD.TS.keys.depth='depth_t';
    %% parameters
    DD.parameters.ssh_unitFactor = 100; % eg 100 if SSH data in cm, 1/10 if in deka m etc..
    DD.parameters.rossbySpeedFactor=1.75; % only relevant if cheltons method is used. eddy translation speed assumed factor*rossbyWavePhaseSpeed for tracking projections
    DD.parameters.meanUtop = 800; % depth from which to take mean U top
    DD.parameters.meanUbot = 1000; % depth from which to take mean U bottom
    DD.parameters.meanUunit=100; %
    DD.parameters.minProjecDist=350e3; % (per week)  minimum linear_eccentricity*2 of ellipse (see chelton 2011)
    DD.parameters.trackingRef='CenterOfVolume'; % choices: 'centroid', 'CenterOfVolume', 'Peak'
    DD.parameters.Nknown=false; % Brunt-Väisälä f already in data
    DD.parameters.RossbySplits =28; % number of chunks for brunt väis calculations
    DD.parameters.SSHAdepth=-25;
    DD.parameters.salinityFactor=1000;
    DD.parameters.zLevel=5; % 0 for SSH
    %%
    DD.switchs.rehashMapDims=true; %!!
end
