function out=field2mat(strct,field)
out=cell2mat(struct2cell(cat(1,strct.(field))));
end