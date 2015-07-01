%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-Jun-2014 17:51:10
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [out]=ncInfoAll(in)
addpath(genpath('./'));    
out.nc_info=nc_info(in);
    warning('off','SNCTOOLS:nc_getall:dangerous');
    out.getAllNoData=nc_getall(in);
    warning('on','SNCTOOLS:nc_getall:dangerous');
end