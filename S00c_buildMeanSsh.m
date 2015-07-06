% build time-mean of SSH
function S00c_buildMeanSsh
    %% init
    DD = initialise('cuts');
    %% load geo data
    window = getfieldload(DD.path.windowFile,'window');
    %% spmd
    main(DD,window);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,window)
    %% init
    sshSum = nan(window.dimPlus.y,window.dimPlus.x);
    files = DD.checks.passed;
    %% sum all SSH
    for ff = 1:numel(files) % TODO make parallel
        %% load
        ssh = getfield(getfieldload(files(ff).filenames,'fields'),'ssh');
        %% mean ssh
        sshSum = nansum([sshSum, ssh],2);
    end
    %% build mean
    sshMean = sshSum./ numel(files); %#ok<NASGU>
    %% save
    save(DD.path.meanSsh.file,'sshMean');
end
