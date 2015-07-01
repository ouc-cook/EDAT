function out=ncVarFromLinIdx(file,key,linIdx)
    out=grabIdx(nc_varget(file,key),linIdx);
end
function out=grabIdx(in,idx)
    out=in(idx);
end