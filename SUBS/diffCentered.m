%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 25-Sep-2014 20:03:54
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dYdX]=diffCentered(diffLevel,X,Y)
    if diffLevel>2
        error('implement!')
    end
    if X==1
        X=1:numel(Y);
    end
    Y=reshape(Y,1,[]);
    X=reshape(X,1,[]);
    dx=diff(X);
    switch diffLevel
        case 0
            dYdX=Y;
            return
        case 1 % first order forward
            dy=diff(Y);
            dx=dx(1:end);
            Xat=atmidpoints(X);
        case 2
            dy=diff(Y,2);
            dx=atmidpoints(dx).^2;
            Xat=X(2:end-1);
    end
    dydx=dy./dx;
    dYdX=spline(Xat,dydx,X);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Xm=atmidpoints(X)
    xa=X(2:end);
    xb=X(1:end-1);
    Xm=(xa+xb)/2;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%