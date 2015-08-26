function makePseudoSshFromP
    global LAT LON
    
    path.pres = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/PRES/';
    path.pseudoSsh = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/pseudoSsh/';
    keys.fnpattern = 'PSEUDOSSH_GLB_t.t0.1_42l_CORE.yyyymmdd.nc';
    keys.lat = 'U_LAT_2D';
    keys.lon = 'U_LON_2D';
    keys.ssh = 'SSH';
    
    mkdirp(path.pseudoSsh)
    
    laloFile = '/scratch/uni/ifmto/u241194/DAILY/EULERIAN/1994-1995/GLB_199402/SSH_GLB_t.t0.1_42l_CORE.19940201.nc'
    LAT = ncread(laloFile,keys.lat);
    LON = ncread(laloFile,keys.lon);
    
    
    path.subdirs.pres = dir2([path.pres 'GLB_*']);
    
    
    for mm = 1:numel(path.subdirs.pres)
        subp.pres  = dir2([path.subdirs.pres(mm).fullname '/PRES*nc']);
        
        [~,subp.name,~] = fileparts(path.subdirs.pres(mm).fullname);
        
        
        if isempty(subp.pres)
            continue
        end
        
        for dd = 1:numel(subp.pres)
            fprintf('%d%% done\n',round(100*dd/numel(subp.pres)));
            try
                opDay(subp,dd,keys,path);
            catch me
                fprintf('error at %d\n',dd)
                disp(me.message);
            end
        end
    end
end


function opDay(subp,dd,keys,path)
    global LAT LON
    Pf = subp.pres(dd).fullname;
    
    %% read
    pres = ncread(Pf,'PRES');
    
    %% dims
    [X,Y] = size(pres);
    
    %% pseudo SSH
    g = 9.81;
    rho0 = 1000;
    pres = pres - nanmedian(pres(:));
    ssh = pres*1e4/g/rho0;
    ssh = ssh*100; % m 2 cm
    ssh(abs(ssh)>1000)=nan;
    
    %% write netCdf
    [~,fname,~] = fileparts(Pf);
    ymd = fname(26:33);
    Fout = [path.pseudoSsh strrep(keys.fnpattern,'yyyymmdd',ymd)];
    nccreate(Fout,keys.ssh,'Dimensions',{'X',X,'Y',Y});
    nccreate(Fout,keys.lat,'Dimensions',{'X',X,'Y',Y});
    nccreate(Fout,keys.lon,'Dimensions',{'X',X,'Y',Y});
    ncwrite(Fout,keys.ssh,ssh);
    ncwrite(Fout,keys.lat,LAT);
    ncwrite(Fout,keys.lon,LON);
    
end