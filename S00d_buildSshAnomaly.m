% subtract time-mean of SSH from SSH to build anomaly
function S00d_buildSshAnomaly
    %% init
    DD = initialise('cuts');
    %% main
    main(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    %% init
    sshMean = getfieldload(DD.path.meanSsh.file,'sshMean');
    files = DD.checks.passed;
    %% sum all SSH
    parfor ff = 1:numel(files)
%         for ff = 1:numel(files)
        loopOverFiles(ff,files,sshMean)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loopOverFiles(ff,files,sshMean)
    currentFile = files(ff).filenames;
    %% load
    cut = load(currentFile);
    %% subtract
    cut.fields.sshAnom = cut.fields.ssh - sshMean;
    %% save
    save(currentFile,'-struct','cut');
end