function makeDensity
    thr = 4; % workers
    YY=1996:2000;
    init_threads(thr);
    for yy = YY
        main(yy,thr);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(yy,thr)
    path.root = ['/scratch/uni/ifmto/u241194/DAILY/EULERIAN/' num2str(yy) '/'];
    path.out  = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/DENS/';
    path.subdirs = dir2([path.root 'GLB_*']);
    
    for mm = 1:numel(path.subdirs)
        subp.temp = dir2([path.subdirs(mm).fullname '/TEMP*nc']);
        subp.salt = dir2([path.subdirs(mm).fullname '/SALT*nc']);
        [~,subp.name,~] = fileparts(path.subdirs(mm).fullname);
        subp.out = [path.out subp.name '/'];
        mkdirp(subp.out);
        
        lims = thread_distro(thr,numel(subp.temp));
        T = disp_progress('init',['density year ' num2str(yy)]);
        spmd(thr)
            for dd = lims(labindex,1):lims(labindex,2)
                T = disp_progress('show',T,diff(lims(labindex,:)));
                try
                    opDay(subp,dd);
                catch me
                    fprintf('error at %d',dd)
                    disp(me.message);
                end
            end
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function opDay(subp,dd)
    %%
    Tf = subp.temp(dd).fullname;
    Sf = subp.salt(dd).fullname;
    %%
    [~,fname,ext] = fileparts(Tf);
    Fout = [subp.out strrep(fname,'TEMP','DENS') ext];
    if exist(Fout,'file'),return,end
    %% read
    lat = ncread(Tf,'U_LAT_2D');
    temp = ncread(Tf,'TEMP');
    salt = ncread(Sf,'SALT')*1000;
    depth = ncread(Tf,'depth_t');
    %% dims
    [X,Y] = size(lat);
    Z = length(depth);
    %% pres from depth
    presDB = sw_pres(repmat(permute(depth,[2 3 1]),[X Y 1]),repmat(lat,[1 1 Z]));
    %% dens from S T P
    dens = sw_dens(salt,temp,presDB);
    %% write netCdf
    nccreate(Fout,'DENS','Dimensions',{'X',X,'Y',Y,'Z',Z});
    ncwrite(Fout,'DENS',dens)
end