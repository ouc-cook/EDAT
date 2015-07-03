function [FieldsOut] = GetFields(file,keys)
    %% init
    FieldsOut = struct;
    %% loop over fields
    for field = fieldnames(keys)'
        ff=field{1};
        %% skip empty
        if isempty(ff),continue;end
        %% read
        FieldsOut.(ff) = extractField(ff,file,keys);
    end
    %% in case of 1d lon/lat vectors make meshgrids
    if isfield(FieldsOut,'lon')
        if numel(FieldsOut.lon)==length(FieldsOut.lon)
            [FieldsOut.lon,FieldsOut.lat] = meshgrid(FieldsOut.lon,FieldsOut.lat);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Fff = extractField(ff,file,keys)
    %% determine method
    [~,~,ext]=fileparts(file);
    if any(strcmpi(ext,{'.nc','.netcdf'}))
        if exist('ncread') %#ok<EXIST>
            % make (Y,X)
            reshapeRaw = @(F,k,ff) permute(squeeze(double(ncread(F,k.(ff)))),[2 1]);
        else
            error('how to read netcdfs?');
        end
    elseif strcmpi(ext,{'.mat'})
        reshapeRaw = @(F,k,ff) squeeze(double(getfield(load(F),k.(ff))));
    end
    %% apply method
    Fff = reshapeRaw(file,keys,ff);
    %% 0:360 longi
    if strcmpi(ff,'lon')
        Fff =  wrapTo360(Fff);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
