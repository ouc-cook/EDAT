% get 2d-coordinate pair from 1d-coordinate.
% columns are stacked on top of one another
% V=[1, 2, 3, 4]
% Vx = 3
%  raise_1d_to_2d(2,Vx) = [1,2]
function [y,x]=raise_1d_to_2d(Y,x1d)
	if isempty(x1d)
		y=[];x=[];return
	end
	x=(ceil((double(x1d))/double(Y)));
	y=(x1d - (x-1)*Y);   
end
