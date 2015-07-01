% see distance_quick
% quick but not very exact
function [dist]=distance_quickest(A,B)

blat=B(:,1);
blon=B(:,2);
alat=A(:,1);
alon=A(:,2);

delta_lon=abs(alon.*cos(alat)-blon.*cos(blat));
delta_lat=abs(alat-blat);
dist=sqrt(delta_lat.^2 + delta_lon.^2); 



