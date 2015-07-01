function mkdirp(D)
	if ~exist(D,'dir')
		mkdir(D)
	end
end