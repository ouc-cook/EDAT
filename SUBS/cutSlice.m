function out=cutSlice(RAW,win)
    cutOut=@(raw,idx) reshape(raw(idx),size(idx));
    %% cut piece
    fields=fieldnames(RAW);
    for ff=1:numel(fields); field=fields{ff};
        out.(field) = cutOut(RAW.(field),win.idx);
    end   
end