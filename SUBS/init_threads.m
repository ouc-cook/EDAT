function desiredThreads=init_threads(desiredThreads)
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        currentThreads = 0;
    else
        currentThreads = poolobj.NumWorkers;
    end
    %%
    if currentThreads < desiredThreads
        delete(poolobj)
        if desiredThreads > 1
            parpool(desiredThreads);
        end
    end
end
