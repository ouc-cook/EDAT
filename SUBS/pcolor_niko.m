%function [fig]=pcolor_niko(D,X,Y,rez,xdim,ydim,varargin)
function [fig]=pcolor_niko(D,X,Y,downsize,rez,xdim,ydim,clrmp,varargin)

%% check data

if nargin<2
    X=cell(sub_num);
    for su=1:sub_num
        X=meshgrid(size(D,2));
        Y=meshgrid(size(D,1));  
    end
end


%% set up figure
close all
resolution=get(0,'ScreenPixelsPerInch');
xdim=xdim*rez/resolution;
ydim=ydim*rez/resolution;
fig=figure('renderer','zbuffer'); 
set(fig,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);


%% plot
hold on
for vv=1:numel(varargin)
eval([varargin{vv},';'])
end
pcolor(gca,X(1:downsize:end,1:downsize:end),Y(1:downsize:end,1:downsize:end),D(1:downsize:end,1:downsize:end));shading flat;colorbar;
axis([min(X(:)),max(X(:)),min(Y(:)),max(Y(:))]);
colormap(clrmp);
%% print
fname=['~/PRINTS/print_',datestr(now,'mmddHHMMSS.FFF'),'.png'];
fnamet=['~/PRINTS/print_',datestr(now,'mmddHHMMSS.FFF'),'thump.png'];
print(fig, '-dpng',['-r',num2str(rez)],fname )
print(fig, '-dpng','-r50',fnamet )







