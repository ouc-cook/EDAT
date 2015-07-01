%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 14-Apr-2014 18:21:47
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [new]=stdOnFly(old, value_N, N)
	if N>1
		new=sqrt(old.^2+1./(N-1).*(value_N-old).^2);
	else
		new=value_N;
	end	
end
