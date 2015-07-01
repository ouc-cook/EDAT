%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-May-2014 16:59:11
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [xx,yy] = meshgridQuick(xrow,ycol)
    %         xrow = full(x(:)).'; % Make sure x is a full row vector.
    %         ycol = full(y(:));   % Make sure y is a full column vector.
    xx = xrow(ones(size(ycol)),:);
    yy = ycol(:,ones(size(xrow)));
end
