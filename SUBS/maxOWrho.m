%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 16-Jul-2014 13:52:44
% Computer:GLNX86
% Matlab:7.9
% Author:NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxOWrho
    load DD
    DD.MD=main(DD,DD.raw,DD.Dim,DD.f); %#ok<NODEF>
    save DD
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [MD]=main(DD,raw,Dim,f)
    [MD]=initbuildRho(DD);
    buildRho(MD,raw,Dim,DD.threads.num,f) ;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s] = initbuildRho(DD);  dF
    s.timesteps= DD.TSow.lims.timesteps;
    s.keys = DD.TS.keys;
    s.Fin = DD.path.TSow.files;
    s.dirOut=DD.path.full3d.name;
    s.Fout=DD.path.TSow.rho;
    s.OWFout=DD.path.TSow.OW;
    s.geoOut=DD.path.TSow.geo;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buildRho(s,raw,Dim,threads,f);    dF
    [depth,lat,T]=spmdInit(threads,raw,Dim,f);
    %%
    for tt = s.timesteps
       T=disp_progress('show',T,numel(s.timesteps),numel(s.timesteps))  ;
%         if ~exist(s.Fout{tt},'file')
            [RHO]=spmdBlock(threads,tt,s,f,depth,lat);
            initNcFile([s.Fout{tt} 'temp'],'density',Dim.ws);
            f.ncvp([s.Fout{tt} 'temp'],'density',f.mDit(RHO{1},Dim.ws),[0 0 0], [Dim.ws]);
            system(['mv ' s.Fout{tt} 'temp '  s.Fout{tt}]);
%         end
    end
end
function [RHO]=spmdBlock(threads,tt,s,f,depth,lat)  
  spmd(threads)       
        RHO=makeRho(s.Fin(tt),depth,lat,s.keys,f)	;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [depth,lat,T]=spmdInit(threads,raw,Dim,f)
    spmd(threads)
        depth = f.locCo(repmat(double(raw.depth),Dim.ws(2)*Dim.ws(3),1));
        lat = f.locCo(f.yx2zyx(raw.lat,Dim.ws(1)));       
    end
     T=disp_progress('init','building density netcdfs')  ;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function RHO=makeRho(file,depth,lat,keys,f)
    [temp,salt]=TSget(file,keys,f.locCo);
    pres=f.oneDit(sw_pres(depth,lat));
    RHO=Rhoget(salt,temp,pres);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function R=Rhoget(salt,temp,pres)
    rho = sw_dens(salt,temp,pres);
    rho(abs(rho>1e10) | rho==0)=nan;
    R=gop(@vertcat, rho,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [T,S]=TSget(FileIn,keys,locCo)
    T= locCo(nc_varget(FileIn.temp,keys.temp));
    S= locCo(nc_varget(FileIn.salt,keys.salt)*1000);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initNcFile(fname,toAdd,WinSize)
    nc_create_empty(fname,'noclobber');
    nc_adddim(fname,'k_index',WinSize(1));
    nc_adddim(fname,'i_index',WinSize(3));
    nc_adddim(fname,'j_index',WinSize(2));
    %%
    varstruct.Name = toAdd;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'k_index','j_index','i_index' };
    nc_addvar(fname,varstruct)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
