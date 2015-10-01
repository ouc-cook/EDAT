function DD=INPUTpop2avi
    %% dirs
    [~,DD.path.OutDirBaseName]=fileparts(pwd);
    DD.path.raw.name='/scratch/uni/ifmto/u300065/POP2AVIssh/';
    
    %% map in keys
    DD.map.in.fname    = 'SSH_GLB_t.t0.1_42l_CORE.yyyymmdd.mat';
    DD.map.in.keys.lat='lat';
    DD.map.in.keys.lon='lon';
    DD.map.in.keys.ssh='msla';
    DD.map.in.keys.time='time';
    
    %% parameters
    DD.parameters.ssh_unitFactor = 100; % eg 100 if SSH data in cm, 1/10 if in deka m etc..
    
    
    
    %% switches
    DD.switches.isAnomaly = false;
end




