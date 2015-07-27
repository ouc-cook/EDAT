%% data preparation
% S00a_prep_raw_data % TODO back2spmd
S00b_rossbyStuff
%%
S00c_buildMeanSsh 
S00d_buildSshAnomaly % TODO back2spmd
%% main steps
S01_calc_fields
S02_contours
S03_filterContours
S04_trackEddies
% %% post process
% P01_analyzeTracks