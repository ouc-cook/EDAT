function dF
    gn=@(ds) ds(2).name;
    fprintf('evaluating function %s\n',gn(dbstack));
end