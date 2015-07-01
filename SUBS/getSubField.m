%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 19-Apr-2014 18:19:49
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [value,fields]=getSubField(fieldnameToAccess,structure)
		fields = textscan(fieldnameToAccess,'%s','Delimiter','.');
		value = getfield(structure,fields{1}{:});		
end