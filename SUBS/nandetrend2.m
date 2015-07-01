%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 12-Oct-2014 17:53:03
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xd=nandetrend2(xin)  % piece wise
    %% init
    x=reshape(xin,1,[]);
    xd=nan(size(x));
    %% ~nan pieces
    water = diff(~isnan([nan x nan]));
    diveIn   = find(water==1);
    goLand = find(water==-1)-1;
    for ii=1:numel(diveIn)
        idx=diveIn(ii):goLand(ii);
        xd(idx)=detrend(x(idx)) + mean(x(idx));
    end
end

