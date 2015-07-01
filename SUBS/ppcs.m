function fig=ppc(in)
%  	figure
	%% if too large, downscale; keep ratio; make double
		[a,b,c]=size(in);
	if a==1 && b~=1 && c~=1
		in=squeeze(in);
	end
	[Y,X]=size(in);
	YoX=Y/X;
	Y(Y>512)=512;
	X=round(Y/YoX);
	%% draw
	fig=pcolor(downsize(double(squeeze(in)),X,Y));
	shading flat
	colorbar
    med.u=nanmedian(nanmin(in(:))) ;
    med.d=nanmedian(nanmax(in(:))) ;    
    caxis([med.u med.d]);    
end