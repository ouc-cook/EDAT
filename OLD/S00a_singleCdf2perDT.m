%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 25-Apr-2014 12:01:45
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Madeleine Version
function S00a_singleCdf2perDT
warning('off','MATLAB:mir_warning_unrecognized_pragma')
    %% init dependencies
    addpath(genpath('./'));
    %% get user input
    DD = initialise([],mfilename);
   warning('off','MATLAB:DELETE:FileNotFound'); delete([DD.path.root,'DD.mat']); % full reboot
    DD = initialise([],mfilename);
    %% get madeleine's data
    [raw]=cdfData(DD);
    %% get geo stuff
    [DD,raw]=geostuff(raw,DD);
    %% thread distro
    DD.threads.lims=thread_distro(DD.threads.num,DD.time.span/DD.time.delta_t);
    %% start threads
    init_threads(DD.threads.num);
    %% spmd
    main(DD,raw)
    %% save brunt väisälä
    saveN(DD,raw);
    %% save UV
    try
    saveUV(DD,raw);
    end
    %% save info
    conclude(DD,0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,raw)
    if DD.debugmode
        spmd_body(DD,raw);
    else
        spmd(DD.threads.num)
            spmd_body(DD,raw);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(DD,raw)
    CC=(DD.threads.lims(labindex,1):DD.threads.lims(labindex,2));
    %% loop over files
    [T]=disp_progress('init','preparing raw data');
    for cc=CC
        [T]=disp_progress('calc',T,numel(CC),5);
        %% get current SSH
        raw.grids.ssh=squeeze(nc_varget(raw.file.in,DD.map.in.keys.ssh,[cc-1,raw.SSHzIdx-1,0,0],[1,1,inf,inf]));		 
        %% append 'zonal wings'           
        raw.grids.ssh=raw.grids.ssh(:,raw.wingIdx);
        %% op day
        operateDay(raw,DD,cc);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [raw]=cdfData(DD)
    raw.file.in=[DD.path.raw.name	,DD.map.in.cdfName];
    try  %#ok<TRYNC>
        raw.info=ncInfoAll(raw.file.in);
        for info=fieldnames(raw.info)'; disp(raw.info.(info{1})); end
    end
    disp(['setting user start date - ' DD.time.from.str ' - as start date!'])
    startTime=DD.time.from.num;
    keys=DD.map.in.keys;
    raw.(keys.time)=nc_varget(raw.file.in,keys.time);
    raw.(keys.time)=raw.(keys.time)-raw.(keys.time)(1)+startTime;
    raw.(keys.x)=nc_varget(raw.file.in,keys.x);
    raw.(keys.y)=nc_varget(raw.file.in,keys.y);
    raw.(keys.z)=nc_varget(raw.file.in,keys.z);
    [~,raw.SSHzIdx]=min(abs(raw.ZT-DD.parameters.SSHAdepth));
    %% append zonal wings to x distance vector
    [raw.(keys.x), raw.wingIdx]=nonZonCont(raw.(keys.x));   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [rx, idx]=nonZonCont(rx)
    X=length(rx);
    idx=[ (1:X)  ];    
    rx=reshape(rx(idx),size(idx));  
end

function [rx, idx]=AppenZonWingToX(rx) %#ok<DEFNU>
    % take $rx(Xhalf+1:end); append it to $rx(-Xhalf:0); shift the
    % values of that piece down by $edgeValue; append $rx(1:Xhalf) to the end of
    % the new $rx(end+1:Xhalf); shift that piece's values up by $edgeValue
    X=length(rx);
    Xhalf=floor(X/2);  
    ii.east = (X-Xhalf+1:X) ;
    ii.west = (1:Xhalf)   ;
    idx=[ii.east   (1:X)     ii.west];
    %% summand
    su=zeros(size(idx));
    edgeValue=repmat(rx(end)+diff(rx(end-1:end)), 1,  Xhalf);
    su(ii.west)       = - edgeValue; 
    su(ii.east + X)       =   edgeValue; 
    %% cat &   correct  
    rx=reshape(rx(idx),size(idx)) + su;  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD,raw]=geostuff(raw,DD)
    [raw.grids.XX,raw.grids.YY]=meshgrid(raw.XT,raw.YT);
    raw.grids.lat=rad2deg(raw.grids.YY./earthRadius) + DD.parameters.boxlims.south;
    raw.grids.lon=rad2deg(raw.grids.XX./(cosd(raw.grids.lat)*earthRadius)) +  0; %%  + boxlims.west
    if max(diff(raw.grids.lon(:)))>300, error('dont put window on -180/180 meridian!'); end %#ok<ERTAG>
    [raw.grids.DY,raw.grids.DX]=DYDX(raw.grids.lat,raw.grids.lon);
    %% reset to exact values
    DD.map.in.west=min(raw.grids.lon(:));
    DD.map.in.east=max(raw.grids.lon(:));
    DD.map.in.south=min(raw.grids.lat(:));
    DD.map.in.north=max(raw.grids.lat(:));
    %% reset out maps
    DD.map.out.west=0;
    DD.map.out.east=ceil((DD.map.in.east-DD.map.in.west+1)/2);
    DD.map.out.south=floor(DD.map.in.south);
    DD.map.out.north=ceil(DD.map.in.north);
    %% use full map
    [Y,X]=size(raw.grids.lon);
    DD.map.window.size.X=X;
    DD.map.window.size.Y=Y;
    DD.map.window.limits.west=1;
    DD.map.window.limits.east=X;
    DD.map.window.limits.south=1;
    DD.map.window.limits.north=Y;
    DD.map.window.size.Z=numel(raw.ZT);  
    %% info
    mapInfo(Y,X,DD.map.in,DD.map.out)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function mapInfo(Y,X,map,mapout)
    fprintf('\n built %ix%i grid \n',Y,X)
    fprintf('       spanning %5.1fW : %5.1fE and %5.1fS : %5.1fN \n',map.west,map.east,map.south,map.north)
    fprintf('output spanning %5.0fW : %5.0fE and %5.0fS : %5.0fN \n\n',mapout.west,mapout.east,mapout.south,mapout.north)
    sleep(1)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveraw(DD,raw)
    NCoverwriteornot(raw.file.out);
    nc_adddim(raw.file.out,'i_index',DD.map.window.size.X);
    nc_adddim(raw.file.out,'j_index',DD.map.window.size.Y);
    %% lat
    varstruct.Name = DD.map.in.keys.lat;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'j_index','i_index' };
    nc_addvar(raw.file.out,varstruct);
    %% lon
    varstruct.Name = DD.map.in.keys.lon;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'j_index','i_index' };
    nc_addvar(raw.file.out,varstruct);
    %% ssh
    varstruct.Name = DD.map.in.keys.ssh;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'j_index','i_index' };
    nc_addvar(raw.file.out,varstruct);
    %%----------put-----------------
    %%------------------------------
    nc_varput(raw.file.out,DD.map.in.keys.lat,raw.grids.lat);
    nc_varput(raw.file.out,DD.map.in.keys.lon,raw.grids.lon);
    nc_varput(raw.file.out,DD.map.in.keys.ssh,raw.grids.ssh);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function operateDay(raw,DD,cc)
    %% set up output file
    tt=raw.TIME(cc);
    timestr=datestr(tt,'yyyymmdd');
    path=DD.path.raw.name;
    fo=DD.map.in.fname;
    fo=strrep(fo,'yyyymmdd',timestr);
    raw.file.out=[path, fo];
    if exist(raw.file.out,'file'), return; end
    %% smooth out dummy values and nans
    foulIdx=(raw.grids.ssh>1000 | raw.grids.ssh<-1000 | isnan(raw.grids.ssh));
    raw.grids.ssh=double(NeighbourValue(foulIdx, raw.grids.ssh));
    %%
    saveraw(DD,raw);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DY,DX]=DYDX(LAT,LON)
    %% grid increment sizes
    DY=deg2rad(abs(diff(double(LAT),1,1)))*earthRadius;
    DX=deg2rad(abs(diff(double(LON),1,2)))*earthRadius.*cosd(LAT(:,1:end-1));
    %% append one line/row to have identical size as other fields
    DY=DY([1:end,end],:);
    DX=DX(:,[1:end,end]);
    %% correct 360° crossings
    seamcrossflag=DX>100*median(DX(:));
    DX(seamcrossflag)=abs(DX(seamcrossflag) - 2*pi*earthRadius.*cosd(LAT(seamcrossflag)));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveUV(DD,raw)
    %%
    [U,V]=getUV(raw,DD.path.raw.name,DD.map.in.keys);
    %%
    [S]=prepUVfile(U,V,DD);
    %%
    writeUVfile(U,V,S,raw);
    %-----------------------------------------------------------------------
    %-----------------------------------------------------------------------
    function writeUVfile(U,V,S,raw)
        %% UV
        nc_varput(U.file,S.U.Name,U.data);
        nc_varput(V.file,S.V.Name,V.data);
        %% z
        nc_varput(U.file,S.Z.Name,raw.(S.Z.Name));
        nc_varput(V.file,S.Z.Name,raw.(S.Z.Name));
        %% lon lat
        for ll={'lon','lat'};l=ll{1};
            nc_varput(U.file,S.L.(l).Name,raw.grids.(l));
            nc_varput(V.file,S.L.(l).Name,raw.grids.(l));
        end
    end
    %-----------------------------------------------------------------------
    function [S]=prepUVfile(U,V,DD)
        NCoverwriteornot(U.file);
        NCoverwriteornot(V.file);
        nc_adddim(U.file,'i_index',DD.map.window.size.X);
        nc_adddim(U.file,'j_index',DD.map.window.size.Y);
        nc_adddim(U.file,'k_index',DD.map.window.size.Z);
        nc_adddim(U.file,'voiddim',1);
        nc_adddim(V.file,'i_index',DD.map.window.size.X);
        nc_adddim(V.file,'j_index',DD.map.window.size.Y);
        nc_adddim(V.file,'k_index',DD.map.window.size.Z);
        nc_adddim(V.file,'voiddim',1);
        %% U
        S.U.Name = DD.map.in.keys.U;
        S.U.Nctype = 'double';
        S.U.Dimension = {'voiddim','k_index','j_index','i_index' };
        nc_addvar(U.file,S.U);
        %% V
        S.V.Name = DD.map.in.keys.V;
        S.V.Nctype = 'double';
        S.V.Dimension = {'voiddim','k_index','j_index','i_index' };
        nc_addvar(V.file,S.V);
        %% lat/lon
        for ll={'lon','lat'};l=ll{1};
            S.L.(l).Name = DD.map.in.keys.(l);
            S.L.(l).Nctype = 'double';
            S.L.(l).Dimension = {'j_index','i_index' };
            nc_addvar(U.file,S.L.(l));
            nc_addvar(V.file,S.L.(l));
        end
        %% Z
        S.Z.Name = DD.map.in.keys.z;
        S.Z.Nctype = 'double';
        S.Z.Dimension = {'k_index'};
        nc_addvar(U.file,S.Z);
        nc_addvar(V.file,S.Z);
    end
    %-----------------------------------------------------------------------
    function [U,V]=getUV(raw,rawpath,keys)
        u=nc_varget(raw.file.in,keys.U);
        v=nc_varget(raw.file.in,keys.V);

        u=u(:,:,raw.wingIdx);v=v(:,:,raw.wingIdx);
        [z,y,x]=size(u);
        U.data=reshape(u,1,z,y,x);
        V.data=reshape(v,1,z,y,x);
        U.file=[rawpath	'UVEL.nc'];
        V.file=[rawpath 'VVEL.nc'];
    end
    %-----------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveN(DD,raw)
    Nin=sqrt(abs(double(squeeze(nc_varget(raw.file.in,DD.map.in.keys.N,[0 0 0 0],[1 inf inf inf])))));  % N IST NEGATIV IN DEN DATEN??
    Nin(:,1:2,:)=repmat(Nin(:,3,:),[1,2,1]) ;
    Nin(:,end-1:end,:)=repmat(Nin(:,end-3,:),[1,2,1]);
    Nin(:,:,1:2)=repmat(Nin(:,:,3),[1,1,2]) ;
    Nin(:,:,end-1:end)=repmat(Nin(:,:,end-3),[1,1,2]);    % WARUM NANS AM RAND?
    N=Nin(:,:,raw.wingIdx);
    Nfile=DD.path.Rossby.Nfile;
    NCoverwriteornot(Nfile);
    nc_adddim(Nfile,'i_index',DD.map.window.size.X);
    nc_adddim(Nfile,'j_index',DD.map.window.size.Y);
    nc_adddim(Nfile,'k_index',DD.map.window.size.Z);
    %% N
    varstruct.Name = DD.map.in.keys.N;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'k_index','j_index','i_index' };
    nc_addvar(Nfile,varstruct);
    nc_varput(Nfile,varstruct.Name,N);
    %% lat/lon
    for ll={'lon','lat'}
        varstruct.Name = DD.map.in.keys.(ll{1});
        varstruct.Nctype = 'double';
        varstruct.Dimension = {'j_index','i_index' };
        nc_addvar(Nfile,varstruct);
        nc_varput(Nfile,DD.map.in.keys.(ll{1}),raw.grids.(ll{1}));
    end
    %% Z
    varstruct.Name = DD.map.in.keys.z;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'k_index'};
    nc_addvar(Nfile,varstruct);
    nc_varput(Nfile,varstruct.Name,raw.(DD.map.in.keys.z));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
