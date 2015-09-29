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
    
    %% switches
    DD.switches.isAnomaly = false;
end
