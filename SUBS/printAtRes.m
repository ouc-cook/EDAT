function printAtRes(rez,xdim,ydim,tit)
	
	%% set up figure
	resolution=get(0,'ScreenPixelsPerInch');
	xdim=xdim*rez/resolution;
	ydim=ydim*rez/resolution;
	set(gcf,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
	
	%% print
	mkdirp('~/PRINTS/')
	%fname=['~/PRINTS/',tit,'_',datestr(now,'mmddHHMMSS')];
	fname=['~/PRINTS/',tit];
	fnamepng=[fname,'.png'];
	fnamepdf=[fname,'.pdf'];
	try
	print(gcf, '-dpng',['-r',num2str(rez)],fnamepng );
	end
	try
	print(gcf, '-dpdf',['-r',num2str(rez)],fnamepdf );
	end
	close(gcf);
end

