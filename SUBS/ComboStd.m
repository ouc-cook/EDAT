% http://en.wikipedia.org/wiki/Standard_deviation#Combining_standard_deviat
% ions
function [stdAB]=ComboStd(Na,Nb,meanA,meanB)	
    nsd=@(A,B) sparse(squeeze(nansum(cat(3,full(A),full(B)),3))); %nansum2sparse2d    
    %%
    Nall=nsd(Na,Nb);
    termA=nsd(Na.*meanA.^2,Nb.*meanB.^2)./Nall;
    termB=n2z(Na.*Nb.*nsd(meanA,-meanB).^2)./(Nall.^2);    
    stdAB=sqrt(termA+termB);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function x=n2z(x)
    x(isnan(x))=0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%