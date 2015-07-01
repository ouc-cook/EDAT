%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dataHighPass,fltr]=ellipseFltr(semi,data)
    %% get center, minor and major axis for ellipse    
    semix=10*ceil(max(nanmedian(semi.x,2)));
    semiy=10*ceil(max(nanmedian(semi.y,2)));
    %% init ellipse mask
    fltr=false(2*semiy+1,2*semix+1);
    %% get ellipse coordinates
    linsdeg=(linspace(0,2*pi,pi*semix*semiy));
    ellx=round(semix*cos(linsdeg) + semix);
    elly=round(semiy*sin(linsdeg) + semiy);
    xi=round(ellx); xi(xi<1)=1; xi(xi>2*semix+1)=2*semix+1;
    yi=round(elly); yi(yi<1)=1; yi(yi>2*semiy+1)=2*semiy+1;
    xlin = drop_2d_to_1d(yi,xi,2*semiy+1);
    %% draw into mask
    fltr(xlin)=true;
    fltr=imfill(fltr,'holes')-fltr;
    fltr=fltr./sum(fltr(:));
    assert(round(sum(fltr(:))*1000)/1000==1);    
    blurred=filter2(fltr,padarray(data,[semiy semix],'symmetric'));
    dataHighPass=(data - blurred(semiy+1:end-semiy,semix+1:end-semix));
end