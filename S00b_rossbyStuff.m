% TODO test for global
% TODO test for aviso
% TODO comment
% needs one 3D salt and temperature file each
% integrates over depth to calculate
% -Brunt Väisälä frequency
% -Rossby Radius
% -Rossby wave first baroclinic phase speed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S00b_rossbyStuff
    %% init
    DD = initialise([]);
    save DD
    % load DD
    %% set up
    TS = S00b_rossbyStuff_setUp(DD);  
    %% spmd
    main(TS,DD)
    %% make netcdf
    WriteMatFile(DD,TS);    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(TS,DD)
    spmd(DD.threads.num)
        spmd_body(TS);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(TS)
    id = labindex;
    lims = TS.lims.threads;
    %% loop over chunks
    for cc = lims(id,1):lims(id,2)
        Calculations(TS,cc);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CK: current chunk
function Calculations(TS,cc)
    %% pre-init
    [CK,ccStr] = initPre(TS,cc,TS.dir);
    %% init
    CK = initChunK(CK,TS,cc);
    %% calculate Brunt-Väisälä f and potential vorticity
    [CK.N]=calcBrvaPvort(CK,ccStr);
    %% integrate first baroclinic rossby radius
    [CK.rossby.(CK.R1Fname)]=calcRossbyRadius(CK,ccStr);
    %% rossby wave phase speed
    [CK.rossby.(CK.c1Fname)]=calcC_one(CK,ccStr);
    %% clean infs
    CK.N=inf2nan(CK.N);
    for fn=fieldnames(CK.rossby)'
        CK.rossby.(fn{1}) = inf2nan(CK.rossby.(fn{1})) ;
    end
    %% save
    saveChunk(CK);
end
function M=inf2nan(M)
    M(isinf(M))=nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CK,ccStr]=initPre(TS,cc,RossbyDir)
    lims = TS.lims.chunks  - 1; % 1: to 0: system
    ccStr=[sprintf(['%0',num2str(length(num2str(size(lims,1)))),'i'],cc),'/',num2str(size(lims,1))];
    CK.fileSelf=[RossbyDir,'rossby_',sprintf('%03d',cc),'.mat'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check whether TS data has different geometry from ssh data. eg to use pop
% rossby stuff for aviso data.
function [reallocIdx,oriData] = InitWriteMatFile(DD,TS)
    oriData = load(DD.path.windowFile);
    reallocIdx=false;
    if any(struct2array(oriData.window.fullsize)~=struct2array(TS.window.fullsize))
        reallocIdx = true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function WriteMatFile(DD,TS)
    [TS.reallocIdx, oriData] = InitWriteMatFile(DD,TS)  ;
    %% loop fields
    FF={'phaseSpeed';'radius'};
    for cc = 1:2
        %% fieldname / fileout name
        FN=TS.keys.(FF{cc});
        MATfileName=[DD.path.Rossby.name FN '.mat'];      
        saveField(TS,FN,MATfileName, oriData.window)
    end   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveField(TS,FN,MATfileName,oriWindow)
    %% start from scratch
    %% dummy init
    data = nan([TS.window.dimPlus.y, TS.window.dimPlus.x]);   %#ok<NASGU>
    save(MATfileName,'data','-v7.3');
    MATfile = matfile(MATfileName,'Writable',true);
    %% loop chunks
    for cc = 1:TS.numChunks
        CKfn = getfield(loadChunk(TS.dir,cc,'rossby'),FN);
        lat  = loadChunk(TS.dir,cc,'lat');
        lon  = loadChunk(TS.dir,cc,'lon');
        newDim = getfield(loadChunk(TS.dir,cc,'dim'),'new');
        yylims = newDim.start(1):newDim.start(1) + newDim.len(1) -1;
        xxlims = newDim.start(2):newDim.start(2) + newDim.len(2) -1;
        MATfile.data(yylims+1,xxlims+1)= CKfn;
        MATfile.lon(yylims+1,xxlims+1) =  wrapTo360(lon);
        MATfile.lat(yylims+1,xxlims+1) = lat;
    end
    %%
    if TS.reallocIdx
        disp('cross-polating data to different geometry')
        differentGeoCase(TS,MATfileName,oriWindow);
    else
        %% the global case is automatically taken care of in the differentGeoCase
        if strcmp(TS.window.type,'globe')
            globalCase(MATfileName,oriWindow);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function differentGeoCase(TS,MATfileName,oriWindow)
    %% in
    lims = TS.window.limits;
    getFlag=@(lims,M) double(M(lims.south:lims.north,lims.west:lims.east));
    %%
    in.lat = getFlag(lims,ncreadOrNc_varget(TS.salt{1},TS.keys.lat,[1 1],[inf inf]));
    in.lon = getFlag(lims,ncreadOrNc_varget(TS.salt{1},TS.keys.lon,[1 1],[inf inf]));
    %%
    fieldLoad=@(field)  double(getfield(load(MATfileName,field),field));
    in.data = fieldLoad('data');
    in.lon  = fieldLoad('lon');
    in.lat  = fieldLoad('lat');
    %% out
    out.lat = oriWindow.lat;
    out.lon = oriWindow.lon;
    %% resample
    data=griddata(in.lon,in.lat,in.data,out.lon,out.lat); %#ok<NASGU>
    %% save
    save(MATfileName,'data');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function globalCase(MATfileName,oriWindow)
    %% zonal append overlap
    data     = getfield(load(MATfileName,'data'),'data');
    YindxMap = oriWindow.iy-min(oriWindow.iy(:))+1;
    XindxMap = oriWindow.ix;
    ovrlpIyx = drop_2d_to_1d(YindxMap,XindxMap,size(oriWindow.iy,1));
    data     = data(ovrlpIyx); %#ok<NASGU>
    %% save
    save(MATfileName,'data','-v7.3');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveChunk(CK)
    save(CK.fileSelf,'-struct','CK');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CK=loadChunk(RossbyDir,cc,field)
    file_in=[RossbyDir,'rossby_',sprintf('%03d',cc),'.mat'];
    CK=getfield(load(file_in,field),field);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Lr=	calcRossbyRadius(CK,ccStr)
    dispM(['integrating Rossby Radius for chunk ',ccStr],1)
    [~,YY,XX]=size(CK.N);
    M.depthdiff=repmat(diff(CK.DEPTH),[1 YY XX]);
    % R = 1/(pi f) int N dz
    Lr=abs(double((squeeze(nansum(M.depthdiff.*CK.N,1))./CK.rossby.f)/pi));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [c1]=calcC_one(CK,ccStr)
    %    c=-beta/(k^2+(1/L_r)^2) approx -beta*L^2
    dispM(['applying long rossby wave disp rel for c1 for chunk ',ccStr])
    c1=-CK.rossby.beta.*CK.rossby.(CK.R1Fname).^2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [N]=calcBrvaPvort(CK,ccStr)
    [ZZ,YY,XX]=size(CK.TEMP);
    dispM(['calculating brunt väisälä, chunk ',ccStr]);
    %% get full matrices for all variables
    M.depth=double(repmat(CK.DEPTH,[1,YY*XX]));
    M.lat=double(repmat(permute(CK.lat(:),[2 1]), [ZZ,1]));
    M.pressure=double(reshape(sw_pres(M.depth(:),M.lat(:)),[ZZ,YY*XX]));
    M.salt=double(reshape(CK.SALT,[ZZ,YY*XX]));
    M.temp=double(reshape(CK.TEMP,[ZZ,YY*XX]));
    %% get brunt väisälä frequency and pot vort
    [brva,~,~]=sw_bfrq(M.salt,M.temp,M.pressure,M.lat);
    brva(brva<0)=nan;
    N=sqrt(reshape(brva,[ZZ-1,YY,XX]));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CK]=initChunK(CK,TS,chunkNum)
    CK.c1Fname = TS.keys.phaseSpeed;  % first long rossby wave phase speed
    CK.R1Fname = TS.keys.radius;      % first Rossby radius
    CK.chunk = chunkNum;
    CK.dim   = ncArrayDims(TS,chunkNum);
    disp('getting temperature..')
    CK.TEMP = ChunkTempOrSalt(TS,CK.dim,'temp','TEMP',1);
    disp('getting salt..')
    CK.SALT = ChunkTempOrSalt(TS,CK.dim,'salt','SALT',TS.salinityFactor);
    disp('getting depth..')
    CK.DEPTH=ChunkDepth(TS);
    disp('getting geo info..')
    [CK.lat,CK.lon]=ChunkLatLon(TS,CK.dim);
    disp('getting coriolis stuff..')
    [CK.rossby]=ChunkRossby(CK);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [rossby]=ChunkRossby(CK)
    day_sid=23.9344696*60*60;
    om=2*pi/(day_sid); % frequency earth
    rossby.f=2*om*sind(CK.lat);
    rossby.beta=2*om/earthRadius*cosd(CK.lat);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lat,lon]=ChunkLatLon(TS,dim)
    lat = ncreadOrNc_varget(TS.temp{1},TS.keys.lat,dim.start1d, dim.len1d);
    lon = ncreadOrNc_varget(TS.temp{1},TS.keys.lon,dim.start1d, dim.len1d);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function depth=ChunkDepth(TS)
    depth=ncreadOrNc_varget(TS.salt{1},TS.keys.depth);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = ChunkTempOrSalt(TS,dim,fieldA,fieldB,fac)
    num = numel(TS.(fieldA));
    out = (1/num) * squeeze(ncreadOrNc_varget(TS.(fieldA){1},fieldB,dim.start2d,dim.len2d));
    for tt=2:num
        tmp=(1/num) * squeeze(ncreadOrNc_varget(TS.(fieldA){tt},fieldB,dim.start2d,dim.len2d));
        out = out + tmp;
    end
    out(out==0)=nan;
    out = out * fac;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dim=ncArrayDims(TS,cc)
    lims        = TS.lims.chunks;
    j_indx_start= TS.window.limits.south-1;
    j_len       = TS.window.dim.y;
    dim.start2d = [0 0 j_indx_start lims(cc,1)-1];
    dim.len2d   = [inf inf j_len diff(lims(cc,:))+1];
    dim.start1d = [j_indx_start lims(cc,1)-1];
    dim.len1d   = [j_len diff(lims(cc,:))+1];
    %% new indeces for output nc file
    xlens            = diff(lims,1,2)+1;
    xlens(xlens<0)   = xlens(xlens<0) + TS.window.fullsize.x;
    newxstart        = sum(xlens(1:cc-1));
    dim.new.start    = [0 newxstart];
    dim.new.len      = dim.len1d;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


