function DD=INPUTdepth

%     zz = 22;
    zz = 26;

    %% dirs
    [~,DD.path.OutDirBaseName]=fileparts(pwd);
    DD.path.raw.name='/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/pseudoSsh/';

    %% map in keys
    DD.map.in.fname    = ['PSEUDOSSH_GLB_t.t0.1_42l_CORE.yyyymmdd_at-z' num2str(zz) '.nc'];
    DD.map.in.keys.lat = 'U_LAT_2D';
    DD.map.in.keys.lon = 'U_LON_2D';
    DD.map.in.keys.ssh = 'SSH';

    %% parameters
    DD.parameters.ssh_unitFactor = 100; % eg 100 if SSH data in cm, 1/10 if in deka m etc..

    %% switches
    DD.switches.isAnomaly = false;

end
