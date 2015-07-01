%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Sep-2014 04:00:00
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% prepare ssh data
% reads user input from input_vars.m and map_vars.m
function S00A_depth2raw
    %% init dependencies
    addpath(genpath('./'))
    %% get user input
    DD = initialise('');
    %%
    DD.path.pseudoSSH.name    = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/pressure/'; % TODO
    DD.path.pseudoSSH.files   = dir2([DD.path.pseudoSSH.name,'pseudoS*.nc']);
    DD.path.pseudoSSH.varname = 'h';
    DD.path.pseudoSSH.latLonDepth.f = '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/LatLonDepth.nc';
    DD.path.pseudoSSH.latLonDepth.data = getLaLoDe(DD.path.pseudoSSH.latLonDepth.f);
    main(DD.path.pseudoSSH,DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = getLaLoDe(lldFile)
    data.lat   = nc_varget(lldFile,'lat');
    data.depth = nc_varget(lldFile,'depth');
    data.lon   = nc_varget(lldFile,'lon');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fname = appendLevel2Name(fname,lev)
    [d,f,x] = fileparts(fname);
    fname   = sprintf('%s/%s_level-%02d%s',d,f,lev,x);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(F,DD)
    %% distro days to threads
    samp    =  nc_varget(F.files(1).fullname,F.varname);
    [Z,Y,X] = size(samp);
    for cc = 1:numel(F.files);
        parforPart(Z,Y,X,F,cc,DD);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function parforPart(Z,Y,X,F,cc,DD)
    currFile.name  = F.files(cc).fullname;
    currFile.data  = nc_varget(currFile.name,F.varname);
    for zz = 1:Z
        if labindex == 1
            fprintf('thread 1: %02d%% at file %d\n',round(zz/Z*100),cc);
        end
        currLevel = opCurrLevel(zz,currFile,F);        
            saveraw(currLevel,X,Y,DD);      
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function currLevel = opCurrLevel(zz,currFile,F)
    antiOffSet = @(d) d/nanmean(d(:));
    currLevel.level = zz;
    currLevel.data  = antiOffSet(squeeze(currFile.data(zz,:,:)));
    currLevel.name  = appendLevel2Name(currFile.name,zz);
    currLevel.lat   = F.latLonDepth.data.lat;
    currLevel.lon   = F.latLonDepth.data.lon;
    currLevel.depth = F.latLonDepth.data.depth(zz);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveraw(cL,X,Y,DD)
    NCoverwriteornot(cL.name);
    nc_adddim(cL.name ,'i_index',X);
    nc_adddim(cL.name ,'j_index',Y);
    nc_adddim(cL.name ,'k_index',1);
    %% lat
    varstruct.Name = DD.map.in.keys.lat;
    varstruct.Nctype = 'single';
    varstruct.Dimension = {'j_index','i_index' };
    nc_addvar(cL.name,varstruct);
    %% lon
    varstruct.Name = DD.map.in.keys.lon;
    varstruct.Nctype = 'single';
    varstruct.Dimension = {'j_index','i_index' };
    nc_addvar(cL.name,varstruct);
    %% ssh
    varstruct.Name = 'pseudoSsh';
    varstruct.Nctype = 'single';
    varstruct.Dimension = {'j_index','i_index' };
    nc_addvar(cL.name,varstruct);
    %% depth
    varstruct.Name = 'depth';
    varstruct.Nctype = 'single';
    varstruct.Dimension = {'k_index'};
    nc_addvar(cL.name,varstruct);
    %% zLevel
    varstruct.Name = 'z';
    varstruct.Nctype = 'single';
    varstruct.Dimension = {'k_index'};
    nc_addvar(cL.name,varstruct);
    %%----------put-----------------
    %%------------------------------
    nc_varput(cL.name, DD.map.in.keys.lat, single(cL.lat));
    nc_varput(cL.name, DD.map.in.keys.lon, single(cL.lon));
    nc_varput(cL.name, 'pseudoSsh', cL.data);
    nc_varput(cL.name, 'depth'    , cL.depth);
    nc_varput(cL.name, 'z'        , cL.level);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%