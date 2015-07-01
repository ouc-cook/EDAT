function makePressure2
    addpath(genpath('./'))
    dbstop if error  
    rootDir='/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/';
    [geo,files,outDir]=getData(rootDir);
    %%
    [Z,Y,X,geo]= inits(geo,files);
    T= disp_progress('init','all rhos');
    spmdBlock(T,files,outDir,geo,Y,X,Z)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmdBlock(T,files,outDir,geo,Y,X,Z)
    for ii=1:numel(files.salt)
        T=    disp_progress('kuguz',T,numel(files.salt));
        try
            opDay(files,ii,Y,X,Z,outDir,geo)
        catch me
            disp(me.message)
            continue
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lalo,files,outDir]=getData(rD)
    files.rho = dir2([rD 'rho/rho_*.nc']);
    files.ssh = dir2([rD 'ssh/SSH_*.nc']);
    files.salt = dir2([rD 'salt/SALT_*.nc']);
    files.temp = dir2([rD 'temp/TEMP_*.nc']);
    lld=[rD 'LatLonDepth.nc'];
    lalo.la=nc_varget(lld,'lat');
    lalo.lo=nc_varget(lld,'lon');
    lalo.de=nc_varget(lld,'depth');
    outDir.p   = [rD 'pressure/'];
    outDir.rho = [rD 'density/'];
    mkdirp(outDir.p );
    mkdirp(outDir.rho );
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Z,Y,X,geo]= inits(geo,files)
    [Y,X]=  size(geo.la);
    [Z]= numel(geo.de) ;
    %5
    disp('dep')
    full.depth = repmat([0; geo.de],[1,Y,X]);
    geo.full.depDiff = diff(full.depth,1,1);
    %%
    disp('lat')
    lat   = (permute(repmat(geo.la,[1,1,Z]),[3,1,2]));
    %%
    disp('g')
    ga=@(M) M(:);
    geo.G=(reshape(sw_g(lat(:),ga(full.depth(2:end,:,:))),[Z,Y,X]));
    %%
    disp('bathym')
    flag=(nc_varget(files.salt(1).fullname,'SALT'))==0;
    geo.full.bathym=flag;
    %%
    FgPerVolZero   = 1000  .*geo.G;
    geo.full.Pzero =  FgPerVolZero .* full.depth(2:end,:,:)   ;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function opDay(files,ii,Y,X,Z,outDir,geo)
    persistent ssh dZ pseudoSsh rho salt temp land
    Fssh  = files.ssh(ii).fullname;
    Fsalt = files.salt(ii).fullname;
    Ftemp = files.temp(ii).fullname;
    [~,b,c]=fileparts(Fsalt);
    pname =@(type) [outDir.(type) '%s_' b(5:end) c];
    pseudoSsh.name = sprintf(pname('p'),'pseudoSsh');
    rho.name       = sprintf(pname('rho'),'rho');
    %%
    pascal2db =@(p) p/(1000*1e2)*10;
    press2h   =@(rho,g,p) p/rho/g;
    land                = geo.full.bathym;
    salt                = (nc_varget(Fsalt,'SALT')*1000 );
    temp                = (nc_varget(Ftemp,'TEMP'));
    ssh                 = nc_varget(Fssh,'SSH')/100; % cm2m
    ssh                 = repmat(permute(ssh,[3,1,2]),[Z,1,1]);
    pseudoSsh.zLevels   = ([0; geo.de(1:end-1)] + geo.de)/2;
    dZ                  = geo.full.depDiff;
    dZ(1,:,:)           = dZ(1,:,:) + ssh(1,:,:); % replace 0's
    rho.data            = nanland(sw_dens(salt,temp,pascal2db(geo.full.Pzero)),land);
    p                   = nanland(cumsum(rho.data.*geo.G.*dZ,1),land);
    pseudoSsh.h         = press2h(1000,9.81,p); % water column equivalent
    %%
    ncOp(pseudoSsh, X,Y,Z);
    ncOp(rho, X,Y,Z);
end
function in=nanland(in,land)
    in(land)=nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ncOp(P,X,Y,Z)
    nc_create_empty(P.name,'clobber');
    nc_adddim(P.name,'i_index',X);
    nc_adddim(P.name,'j_index',Y);
    nc_adddim(P.name,'k_index',Z);
    %%
    FN=fieldnames(rmfield(P,'name'))';
    for ff=1:numel(FN)
        fn = FN{ff};
        switch ndims(P.(fn))
            case 3
                varstruct.Name = fn;
                varstruct.Nctype = 'single';
                varstruct.Dimension = {'k_index','j_index','i_index'};
                nc_addvar(P.name,varstruct);
            case 2
                varstruct.Name = fn;
                varstruct.Nctype = 'single';
                varstruct.Dimension = {'k_index'};
                nc_addvar(P.name,varstruct);
        end
        nc_varput(P.name,fn,single(P.(fn)));
    end
end

