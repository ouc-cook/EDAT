%%%%%%%%%
% Created: 08-Apr-2014 19:50:46
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function S07_getMeanU
    %% init
    DD = initialise([],mfilename);
     DD.map.window = getfieldload(DD.path.windowFile,'window');
    %           save DD
    %     load DD
    %     if ~DD.switchs.netUstuff,return;end
    %% find files
    [file] = findVelFiles(DD);
    %% get dims
    [d,pos,dim] = getDims(file,DD);
    %% means
    means = getMeans(d,pos,dim,file,DD);
    %%
    means.d = d;
    means.pos = pos;
    means.dim = dim;
    %% save
    save([DD.path.meanU.file], 'means')
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [means] = gMsConstCase(file,DD,dim,d,pos)
    
    for kk = 1:numel(file)
        disp(['found ' file(kk).U ' and ' file(kk).V])
        %%
        traforead = @(f,fac,key)  permute(squeeze(ncread(f,key,dim.start,dim.length))/fac,[2,1,3]);
        % [Y X Z K]
        U(:,:,:,kk) = traforead(file(kk).U,DD.parameters.meanUunit,DD.map.in.keys.U);
        %         V(:,:,:,kk) = traforead(file(kk).V,DD.parameters.meanUunit,DD.map.in.keys.V);
        
    end
    [Y, X, Z, K] = size(U); %#ok<ASGLU>
    disp(['creating means'])
    U(U<-1e33) = nan; % missing values
    %     V(V<-1e33) = nan; % missing values
    allzonal = nanmean(U,4);
    %     allmerid = nanmean(V,4);
    %     alltotal = hypot(means.zonal,means.merid);
    %     means.direc = azimuth(zeros(size(means.zonal)),zeros(size(means.zonal)),means.merid,means.zonal);
    %%
    pos.z.start(pos.z.start==1) = 2; % TODO
    %%
    zA = pos.z.start - 1;
    zB = pos.z.start + pos.z.length;
    %%
    depA = d(zA:zB-2);
    depB = d(zA+2:zB);
    means.depth = d(zA+1:zB-1);
    %%
    depCentralDiff =  double((depB-depA));
    %%
    DEPDIFF = permute(repmat(depCentralDiff,[1,Y,X]), [2,3,1]);
    %%
    means.zonal = (nansum(allzonal .* DEPDIFF,3)./sum(DEPDIFF,3));
    %%
    disp(['resizing to output size'])
    proto = load(DD.path.protoMaps.file);
    lin = proto.idx(1:numel(U(:,:,1))); % ignore overlap
    means.small.zonal = proto.proto.nan;
    %%
    
    indextrafo = cell(size(proto.proto.nan));
    parfor cc = 1:numel(indextrafo)
        indextrafo{cc} = find((lin == cc));
    end
    means.small.indextrafo = indextrafo;
    %%
    for cc = 1:numel(indextrafo)
        if numel(indextrafo{cc}) > 0
            means.small.zonal(cc) = nanmean(means.zonal(indextrafo{cc}));
        end
    end
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function means = getMeans(d,pos,dim,file,DD)
    [means] = gMsConstCase(file,DD,dim,d,pos);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [d,pos,dim] = getDims(file,DD)
    dWanted.top = DD.parameters.meanUtop;
    dWanted.bot = DD.parameters.meanUbot;
    
    %%
    d =  ncread(file(1).U,DD.map.in.keys.z);
    %%
    [~,pos.z.start] = min(abs(d-dWanted.top));
    [~,pos.z.end  ] = min(abs(d-dWanted.bot));
    pos.z.length    = pos.z.end - pos.z.start + 1;
    %
    pos.x.start  = DD.map.window.limits.west;
    pos.x.length = DD.map.window.dim.x;
    pos.y.start  = DD.map.window.limits.south;
    pos.y.length = DD.map.window.dim.y;
    dim.start    = [ pos.x.start pos.y.start pos.z.start 1];
    dim.length   = [pos.x.length pos.y.length pos.z.length inf];
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [file] = findVelFiles(DD)
    %% find the U and V files
    ucc = 0; vcc = 0;
    file = struct;
    uvFiles = DD.path.UV.files;
    for kk = 1:numel(uvFiles)
        if ~isempty(strfind(uvFiles(kk).name,'UVEL_'))
            ucc = ucc+1;
            file(ucc).U = [DD.path.UV.name uvFiles(kk).name]; %#ok<AGROW>
        end
        if ~isempty(strfind(uvFiles(kk).name,'VVEL_'))
            vcc = vcc+1;
            file(vcc).V = [DD.path.UV.name uvFiles(kk).name]; %#ok<AGROW>
        end
    end
    if isempty(fieldnames(file))
        disp(['put U/V files into ' DD.path.UV.name])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
