%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% needs one 3D salt and temperature file each.open IN
% integrates over depth to calculate
% -Brunt Väisälä frequency
% -Rossby Radius
% -Rossby wave first baroclinic phase speed

function S01b_fromTS
    %% set up
    [DD]=S01b_ST_set_up;
     DD.map.window = getfieldload(DD.path.windowFile,'window');
    %% spmd
    main(DD)
    %% make netcdf
    WriteMatFile(DD);
    %% update DD
    save_info(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    if DD.debugmode
        spmd_body(DD);
    else
        spmd(DD.threads.num)
            spmd_body(DD);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(DD)
    id=labindex;
    lims=DD.RossbyStuff.lims;
    %% loop over chunks
    for cc=lims.loop(id,1):lims.loop(id,2)
        Calculations(DD,cc);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Calculations(DD,cc)
    %% pre-init
    [CK,ccStr]=initPre(DD,cc,DD.path.Rossby.name);
    if exist(CK.fileSelf,'file') && ~DD.overwrite, return;end
    %% init
    CK=initChunK(CK,DD,cc);
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
function [CK,ccStr]=initPre(DD,cc,RossbyDir)
    lims = DD.RossbyStuff.lims.dataIn  - 1; % 1: to 0: system
    ccStr=[sprintf(['%0',num2str(length(num2str(size(lims,1)))),'i'],cc),'/',num2str(size(lims,1))];
    disp('initialising..')
    CK.fileSelf=[RossbyDir,'BVRf_',sprintf('%03d',cc),'.mat'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD]=InitWriteMatFile(DD)
    DD.reallocIdx=false;
    DD.splits=DD.parameters.RossbySplits;
    if any(struct2array(DD.map.window.fullsize)~=struct2array(DD.TS.window.fullsize))
        DD.reallocIdx=true;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function WriteMatFile(DD)
    [DD]=InitWriteMatFile(DD)  ;
    %% loop fields
    for ff=1:numel(DD.FieldKeys.Rossby)
        %% fieldname / fileout name
        FN=DD.FieldKeys.Rossby{ff} ;
        MATfileName=[DD.path.Rossby.name FN '.mat'];
        saveField(DD,FN,MATfileName)
    end
    
    
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveField(DD,FN,MATfileName)
    %% start from scratch
    %% dummy init
    data=nan([DD.TS.window.dimPlus.y, DD.TS.window.dimPlus.x]);   %#ok<NASGU>
    save(MATfileName,'data','-v7.3');
    MATfile=matfile(MATfileName,'Writable',true);
    %% loop chunks
    for cc=1:DD.splits
        CKfn=getfield(loadChunk(DD.path.Rossby.name,cc,'rossby'),FN);
        lat=loadChunk(DD.path.Rossby.name,cc,'lat');
        lon=loadChunk(DD.path.Rossby.name,cc,'lon');
        newDim=getfield(loadChunk(DD.path.Rossby.name,cc,'dim'),'new');
        yylims=newDim.start(1):newDim.start(1) + newDim.len(1) -1;
        xxlims=newDim.start(2):newDim.start(2) + newDim.len(2) -1;
        MATfile.data(yylims+1,xxlims+1)=CKfn;
        MATfile.lon(yylims+1,xxlims+1)= wrapTo360(lon);
        MATfile.lat(yylims+1,xxlims+1)=lat;
    end
    %%
    if DD.reallocIdx
        disp('cross-polating data to different geometry')
        differentGeoCase(DD,MATfileName);
    else
        %% the global case is automatically taken care of in the differentGeoCase
        if strcmp(DD.map.window.type,'globe')
            globalCase(DD,MATfileName);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function differentGeoCase(DD,MATfileName)
    %% in
    lims=  DD.TS.window.limits;
    getFlag=@(lims,M) double(M(lims.south:lims.north,lims.west:lims.east));
    %%
    in.lat=getFlag(lims,ncreadOrNc_varget(DD.path.TempSalt.salt{1},DD.TS.keys.lat,[1 1],[inf inf]));
    in.lon=getFlag(lims,ncreadOrNc_varget(DD.path.TempSalt.salt{1},DD.TS.keys.lon,[1 1],[inf inf]));
    %%
    fieldLoad=@(field)  double(getfield(load(MATfileName,field),field));
    in.data=fieldLoad('data');
    in.lon=fieldLoad('lon');
    in.lat=fieldLoad('lat');
    %% out
    Y= DD.map.window.dim.y;
    out.lat=reshape(extractdeepfield(load([DD.path.cuts.name DD.path.cuts.files(1).name]),'fields.lat'),Y,[]);
    out.lon=reshape(extractdeepfield(load([DD.path.cuts.name DD.path.cuts.files(1).name]),'fields.lon'),Y,[]);
    %% resample
    data=griddata(in.lon,in.lat,in.data,out.lon,out.lat); %#ok<NASGU>
    %% save
    save(MATfileName,'data');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function globalCase(DD,MATfileName)
    %% zonal append
    data=getfield(load(MATfileName,'data'),'data');
    wndw=getfield(load(DD.path.windowFile),'window');
    YindxMap=wndw.iy-min(wndw.iy(:))+1;
    XindxMap=wndw.ix;
    ovrlpIyx=drop_2d_to_1d(YindxMap,XindxMap,size(wndw.iy,1));
    data=data(ovrlpIyx); %#ok<NASGU>
    %% save
    save(MATfileName,'data','-v7.3');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveChunk(CK)
    save(CK.fileSelf,'-struct','CK');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function CK=loadChunk(RossbyDir,cc,field)
    file_in=[RossbyDir,'BVRf_',sprintf('%03d',cc),'.mat'];
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
function [CK]=initChunK(CK,DD,chunk)
    CK.c1Fname=DD.FieldKeys.Rossby{1};
    CK.R1Fname=DD.FieldKeys.Rossby{2};
    CK.chunk=chunk;
    CK.dim=ncArrayDims(DD,chunk);
    %     CK.dim=ncArrayDims(DD,12);
    disp('getting temperature..')
    CK.TEMP=ChunkTemp(DD,CK.dim);
    disp('getting salt..')
    CK.SALT=ChunkSalt(DD,CK.dim);
    disp('getting depth..')
    CK.DEPTH=ChunkDepth(DD);
    disp('getting geo info..')
    [CK.lat,CK.lon]=ChunkLatLon(DD,CK.dim);
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
function [lat,lon]=ChunkLatLon(DD,dim)
    lat = ncreadOrNc_varget(DD.path.TempSalt.temp{1},DD.TS.keys.lat,dim.start1d, dim.len1d);
    lon = ncreadOrNc_varget(DD.path.TempSalt.temp{1},DD.TS.keys.lon,dim.start1d, dim.len1d);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function depth=ChunkDepth(DD)
    depth=ncreadOrNc_varget(DD.path.TempSalt.salt{1},'depth_t');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function salt=ChunkSalt(DD,dim)
    num=numel(DD.path.TempSalt.salt);
    salt=(1/num) * squeeze(ncreadOrNc_varget(DD.path.TempSalt.salt{1},'SALT',dim.start2d,dim.len2d));
    for ss=2:num
        tmp=(1/num) * squeeze(ncreadOrNc_varget(DD.path.TempSalt.salt{ss},'SALT',dim.start2d,dim.len2d));
        salt=salt + tmp;
    end
    salt(salt==0)=nan;
    salt=salt* DD.parameters.salinityFactor;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function temp=ChunkTemp(DD,dim)
    num=numel(DD.path.TempSalt.temp);
    temp = (1/num) * squeeze(ncreadOrNc_varget(DD.path.TempSalt.temp{1},'TEMP',dim.start2d,dim.len2d));
    for tt=2:num
        tmp=(1/num) * squeeze(ncreadOrNc_varget(DD.path.TempSalt.temp{tt},'TEMP',dim.start2d,dim.len2d));
        temp=temp + tmp;
    end
    temp(temp==0)=nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dim=ncArrayDims(DD,cc)
    lims=DD.RossbyStuff.lims.dataIn;
    j_indx_start = DD.TS.window.limits.south-1;
    j_len = DD.TS.window.dim.y;
    dim.start2d = [0 0 j_indx_start lims(cc,1)-1];
    dim.len2d = 	[inf inf j_len diff(lims(cc,:))+1];
    dim.start1d = [j_indx_start lims(cc,1)-1];
    dim.len1d =	[j_len diff(lims(cc,:))+1];
    %% new indeces for output nc file
    xlens=diff(lims,1,2)+1;
    xlens(xlens<0)= xlens(xlens<0) + DD.TS.window.fullsize.x;
    newxstart=sum(xlens(1:cc-1));
    dim.new.start =[0 newxstart];
    dim.new.len =  dim.len1d;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


