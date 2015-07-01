%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 18:55:29
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function zzz
	while true;sleep(1);disp(datestr(now));end
end
function sleep(secs)
	tic;	t=0;
	while t<secs
		t=toc;
	end
end