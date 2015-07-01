function [OUT]=downsize(IN,xout,yout)
[ydim,xdim]=size(IN);
xinc=round(linspace(1,xdim,xout));
yinc=round(linspace(1,ydim,yout))';
[X,Y]=meshgrid(xinc,yinc);
lininc=drop_2d_to_1d(Y(:),X(:),ydim);
OUT=reshape(IN(lininc),yout,xout);
end
