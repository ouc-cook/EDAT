function DD=INPUTmad
    %% time step
    DD.time.delta_t=3; % [days]!
    %% dirs
    [~,DD.path.OutDirBaseName]=fileparts(pwd);
    DD.path.TempSalt.name='../rawMad/';
    DD.path.UV.name='../rawMad/';
    DD.path.raw.name='../rawMad/';
    %% map in keys
    DD.map.in.fname='RAWyyyymmdd.nc';
    DD.map.in.keys.ssh='SSHA';
    DD.map.in.keys.time='TIME';
    DD.map.in.keys.U='U';
    DD.map.in.keys.V='V';
    DD.map.in.keys.x='XT';
    DD.map.in.keys.y='YT';
    DD.map.in.keys.z='ZT';
    DD.map.in.keys.N='N';
    DD.map.in.cdfName='new2.cdf';
    DD.map.in.keys.lat='lat';
    DD.map.in.keys.lon='lon';  
    %% temp salt keys
    DD.TS.keys.lat='U_LAT_2D';
    DD.TS.keys.lon='U_LON_2D';
    DD.TS.keys.salt='SALT';
    DD.TS.keys.temp='TEMP';
    DD.TS.keys.depth='depth_t'; 
    %% parameters 
    DD.parameters.Nknown=true; % Brunt-Väisälä f already in data
    DD.parameters.SSHAdepth=-25;
    DD.parameters.ssh_unitFactor = 1000; % eg 100 if SSH data in cm, 1/10 if in deka m etc..
    DD.parameters.rossbySpeedFactor=1.75; % only relevant if cheltons method is used. eddy translation speed assumed factor*rossbyWavePhaseSpeed for tracking projections
    DD.parameters.meanU=-200; % depth from which to take mean U
    DD.parameters.meanUunit=1; %
    DD.parameters.minProjecDist=150e3; %  (per week) minimum linear_eccentricity*2 of ellipse (see chelton 2011)
    DD.parameters.Gausswidth=1e5;
    DD.parameters.trackingRef='CenterOfVolume'; % choices: 'centroid', 'CenterOfVolume', 'Peak'
    DD.parameters.RossbySplits =12; % number of chunks for brunt väis calculations
     DD.parameters.salinityFactor=1000;
    %%
     DD.switchs.rehashMapDims=false; %!!
    %% special:    
    DD.parameters.boxlims.south=10;
   
    
    
    
    
    
    
    
    
    
    
