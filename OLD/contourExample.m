%%
close all
clear all
cmc=jet(200)
cma=cmc(1:100,:)
cmb=cmc(101:end,:)

D=textscan(pwd,'%s','delimiter','/')
d=D{1}{end}

dd=getfield(dir(['../data' d '/EDDIES/*19941120*' ]),'name')
cc=getfield(dir(['../dataC/CUTS/*19941120*' ]),'name')
load(['../data' d '/EDDIES/' dd ])
load(['../dataC/CUTS/' cc ])
whos
%%
DD=load(['../data' d '/DD.mat' ])
%%
csteps=nanmin(grids.ssh(:)):.01:nanmax(grids.ssh(:))
contour(grids.ssh,csteps,'linewidth',1.5)
%%
save(['tmp-' d])
%%
axis on
grid on
set(gca,'xticklabel','','yticklabel','')
% colormap(hsv)
cl=[-.5 .7]
caxis(cl) 
doublemap([cl(1) 0 cl(2)],cma,flipud(cmb),[.1 .6 .1],20)
%%
hold on
for ee=1:numel(anticyclones)
   x=anticyclones(ee).coordinates.exact.x;
   y=anticyclones(ee).coordinates.exact.y;
   plot(x,y,'--','color','black','linewidth',2)
end
%%
hold on
for ee=1:numel(cyclones)
   x=cyclones(ee).coordinates.exact.x;
   y=cyclones(ee).coordinates.exact.y;
   plot(x,y,'-','color','red','linewidth',2)
end

% 
% %%
% hold on
% for ee=1:numel(anticyclones)
%    x=anticyclones(ee).coordinates.int.x;
%    y=anticyclones(ee).coordinates.int.y;
%    plot(x,y,'--','color','black','linewidth',2)
% end
% %%
% hold on
% for ee=1:numel(cyclones)
%    x=cyclones(ee).coordinates.int.x;
%    y=cyclones(ee).coordinates.int.y;
%    plot(x,y,'-','color','red','linewidth',2)
% end

%%
% 
% hold on
% for ee=1:numel(cyclones)
%     corr.x=    cyclones(ee).peak.x(1) -  cyclones(ee).peak.z.x + 1;
%     corr.y=    cyclones(ee).peak.y(1) -  cyclones(ee).peak.z.y + 1;    
%     xa=cyclones(ee).radius.coor.Xwest + corr.x;
% 	xb=cyclones(ee).radius.coor.Xeast + corr.x;
% 	ya=cyclones(ee).radius.coor.Ysouth + corr.y;
% 	yb=cyclones(ee).radius.coor.Ynorth + corr.y;
%     xm=(mean([xa,xb]));
% 	ym=(mean([ya,yb]));
% 	axisX=(double(xb-xa))/2;
% 	axisY=(double(yb-ya))/2;
%     %% init ellipse mask
% 	ellipse=false(size(grids.ssh));
% 	%% get ellipse coordinates
% 	linsdeg=(linspace(0,2*pi,2*sum(size(grids.ssh))));
% 	ellipseX=round(axisX*cos(linsdeg)+xm);
% 	ellipseY=round(axisY*sin(linsdeg)+ym);
% 	ellipseX(ellipseX>size(grids.ssh,2))=size(grids.ssh,2);
% 	ellipseY(ellipseY>size(grids.ssh,1))=size(grids.ssh,1);
% 	ellipseX(ellipseX<1)=1;
% 	ellipseY(ellipseY<1)=1;
%   plot(ellipseX,ellipseY,'red','linewidth',1.2)    
% end
% 
% 
% %%
% 
% hold on
% for ee=1:numel(anticyclones)
%     corr.x=    anticyclones(ee).peak.x(1) -  anticyclones(ee).peak.z.x + 1;
%     corr.y=    anticyclones(ee).peak.y(1) -  anticyclones(ee).peak.z.y + 1;    
%     xa=anticyclones(ee).radius.coor.Xwest + corr.x;
% 	xb=anticyclones(ee).radius.coor.Xeast + corr.x;
% 	ya=anticyclones(ee).radius.coor.Ysouth + corr.y;
% 	yb=anticyclones(ee).radius.coor.Ynorth + corr.y;
%     xm=(mean([xa,xb]));
% 	ym=(mean([ya,yb]));
% 	axisX=(double(xb-xa))/2;
% 	axisY=(double(yb-ya))/2;
%     %% init ellipse mask
% 	ellipse=false(size(grids.ssh));
% 	%% get ellipse coordinates
% 	linsdeg=(linspace(0,2*pi,2*sum(size(grids.ssh))));
% 	ellipseX=round(axisX*cos(linsdeg)+xm);
% 	ellipseY=round(axisY*sin(linsdeg)+ym);
% 	ellipseX(ellipseX>size(grids.ssh,2))=size(grids.ssh,2);
% 	ellipseY(ellipseY>size(grids.ssh,1))=size(grids.ssh,1);
% 	ellipseX(ellipseX<1)=1;
% 	ellipseY(ellipseY<1)=1;
%   plot(ellipseX,ellipseY,'black','linewidth',1.2)    
% end
% 
% 

%%

axis([300 500 300 600])

tit=[sprintf('IQ: %2.1f', DD.thresh.shape.iq) ' - ' ...
      sprintf('r/Lr: %2d', DD.thresh.maxRadiusOverRossbyL) ]
   plot(x,y,'red','linewidth',2)
end

%%

axis([120 320 325 475])

tit=[sprintf('IQ: %2.1f', DD.thresh.shape.iq) ' - ' ...
     sprintf('ID: %2.1f', DD.thresh.IdentityCheck) ' - ' ...
     sprintf('r/Lr: %2d', DD.thresh.maxRadiusOverRossbyL) ]
title([tit])
colorbar('location', 'southOutside')
colorbar off
%%

savefig('./',72,400,600, d)




