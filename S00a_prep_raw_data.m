function S00a_prep_raw_data
    %% set up meta-data/info file "DD.mat"
    [DD, window] = set_up;
    %% main
    main(DD, window);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD, window)
    %% operate main
    parfor cc=1:DD.checks.passedTotal
        S00a_main(DD,window,cc);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DD, window] = set_up
    %% init dependencies
    addpath(genpath('./'));
    %% get user input
    DD = initialise('raw');
    %% build one file each for lat/lon
    window = constructGeoFile(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

