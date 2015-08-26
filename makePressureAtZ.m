function makePressureAtZ
    global g zi meanSsh
    g = 9.81;
    zi = 22; % depth level to calc p at
    meanSSHfile = '/scratch/uni/ifmto/u300065/dataFO/meanSSH.mat';
    path.dens = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/DENS/';
    path.pres = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/PRES/';
    path.ssh  = '/scratch/uni/ifmto/u241194/DAILY/EULERIAN/1994-1995/';
    
    path.subdirs.dens = dir2([path.dens 'GLB_*']);
    path.subdirs.ssh  = dir2([path.ssh  'GLB_*']);
    
    meanSsh = getfield(load(meanSSHfile),'sshMean');
    meanSsh = permute(meanSsh(:,1:3600),[2 1]);
    
    for mm = 1:numel(path.subdirs.dens)
        subp.dens  = dir2([path.subdirs.dens(mm).fullname '/DENS*nc']);
        subp.ssh  = dir2([path.subdirs.ssh(mm).fullname  '/SSH*nc' ]);
        if isempty(subp.ssh)
            continue
        end
        [~,subp.name,~] = fileparts(path.subdirs.dens(mm).fullname);
        subp.out = [path.pres subp.name '/'];
        mkdirp(subp.out);
        for dd = 1:numel(subp.dens)
            fprintf('%d%% done\n',round(100*dd/numel(subp.dens)));
            try
                opDay(subp,dd);
            catch me
                fprintf('error at %d\n',dd)
                disp(me.message);
            end
        end
    end
end


function opDay(subp,dd)
    global g zi meanSsh    
    Df = subp.dens(dd).fullname;
    Sf = subp.ssh(dd).fullname;
    %% read
    depth = ncread(Sf,'depth_t');
    depthw= ncread(Sf,'w_dep');
    ssh   = ncread(Sf,'SSH')/100 - meanSsh;
    dens  = ncread(Df,'DENS');
    %% dims
    [X,Y,~] = size(dens);
   
    %% cell heights
    DEPTH = repmat(permute(depth,[2 3 1]),[X,Y,1]); % depth at values
    DEPTHW= repmat(permute(depthw,[2 3 1]),[X,Y,1]); % depth at edges of cells
    DEPTHW(:,:,1) = DEPTHW(:,:,1) - ssh; % shift 0'th edge according to ssh
    delDEP = diff(DEPTHW,1,3);
    
    %% pressure
    pres = g*sum(delDEP(:,:,1:zi).*dens(:,:,1:zi),3);
    pres = pres*1e-4; % pascal to db
        
    %% write netCdf
    [~,fname,ext] = fileparts(Df);
    Fout = [subp.out strrep(fname,'DENS','PRES') '_at-z' num2str(zi) ext];
    nccreate(Fout,'PRES','Dimensions',{'X',X,'Y',Y});
    ncwrite(Fout,'PRES',pres);
end