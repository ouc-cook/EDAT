%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 14-Apr-2014 18:21:23
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new]=meanOnFly(old, value_N, N)
	new=nansum([(N-1)./(N).*old, (1./N).*value_N],2);
end
