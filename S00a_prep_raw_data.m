% This is the first 'pre'-step (S00..). It's purpose is to extract SSH data
% from either pop or aviso files named like eg (15/07)
% SSH_GLB_t.t0.1_42l_CORE.yyyymmdd.nc or
% dt_global_twosat_msla_h_yyyymmdd_20140106.nc.
%
% the function
% -first creates the geometric information needed to transform
% input SSH to desired output geometry
% -and then saves one output .mat SSH file per time-step to
% ../dataXXX/CUTS/
%
% geo information is stored in ../dataXXX/window.mat.
%
% All S00 steps are not officially part of the program as they have to be
% rewritten/adapted to produce the needed format for S01.. etc.

function S00a_prep_raw_data
    %% set up meta-data/info file "DD.mat"
    [DD, window] = set_up;
    %% main
    main(DD, window);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD, window)
    %% operate main
    parfor_progress(DD.checks.passedTotal);
    parfor cc=1:DD.checks.passedTotal       
        S00a_main(DD,window,cc);
    end
    parfor_progress(0);
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

