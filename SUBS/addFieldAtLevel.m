%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 13-Apr-2014 16:04:24
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function inout=addFieldAtLevel(inout,fieldtoadd,nametoadd,atlevelof)
	fn=fieldnames(inout);
	%% loop over fields of struct
	for field=fn'
		if strcmp(field,atlevelof)
			%% reached desired level; add new field
			inout.(nametoadd)=fieldtoadd;
		elseif isstruct(inout.(field{1}))
			%% recursively penetrate to deeper levels
			inout.(field{1})=addFieldAtLevel(inout.(field{1}),fieldtoadd,nametoadd,atlevelof);
		end
	end
end