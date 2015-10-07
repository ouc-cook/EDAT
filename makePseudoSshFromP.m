function makePseudoSshFromP
    zz = 26;
    
    path.pres = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/PRES/';
    path.pseudoSsh = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/pseudoSsh/';
    keys.fnpattern = ['PSEUDOSSH_GLB_t.t0.1_42l_CORE.yyyymmdd_at-z' num2str(zz) '.nc'];
    keys.lat = 'U_LAT_2D';
    keys.lon = 'U_LON_2D';
    keys.ssh = 'SSH';
    
    mkdirp(path.pseudoSsh)
    
    laloFile = '/scratch/uni/ifmto/u241194/DAILY/EULERIAN/1994-1995/GLB_199402/SSH_GLB_t.t0.1_42l_CORE.19940201.nc';
    LAT = ncread(laloFile,keys.lat);
    LON = ncread(laloFile,keys.lon);
    
    path.subdirs.pres = dir2([path.pres 'GLB_*']);
    
    thr = 4;
    init_threads(thr);
    spmd(thr)
        lims = thread_distro(thr,numel(path.subdirs.pres));
        spmdBlock(path,keys,lims(labindex,:),LAT,LON,zz);
    end
end

function spmdBlock(path,keys,lims,LAT,LON,zz)
    T = disp_progress('init','making pseudo ssh');
    for mm = lims(1):lims(2)
        T = disp_progress('blubb',T,diff(lims)+1);
        subp.pres  = dir2([path.subdirs.pres(mm).fullname '/PRES*at-z' num2str(zz) '.nc']);
        [~,subp.name,~] = fileparts(path.subdirs.pres(mm).fullname);
        if isempty(subp.pres)
            continue
        end
        for dd = 1:numel(subp.pres)
            %             fprintf('%d%% done\n',round(100*dd/numel(subp.pres)));
            try
                opDay(subp,dd,keys,path,LAT,LON);
            catch me
                fprintf('error at %d\n',dd)
                disp(me.message);
            end
        end
    end
end

function opDay(subp,dd,keys,path,LAT,LON)
    Pf = subp.pres(dd).fullname;
    %% read
    pres = ncread(Pf,'PRES');
    %% dims
    [X,Y] = size(pres);
    %% pseudo SSH
    g = 9.81;
    rho0 = 1000;
    ssh = pres*1e4/g/rho0;
    ssh = ssh*100; % m 2 cm
    %% write netCdf
    [~,fname,~] = fileparts(Pf);
    ymd = fname(26:33);
    
    Fout = [path.pseudoSsh strrep(keys.fnpattern,'yyyymmdd',ymd)];
    system(['rm ' Fout]);
    nccreate(Fout,keys.ssh,'Dimensions',{'X',X,'Y',Y});
    nccreate(Fout,keys.lat,'Dimensions',{'X',X,'Y',Y});
    nccreate(Fout,keys.lon,'Dimensions',{'X',X,'Y',Y});
    ncwrite(Fout,keys.ssh,ssh);
    ncwrite(Fout,keys.lat,LAT);
    ncwrite(Fout,keys.lon,LON);
    
end