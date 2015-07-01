function sumOfAandB=multiDnansum(A,B)
%     apnd1d = @(x) reshape(x,[1,size(x)])  ;
	 apnd1d = @(x) x(:) ;
	 backshape = @(x,oridim) reshape(x,oridim) ;
    sumOfAandB=backshape(nansum([apnd1d(A) apnd1d(B)],2),size(A));
end