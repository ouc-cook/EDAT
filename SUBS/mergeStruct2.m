function [A,B]=mergeStruct2(A,B)
    %% A into B
    [A,B]=AintoB(A,B);
    %% new B into A
    [B,A]=AintoB(B,A);
    %----------------------------------------------------------------------
    function [A,B]=AintoB(A,B)
        fields=fieldnames(A);
        for ff=1:numel(fields)
            field=fields{ff};
            if isstruct(A.(field))
                if ~isfield(B,field)
                    B.(field)=A.(field);
                else
                    [A.(field),B.(field)]=mergeStruct2(A.(field),B.(field));
                end
            else
                if ~isfield(B,field)
                    B.(field)=A.(field);
                end
            end
        end
    end
end