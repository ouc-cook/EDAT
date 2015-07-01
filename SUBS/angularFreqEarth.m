%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 17:38:14
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function om=angularFreqEarth
    T=day_sid;
    om=2.0*pi/T;
    function d=day_sid
        d=23.9344696*60*60; % wikipedia
    end
end