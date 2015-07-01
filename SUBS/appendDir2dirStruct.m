function appendDir2dirStruct(S,d)
	for ii=1:numel(S)
		S(ii).fullname=[d S(ii).name];
	end
end