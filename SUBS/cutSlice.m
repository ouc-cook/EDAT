function out=cutSlice(RAW,winIdx)
    cutOut=@(raw,idx) reshape(raw(idx),size(idx));
    %% cut piece
    fields=fieldnames(RAW);
    for ff=1:numel(fields); field=fields{ff};
        out.(field) = cutOut(RAW.(field),winIdx);
    end   
end