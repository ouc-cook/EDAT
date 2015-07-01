%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 28-Oct-2014 15:36:41
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [col]=int2color(intIn)
    col=sscanf(dec2bin(intIn,3),'%1d')';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%