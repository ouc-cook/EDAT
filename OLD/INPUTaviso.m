function DD=INPUTaviso
    %% dirs
    [~,DD.path.OutDirBaseName]=fileparts(pwd);
    DD.path.TempSalt.name='/scratch/uni/ifmto/u300065/TempSaltUV/';
    DD.path.UV.name='/scratch/uni/ifmto/u300065/TempSaltUV/';
    DD.path.full3d.name='/scratch/uni/ifmto/u300065/MONTHLY/';
%     DD.path.raw.name='/data/icdc/ocean/aviso_ssh/DATA/weekly/msla/';
    DD.path.raw.name='/data/icdc/ocean/aviso_ssh/DATA/msla/two-sat-merged/h/2003/'; % TODO dir structure was changed :(
    DD.path.OkuboWeiss.name='/scratch/uni/ifmto/u300065/FINAL/okuboWeiss/';
   %% binned out map res
    DD.map.out.binSize = 1; % eg 1 for 1 degree
    %% map in keys
    DD.map.full3d.fname='GLB_t0.1_42l_CORE.yyyymm.tar';
%     DD.map.in.fname='SsaltoDuacs__merged_msla__AVISO__ref__0.25deg__yyyymmdd.nc';    
    DD.map.in.fname='dt_global_twosat_msla_h_yyyymmdd_20140106.nc';  
    DD.map.in.keys.lat='lat';
    DD.map.in.keys.lon='lon';
    DD.map.in.keys.ssh='sla';
    DD.map.in.keys.time='time';
     DD.map.in.keys.U='UVEL';
    DD.map.in.keys.V='VVEL';
    DD.map.in.keys.x='XT';
    DD.map.in.keys.y='YT';
    DD.map.in.keys.z='ZT';
    DD.map.in.keys.N='N';
    DD.map.in.cdfName='new2.cdf';
    %% temp salt keys
    DD.TS.keys.lat='U_LAT_2D';
    DD.TS.keys.lon='U_LON_2D';
    DD.TS.keys.salt='SALT';
    DD.TS.keys.temp='TEMP';
    DD.TS.keys.depth='depth_t';
    %% parameters
    DD.parameters.ssh_unitFactor = 1; % eg 100 if SSH data in cm, 1/10 if in deka m etc..
    DD.parameters.rossbySpeedFactor=1.75; % only relevant if cheltons method is used. eddy translation speed assumed factor*rossbyWavePhaseSpeed for tracking projections
    DD.parameters.meanU=100; % depth from which to take mean U
    DD.parameters.meanUunit=100; % depth from which to take mean U
    DD.parameters.minProjecDist=150e3; %  (per week)  minimum linear_eccentricity*2 of ellipse (see chelton 2011)
    DD.parameters.trackingRef='CenterOfVolume'; % choices: 'centroid', 'CenterOfVolume', 'Peak'
%    DD.parameters.trackingRef='centroid';
    DD.parameters.Nknown=false; % Brunt-Väisälä f already in data
    DD.parameters.RossbySplits =12; % number of chunks for brunt väis calculations
    DD.parameters.SSHAdepth=-25;
  DD.parameters.salinityFactor=1000;
       %%
    DD.switchs.rehashMapDims=true; %!!
