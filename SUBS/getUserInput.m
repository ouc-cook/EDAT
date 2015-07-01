function [DD] = getUserInput      
    %% merge INPUT.m with source specific INPUTxxx.m
    DD = evalUserInput; 
    %% load filename patterns and field keys
    [DD.pattern, DD.FieldKeys] = patternsAndKeys;   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DD = evalUserInput    
    B = INPUT;
    A = eval(['INPUT' B.template]);
    DD = mergeStruct2(A,B);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
