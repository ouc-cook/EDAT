
function [OUT]=extractdeepfield(IN,fieldnameToAccess)
    field = textscan(fieldnameToAccess,'%s','Delimiter','.');
    fieldSize=size(field{1},1);
    switch fieldSize
        case 1
            OUT=extractfield(IN,fieldnameToAccess);
        case 2
            OUT=extractfield(cell2mat(extractfield(IN,field{1}{1})),field{1}{2} );
        case 3
            OUT=extractfield(cell2mat(extractfield(cell2mat(extractfield(IN,field{1}{1})),field{1}{2} )),field{1}{3});
        case 4
            OUT=extractfield(cell2mat(extractfield(cell2mat(extractfield( cell2mat(extractfield(IN,field{1}{1})),field{1}{2} )),field{1}{3})),field{1}{4});
    end    
    if iscell(OUT)
        OUT = cell2mat(OUT);
    end    
end
