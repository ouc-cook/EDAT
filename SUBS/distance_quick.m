%function dist=distance_quick(A,B)
%typ either 'rad' (default) or 'deg'
%accuracy 1 or 2 (more exact)
function [dist,bloncos]=distance_quick(A,B,typ_in,typ_out,accuracy,bloncos)

if nargin<5
    accuracy=0;
    if nargin<4
        typ_out='rad';
        if nargin<3
            typ_in='rad';
        end
    end
end



if strcmp(typ_in,'deg')
    B=deg2rad(B); A=deg2rad(A);
end

dist=[];
blat=B(:,1);
blon=B(:,2);
alat=A(:,1);
alon=A(:,2);


switch accuracy
    case 2
        delta_lon=abs(alon-blon);
        top=sqrt((cos(blat).*sin(delta_lon)).^2+(cos(alat).*sin(blat)-sin(alat).*cos(blat).*cos(delta_lon)).^2); %most exact
        denom=(sin(alat).*sin(blat)+cos(alat).*cos(blat).*cos(delta_lon));
        dist=atan(top./denom);
    case 1
        delta_lon=abs(alon-blon);
        dist=acos(sin(alat).*sin(blat)+cos(alat).*cos(blat).*cos(delta_lon));
    case 0
        
        if nargin<6
            bloncos=blon.*cos(blat);  % only calc once
        end
        delta_lon_real=abs(alon.*cos(alat)-bloncos);
        delta_lat=abs(alat-blat);
        dist=sqrt(delta_lat.^2 + delta_lon_real.^2);  % quickest
end

if strcmp(typ_out,'deg')
    dist=rad2deg(dist);
end




