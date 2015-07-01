%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 18-Jun-2014 12:00:00
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NCoverwriteornot(nc_file_name,overwrite)
    if nargin<2
        overwrite=false;
    end
    %%
    try
        nc_create_empty(nc_file_name,'clobber');
    catch me
        existsCase(me,nc_file_name,overwrite);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function existsCase(me,nc_file_name,overwrite)
    disp(me.message)
    if overwrite
        owCase(nc_file_name);
    else
        warning(['delete ' nc_file_name ' or set DD.overwrite to true!' ])
        %         error(['delete ' nc_file_name ' or set DD.overwrite to true!' ])
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function owCase(nc_file_name)
    h=waitbar(0,['overwriting ' nc_file_name ' in 2s!']);
    ss=2;
    while ss>=0
        sleep(.01);
        waitbar((2-ss)/2);
        ss=ss-.01;
    end
    %%
    nc_create_empty(nc_file_name,'clobber');
    close(h)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%