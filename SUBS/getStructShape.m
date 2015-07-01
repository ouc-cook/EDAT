%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 13-Apr-2014 14:38:46
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function shp=getStructShape(strct)
	shp=recursiveNames(strct);
% 	ljkigu
% 	[paths]=allpaths(shp,{[]})
	
end
% 
% function [paths]=allpaths(shp,paths)
% 	for ss=1:numel(shp)
% 		if ~iscell(shp{ss}{2})
% 			return
% 		end
% 			paths={{paths}; {{shp{ss}{1}} {allpaths(shp{ss}{2},paths)}}}
% 		
% 	end
% end

function shp=recursiveNames(strct)
	
	%% get field name strings
	fn=fieldnames(strct);
	%% init empty shape array
	shp=cell(1,1);
	%% init indices (xx ie 'depth' must be supllied as 1 from first call!)
	yy=0;
	%% loop ver fields at depth xx
	for field=fn'
		yy=yy+1;
		%% write field name
		
		%% if subfields exist restart recursively for sub struct
		if isstruct(strct.(field{1}))
			shp(yy)={[field {recursiveNames(strct.(field{1}))}]};
		else
			shp(yy)={field};
		end
	end
end







