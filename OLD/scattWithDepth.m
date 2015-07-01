load DD

trFiles = dir2([DD.path.tracks.name,'TR*.mat']);


idx = nan(1,30*1000);

a=0;
for tt = 1:1000:numel(trFiles)
    track = getfield(load(trFiles(tt).fullname),'track');
    len = length(track);
    b=a+len;
    
    
    idx(a+1:b) = extractdeepfield(track,'centroid.lin');
    idx(a+1:b) = extractdeepfield(track,'centroid.lin');
    
    
    
    
    a=b;
end



