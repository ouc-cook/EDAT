%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 18-Sep-2014 20:15:23
% Computer:  GLNXA64
% Matlab:  8.1
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [meanAB]=ComboMean(NA,NB,meansA,meansB)   
    zyx=@(yx) permute(full(yx),[3,1,2]);
    nansum2d=@(A,B) sparse(permute(nansum([zyx(A); zyx(B)],1),[2,3,1]));
    meanAB=nansum2d(meansA.*NA,meansB.*NB)./nansum2d(NA,NB);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


