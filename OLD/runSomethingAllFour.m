function runSomethingAllFour(todo)
    dirs = {'aviI';'aviII';'pop7II';'p2aII'};
    for dd=1:numel(dirs)
        DOIT(['../' dirs{dd}],todo);
    end
end

function DOIT(dr,todo)
    cd(dr);
    addpath(genpath('./'));
    eval(todo)
end
