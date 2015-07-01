function fig=ppc(in)
%  	figure
	%% if too large, downscale; keep ratio; make double
		[a,b,c]=size(in);
	if a==1 && b~=1 && c~=1
		in=squeeze(in);
	end
	[Y,X]=size(in);
	YoX=Y/X;
	Y(Y>256)=256;
	X=round(Y/YoX);
	%% draw
	fig=pcolor(downsize(double(squeeze(in)),X,Y));
	shading flat
	colorbar
end