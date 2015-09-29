function DD = INPUTaviso
    
    %% dirs
    [~,DD.path.OutDirBaseName] = fileparts(pwd);
    DD.path.raw.name = '/data/icdc/ocean/aviso_ssh/DATA/msla/two-sat-merged/h/2003/'; % TODO dir structure was changed :(
    
    %% map in keys
    DD.map.in.fname = 'dt_global_twosat_msla_h_yyyymmdd_20140106.nc';
    DD.map.in.keys.lat = 'lat';
    DD.map.in.keys.lon = 'lon';
    DD.map.in.keys.ssh = 'sla';
    DD.map.in.keys.time = 'time';
    
    
    %% parameters
    DD.parameters.ssh_unitFactor = 1; % eg 100 if SSH data in cm, 1/10 if in deka m etc..
    
    %% switches
    DD.switches.isAnomaly = true;
end