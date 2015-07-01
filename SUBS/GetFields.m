function [F,unreadable]=GetFields(file,keys)
    F=struct;
    unreadable.is=false;
    for field=fieldnames(keys)';ff=field{1};
        %%
        if isempty(ff),continue;end
        %%
        try
            F.(ff)=tryCase(ff,file,keys);
        catch uc
            unreadable=cathCase(uc);
            return
        end
    end
    %%
    if isfield(F,'lon')
        if numel(F.lon)==length(F.lon)
            [F.lon,F.lat]=meshgrid(F.lon,F.lat);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Fff = tryCase(ff,file,keys)
    [~,~,ext]=fileparts(file);
    if any(strcmpi(ext,{'.nc','.netcdf'}))
        if exist('nc_varget') %#ok<*EXIST>
            sqDouNCv=@(F,k,ff) squeeze(double(nc_varget(F,k.(ff))));
        elseif exist('ncread')
            sqDouNCv=@(F,k,ff) permute(squeeze(double(ncread(F,k.(ff)))),[2 1]);
        else
            error('how to read netcdfs?');
        end
    elseif any(strcmpi(ext,{'.mat'}))
        sqDouNCv=@(F,k,ff) squeeze(double(getfield(load(F),k.(ff))));
    end
    Fff = sqDouNCv(file,keys,ff);
    if strcmpi(ff,'lon')
        Fff =  wrapTo360(Fff);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function unreadable=cathCase(uc)
    unreadable.is=true;
    unreadable.catch=uc;
    disp('skipping'); disp(uc);
    disp(uc.message);
    disp(uc.getReport);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%