files.chunks = dir2('../datapop7II/ROSSBY/BVR*mat');


DEPTH = getfield(load(files.chunks(1).fullname,'DEPTH'),'DEPTH');



for cc = 1:numel(files.chunks)
    fprintf('%d\n',round(100*cc/numel(files.chunks)));
    file = files.chunks(cc).fullname;
    chunk = load(file);
    T = isnan(chunk.TEMP);
    [Z,Y,X] = size(T);
    T2d = reshape(T,Z,[]);
    Tdiff = abs(diff([T2d; false(1,Y*X)],1,1));
    bottom = sum(Tdiff,1)==1;
    Tdiff(end,~bottom)    = false;
    surfa = sum(Tdiff,1)<1;
    Tdiff(1,surfa) = ones(1,sum(surfa));
    [di,xi] = find(Tdiff);
    di = di + 1;
    di(di>numel(DEPTH)) = numel(DEPTH);
    chunk.bottomDepth = reshape(DEPTH(di),Y,X);
    
    save(file,'-struct','chunk');
    
end

 file = files.chunks(1).fullname;
 fullDepth = getfield(load(file,'bottomDepth'),'bottomDepth');


for cc = 2:numel(files.chunks)
    fprintf('catting %d\n',round(100*cc/numel(files.chunks)));
    file = files.chunks(cc).fullname;
  fullDepth = [fullDepth getfield(load(file,'bottomDepth'),'bottomDepth')];
  
end

disp('done!')

save('fullDepth.mat','fullDepth');