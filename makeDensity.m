function makeDensity
    
    path.root = '/scratch/uni/ifmto/u241194/DAILY/EULERIAN/1994-1995/';
    path.out  = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/DENS/';
    path.subdirs = dir2([path.root 'GLB_*']);
    
    for mm = 1:numel(path.subdirs)
        subp.temp = dir2([path.subdirs(mm).fullname '/TEMP*nc']);
        subp.salt = dir2([path.subdirs(mm).fullname '/SALT*nc']);
        [~,subp.name,~] = fileparts(path.subdirs(mm).fullname);
        subp.out = [path.out subp.name '/'];
        mkdirp(subp.out);
        for dd = 1:numel(subp.temp)
            try
                opDay(subp,dd);
            catch me
                fprintf('error at %d',dd)
                disp(me.message);
            end
        end
    end
end


function opDay(subp,dd)
    dd
    Tf = subp.temp(dd).fullname;
    Sf = subp.salt(dd).fullname;
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
    [~,fname,ext] = fileparts(Tf);
    Fout = [subp.out strrep(fname,'TEMP','DENS') ext];
    nccreate(Fout,'DENS','Dimensions',{'X',X,'Y',Y,'Z',Z});
    ncwrite(Fout,'DENS',dens)
end