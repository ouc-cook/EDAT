%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DD=maxOWsetUp(DD)
    %% threads
    DD.threads.num=init_threads(DD.threads.num);
    %% find temp and salt files
    [DD.path.TSow]=DataInit(DD);
    %% get window according to user input
    DD.TSow.window.size(2:3)=getfield(getfield(load([DD.path.root 'window']),'window'),'fullsize');
    %% get z info
    DD.TSow.window=mergeStruct2(DD.TSow.window, GetFields(DD.path.TSow.files(1).salt, cell2struct({DD.TS.keys.depth},'depth')));
    DD.TSow.window.size(1)=numel(DD.TSow.window.depth);
    %%
    DD.path.TSow=appendFields(DD.path.TSow,Data2Init(DD));
    %% distro time steps to threads
    DD.TSow.lims.inTime=thread_distro(DD.threads.num,numel(DD.path.TSow.files));
    DD.TSow.lims.timesteps=1:numel(DD.path.TSow.files);
    DD.TSow.lims.inZ=thread_distro(DD.threads.num,DD.TSow.window.size(1));
   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out]=DataInit(DD)
    %% find the temp and salt files
    DirIn=dir([DD.path.full3d.name '*.nc'])   ;
    tt=0;ss=0;
    for kk=1:numel(DirIn);
        if ~isempty(strfind(upper(DirIn(kk).name),DD.TS.keys.salt))
            ss=ss+1;
            out.files(ss).salt=[DD.path.full3d.name DirIn(kk).name];
            
        end
        if ~isempty(strfind(upper(DirIn(kk).name),DD.TS.keys.temp))
            tt=tt+1;
            out.files(tt).temp=[DD.path.full3d.name DirIn(kk).name];
        end
    end
    out.fnum=numel(out.files);
    out.dir   = [DD.path.Rossby.name];
    out.dailyOWName   = [ out.dir 'OW_'];
    out.dailyRhoName   = [ out.dir 'rho_'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [out]=Data2Init(DD)
    TSow=DD.path.TSow;
    dim=DD.TSow.window.size;
    out.geo=initNcGeoInfo(dim,TSow.dir);
    parfor tt=1:TSow.fnum
        fprintf('init NC file %2d of %2d\n',tt,TSow.fnum); %#ok<PFBNS>
        [rho(tt),OW(tt)]=parInitNcs(tt,TSow);
    end
    out.rho=rho;
    out.OW=OW;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rho, OW]=parInitNcs(tt,TSow)
    rho={initNcFile(tt,TSow.dailyRhoName)};
    OW={initNcFile(tt,TSow.dailyOWName)};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fname=initNcGeoInfo(WinSize,ds)
    fname=[ds  'LatLonDepth.nc' ];
    try
        nc_create_empty(fname,'noclobber');
        nc_adddim(fname,'i_index',WinSize(3));
        nc_adddim(fname,'j_index',WinSize(2));
        nc_adddim(fname,'k_index',WinSize(1));
        %% depth
        varstruct.Name = 'depth';
        varstruct.Nctype = 'double';
        varstruct.Dimension ={'k_index'};
        nc_addvar(fname,varstruct)
        %% lat
        varstruct.Name = 'lat';
        varstruct.Nctype = 'double';
        varstruct.Dimension ={'j_index','i_index' };
        nc_addvar(fname,varstruct)
        %% lon
        varstruct.Name = 'lon';
        varstruct.Nctype = 'double';
        varstruct.Dimension ={'j_index','i_index' };
        nc_addvar(fname,varstruct)
    catch
        disp([fname 'exists'])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fname=initNcFile(ff,ds)
    fname=[ds sprintf('%04d.nc',ff) ];
end
