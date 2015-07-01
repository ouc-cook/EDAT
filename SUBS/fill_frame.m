% this is slightly quicker than using the 'holes' option of imfill
function [BOX]=fill_frame(BOX,Y,X)
Y=double(Y);
X=double(X);
boxrim_i_y=[(1:Y), Y*ones(1,X-1), (Y-1:-1:1), ones(1,X-2)];
boxrim_i_x=[ones(1,Y), (2:X), X*ones(1,Y-1), (X-1:-1:2)];
boxrim_i=drop_2d_to_1d(boxrim_i_y,boxrim_i_x,Y);
[y_s,x_s]=raise_1d_to_2d(Y,boxrim_i(BOX(boxrim_i)==0));
y_s=double(y_s);x_s=double(x_s);
if isempty(y_s)
    return
end
warning('off') %#ok<*WNOFF> % ignoring out of range locations. irrelevant here
BOX=imfill(logical(BOX),[y_s',x_s'],4);
warning('on') %#ok<*WNON>


