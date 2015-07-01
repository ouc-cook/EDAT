%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 18-Feb-2014 11:03:33
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function idx=getIndicesForOutMaps(in,out,JJ,idx)
	%% allocate indices to be calculated by worker
	T=disp_progress('init','allocating old indices to output indeces');
	locSize=numel(JJ);	out.proto=[]; % save mem
	%% loop over indeces
	for ii=JJ
		T=disp_progress('disp',T,locSize,100);
		[idx(ii)]=rangeOp(in.lon(ii),in.lat(ii), out);
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lin]=rangeOp(inLon,inLat,out)
	%% scan for lat/lon within vicinity and use those only
	temp.lon=abs(out.lon-inLon)<=abs(2*(out.inc.x));
	temp.lat=abs(out.lat-inLat)<=abs(2*(out.inc.y));
	used.flag=temp.lon & temp.lat;
	%% out of bounds
	if ~any(used.flag(:)), lin=nan;	return;	end
	%% set lon/lat to be inter-distance checked
	[yi,xi]=find(used.flag);
	used.lat=out.lat(used.flag);
	used.lon=out.lon(used.flag);
	%% find best fit between new/old
	[used.idx]=TransferIdx(inLon,inLat,used);
	%% reset to full size
	y=yi(used.idx.y);
	x=xi(used.idx.x);
	lin=drop_2d_to_1d(y,x,out.dim.y);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [idx]=TransferIdx(lon,lat,used)
	%% build lon/lat matrices
	[yy,xx]=yyxx(lon,lat,used);
	%% take norm2 (sufficient for small distances)
	H=hypot(yy,xx);
	%% find pos of min
	[~,pos]=min(H(:));
	%% raise to 2d to find respective x/y
	[idx.y,idx.x]=raise_1d_to_2d(size(H,1),pos);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [YY,XX]=yyxx(lon,lat,used)
	%% zonal dists
	[A,B]=meshgrid(lon,used.lon);
	xx=abs(A-B)*cosd(lat);
	%% merid dist
	[A,B]=meshgrid(lat,used.lat);
	yy=abs(A-B);
	%%
	[XX,YY]=meshgrid(xx,yy);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
