%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 08-Oct-2014 17:53:03
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xd=nandetrend(xin) 
    x=xin;
 x(isnan(xin))=interp1(find(~isnan(xin)),xin(~isnan(xin)),find(isnan(xin)),'spline');
 xd=detrend(x) + nanmean(xin);
end
