% get 1d-coordinate from 2d-coordinate pair.
% columns are stacked on top of one another
% e.g. (1,2) of matrix 4x4 becomes 5
function [coor]=drop_2d_to_1d(y,x,Y)
    if size(x)~=size(y)
        x=x';
    end
    if y>Y
        error('y>Y doesnt make sense sorry')
    end
    coor=int32(round(x-1)*double(Y)+round(y));
end
