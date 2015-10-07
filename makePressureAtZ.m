function makePressureAtZ
    g = 9.81;
    % set vertical level
    zi = 26; % 1875m
    %     zi = 19; % 465m
    %     zi = 22; % 918m
    
    %%
    init_threads(12);
    path.dens = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/DENS/';
    path.pres = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/PRES/';
    path.ssh  = '/scratch/uni/ifmto/u241194/DAILY/EULERIAN/';
    
    years = 1994:1996;
    for yy=years
        main(path,yy,g,zi)
    end
end

function main(path,yy,g,zi)
    
    for mm = 1:12
        
        monDir = sprintf('GLB_%d%02d',yy,mm);
        subp.dens  = dir2([path.dens monDir '/DENS*nc']);
        if yy==1994 || yy==1995
            subp.ssh = dir2([path.ssh '1994-1995/' monDir '/SSH*nc' ]);
        else
            subp.ssh = dir2([path.ssh num2str(yy) '/' monDir '/SSH*nc' ]);
        end
        
        if isempty(subp.ssh)
            continue
        end
        
        subp.out = [path.pres monDir '/'];
        mkdirp(subp.out);
        
        T=disp_progress('init',monDir);
        spmd(12)
            lims = thread_distro(12,numel(subp.dens));
            for dd=lims(labindex,1):lims(labindex,2)
                T=disp_progress('ghfdg',T,diff(lims(labindex,1))+1);
                fprintf('%d%% done\n',round(100*dd/numel(subp.dens)));
                try
                    opDay(subp,dd,g,zi);
                catch me
                    dd
                    disp(me.message)
                    
                end
            end
        end
    end
end

function opDay(subp,dd,g,zi)
    Df = subp.dens(dd).fullname;
    Sf = subp.ssh(dd).fullname;
    [~,fname,ext] = fileparts(Df);
    Fout = [subp.out strrep(fname,'DENS','PRES') '_at-z' num2str(zi) ext];
    if exist(Fout,'file')
        return
    end
    
    %% read
    %     depth = ncread(Sf,'depth_t');
    depthw= ncread(Sf,'w_dep');
    ssh   = ncread(Sf,'SSH')/100;
    dens  = ncread(Df,'DENS');
    %% dims
    [X,Y,~] = size(dens);
    
    %% cell heights
    %     DEPTH = repmat(permute(depth,[2 3 1]),[X,Y,1]); % depth at values
    DEPTHW= repmat(permute(depthw,[2 3 1]),[X,Y,1]); % depth at edges of cells
    DEPTHW(:,:,1) = DEPTHW(:,:,1) - ssh; % shift 0'th edge according to ssh
    delDEP = diff(DEPTHW,1,3);
    
    %% pressure
    pres = g*sum(delDEP(:,:,1:zi).*dens(:,:,1:zi),3);
    pres = pres*1e-4; % pascal to db
    
    %% write netCdf
    system(['rm -f ' Fout]);
    nccreate(Fout,'PRES','Dimensions',{'X',X,'Y',Y});
    ncwrite(Fout,'PRES',pres);
end