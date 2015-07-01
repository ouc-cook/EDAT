function locate_deps
PATHS=...
{
 '.';
 './SUBS';
 './SUBS/mexcdf/mexnc';
 './SUBS/mexcdf/snctools';
};
for path=PATHS'
   addpath(genpath(path{1})) 
end
dbstop if error
rehash
end
