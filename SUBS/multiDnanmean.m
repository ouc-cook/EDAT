function meanOfAandB=multiDnanmean(A,B)
    apnd1d = @(x) reshape(x,[1,size(x)])  ;
    meanOfAandB=nanmean([apnd1d(A); apnd1d(B)]);
end