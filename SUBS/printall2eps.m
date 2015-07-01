%prints all figures into current dir as .eps
function []=printall2eps()
	figs = findobj('Type','figure');
	for l=1:length(figs)
		eval(['print -f', num2str(figs(l)),' -r600 -depsc figure_',num2str(figs(l)),'.eps;'])
	end
end

