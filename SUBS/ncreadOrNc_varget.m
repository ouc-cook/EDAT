function [out] = ncreadOrNc_varget(File,field,dimStart,dimLen)
    if nargin<3
        if exist('nc_varget') %#ok<*EXIST>
            out = nc_varget(File,field);
        elseif exist('ncread')
            out = ncread(File,field);
        else
            error('how to read netcdfs?');
        end
    else
        if exist('nc_varget')
            out = nc_varget(File,field,dimStart,dimLen);
        elseif exist('ncread')
            dimStart = dimStart + 1;
            switch numel(dimLen)
                case 4
                    pp = @(x) x([4 3 1 2]);
                    out = permute(squeeze(ncread(File,field,pp(dimStart),pp(dimLen))),[3 2 1]);
                case 2
                    pp = @(x) x([2 1]);
                    out = permute(squeeze(ncread(File,field,pp(dimStart),pp(dimLen))),[2 1]);
            end
           
        else
            error('how to read netcdfs?');
        end
    end
end