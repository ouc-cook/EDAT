% written by NK,1406
% 	inspired by Greg Reeves, March 2009.
% 	Division of Biology
% 	Caltech
% 	Inspired by "smooth2", written by Kelly Hilands, October 2004
% 	Applied Research Laboratory
% 	Penn State University
% 	Developed from code written by Olof Liungman, 1997
% 	Dept. of Oceanography, Earth Sciences Centre
% 	G�teborg University, Sweden
% 	E-mail: olof.liungman@oce.gu.se
function Mout = smooth2gauss(Min,alpha)
    [Y,X] = size(Min);
    N=min([Y,X]);
    sig=(2*N+1)./(2*alpha);
    padwidth=ceil(median(2*sig))  ;
    Mpad=padarray(Min,[padwidth padwidth],'symmetric');
  
    [Ypad,Xpad] = size(Mpad);
    
    
    %%
    if numel(sig)==1
        fltr.y=repmat(gausswin(2*N+1,sig)',Ypad,1);
        fltr.x=repmat(gausswin(2*N+1,sig)',Xpad,1);
    else
        sig=padarray(sig,[0 padwidth],'replicate');
        fltr.y=zeros(Ypad,2*N+1);
        fltr.x=zeros(Xpad,2*N+1);
        for ii=1:Ypad
            fltr.y(ii,:) = gausswin(2*N+1,sig(ii))';
        end
        for ii=1:Xpad
            fltr.x(ii,:) = gausswin(2*N+1,sig(ii));            
        end
    end
    %%
    e.y = spdiags(fltr.y,(-N:N),Ypad,Ypad);
    e.x = spdiags(fltr.x,(-N:N),Xpad,Xpad);
    
    A = isnan(Mpad);
    Mpad(A) = 0;
    nrmlize = e.y*(~A)*e.x;
    nrmlize(A) = NaN;
    Mout = e.y*Mpad*e.x;
    Mout = Mout./nrmlize;
    Mout = Mout(padwidth+1:end-padwidth,padwidth+1:end-padwidth);
   
end











