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
    prmt = @(x) permute(x,[3,1,2]);
    files = DD.checks.passed;
    %% sum all SSH
    sshSum = prmt(nan(window.dimPlus.y,window.dimPlus.x));
    for ff = 1:numel(files) % TODO make parallel
        %% load
        ssh = prmt(getfield(getfieldload(files(ff).filenames,'fields'),'ssh'));
        %% mean ssh
        sshSum = nansum([sshSum; ssh],1);
    end
    %% build mean
    sshMean = squeeze(sshSum)./ numel(files); %#ok<NASGU>
    %% save
    save(DD.path.meanSsh.file,'sshMean');
end

