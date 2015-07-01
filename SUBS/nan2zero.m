function M=nan2zero(M)
	M(isnan(M))=0;
end