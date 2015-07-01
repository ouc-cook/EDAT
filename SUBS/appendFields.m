function out=appendFields(out,in)    
    fn=fieldnames(in);
    for f=fn'
        out.(f{1})=in.(f{1});
    end    
end