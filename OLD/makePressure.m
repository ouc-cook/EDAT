function makePressure
    addpath(genpath('../'));
    rootDir='/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/';
    outDir = [rootDir 'pressure/'];
    [geo,files]=getData(rootDir);
    %%
    mkdirp(outDir);
    dbstop if error
    init_threads(12);
    %%
    [Z,Y,X,geo]= inits(geo,files);
    
    T= disp_progress('init','all rhos');
    for ii=1:numel(files.salt)
        %           parfor ii=1:numel(rhoFiles)
        T=    disp_progress('kuguz',T,numel(files.salt));
        %         try
        opDay(files,ii,Y,X,Z,outDir,geo)
        %         catch me
        %             disp(me.message)
        %             continue
        %         end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lalo,files]=getData(rD)
    files.rho = dir2([rD 'rho/rho_*.nc']);
    files.ssh = dir2([rD 'ssh/SSH_*.nc']);
    files.salt = dir2([rD 'salt/SALT_*.nc']);
    files.temp = dir2([rD 'temp/TEMP_*.nc']);
    
    lld=[rD 'LatLonDepth.nc'];
    lalo.la=nc_varget(lld,'lat');
    lalo.lo=nc_varget(lld,'lon');
    lalo.de=nc_varget(lld,'depth');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [Z,Y,X,geo]= inits(geo,files)
    [Y,X]=  size(geo.la);
    [Z]= numel(geo.de) ;
    %5
    disp('dep')
    geo.full.depth = repmat([0; geo.de],[1,Y,X]);
    geo.full.depDiff = diff(geo.full.depth,1,1);
    %%
    disp('lat')
    geo.full.lat   = (permute(repmat(geo.la,[1,1,Z]),[3,1,2]));
    %%
    disp('g')
    ga=@(M) M(:);
    geo.G=(reshape(sw_g(geo.full.lat(:),ga(geo.full.depth(2:end,:,:))),[Z,Y,X]));
    %%
    disp('bathym')
    flag=(nc_varget(files.salt(1).fullname,'SALT'))==0;
    geo.full.bathym=flag;
    
%     [zBottom,xy] = find(abs(diff(salt,1,1))>10);
%     flag=zeros(size(salt));
%     flag(drop_2d_to_1d(zBottom+1,xy,size(salt,1)))=1;
%     flag=reshape(logical(cumsum(flag,1)),[Z,Y,X]);
%     geo.full.bathym=flag;    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function opDay(files,ii,Y,X,Z,outDir,geo)
     anom = @(p) p - repmat(reshape(nanmean(nanmean(p,2),3),size(p(:,1,1))),[size(p(1,:,:))]);
        fillSurfLayer    =  @(d) repmat(d(1,:,:),size(d(:,1,1)));
          pascal2db =@(p) p/(1000*1e2)*10; 
    Fssh = files.ssh(ii).fullname;
    Fsalt = files.salt(ii).fullname;
    Ftemp = files.temp(ii).fullname;
    [~,b,c]=fileparts(Fsalt);
    pname = [outDir '%s_' b(5:end) c];
    P.baroClin.name  = sprintf(pname,'baroClin');
    P.baroTrop.name  = sprintf(pname,'baroTrop');
    P.pseudoSsh.name = sprintf(pname,'pseudoSsh');
    P.rho.name       = sprintf(pname,'rho');   
    %%
    land           = geo.full.bathym; 
    salt         = (nc_varget(Fsalt,'SALT')*1000 );
    temp         = (nc_varget(Ftemp,'TEMP'));
    ssh            = nc_varget(Fssh,'SSH')/100; %cm2m
    ssh            = repmat(permute(ssh,[3,1,2]),[Z,1,1]);
    dD             = geo.full.depDiff;
    G              = geo.G;
 
    %% TODO: put in init  
    FgPerVolZero   = 1000  .* G;     
    P.zero.data    =  FgPerVolZero .* geo.full.depth(2:end,:,:)   ;
    dens   = sw_dens(salt,temp,pascal2db(P.zero.data));
    dens(land)=nan;
    densZero       =fillSurfLayer(dens);
  densZero(land)=nan;
    %%
    FgPerVolSurf = densZero .* G;
    FgPerVol     = dens     .* G;
    FgPerVolAnom = FgPerVol - FgPerVolSurf;
    
    P.baroTrop.data   =         FgPerVolSurf .* ssh      ;
    P.baroClin.data   =  cumsum(FgPerVolAnom .* dD ,1)   ;
    P.prime.data      =  P.baroClin.data - P.baroTrop.data   ;
    
    P.zero.data       =  cumsum(FgPerVolSurf .* dD ,1)   ;
    P.full.data       =  P.baroClin.data + P.baroTrop.data + P.zero.data       ;
    
    
    
    dZ = dD;
    dZ(1,:,:)=dZ(1,:,:) + ssh(1,:,:);
    dZm = (dZ(2:end,:,:) + dZ(1:end-1,:,:))/2  ;
    dZm = dZm([1:end end],:,:);   
    pfu = cumsum(dens.*G.*dZm,1);
    pfu(land)=nan;
  
    
    
    
    
       pp=squeeze(pfu(1:1:42,1000:2000,800))  ;
    
%       pp=(pp - repmat(nanmean(pp,2),1,1001))'
      plot(pp'/1e4)
     
    
       pp=squeeze(pfu(1:1:42,1:100:end,1:100:end))  ;
    
       lla=abs(geo.la(1:100:end,1:100:end));
       lla=lla/nanmax(lla(:))*100;
       lla(lla<1)=1;
       lla(lla>100)=100;
       lla=round(lla);
    
      clf
    
      COL=jet(100);
      clf
      for kk=1:numel(pp)/42
          hold on
      plot(geo.de,pp(:,kk),'color',COL(lla(kk),:))
      end
      grid minor
      colorbar
    
    %
    %
    %
    %    for ii=1:1:round(42/5)
    %       hold on
    %       surf(squeeze(pp(ii,:,:)))
    %    end
    %    view(3)
    %     shading flat
    %
    %
    %
    %
    %
    %
    %
    %
    
    %%
    ncOp(P.baroClin, X,Y,Z,'baroclinic');
    ncOp(P.baroTrop, X,Y,Z,'barotropic');
    ncOp(P.pseudoSsh,X,Y,Z,'waterColumnHeight');
end
function in=nanland(in,land)
    in(land)=nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ncOp(P,X,Y,Z,fn)
    nc_create_empty(P.name,'clobber');
    nc_adddim(P.name,'i_index',X);
    nc_adddim(P.name,'j_index',Y);
    nc_adddim(P.name,'k_index',Z);
    %%
    varstruct.Name = fn;
    varstruct.Nctype = 'single';
    varstruct.Dimension = {'k_index','j_index','i_index' };
    nc_addvar(P.name,varstruct);
    %%
    nc_varput(P.name,fn,single(P.data));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S=dir2(d)
    S=dir(d);
    [base,~,~]=fileparts(d);
    for ii=1:numel(S)
        S(ii).fullname=[base '/' S(ii).name];
    end
end
