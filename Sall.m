% The idea is that the code from step S01.. on can only
% accept one particular data structure.
% All S00.. steps are meant to prepare the raw input data to the desired format which should look as such:
% Daily .mat-files saved as
%
% exampleCut = load('../dataXXX/CUTS/CUT_yyyymmdd_SSS-NNN-WWW-EEE.mat')
%
% exampleCut.fields
%
% ans =
%
%            ssh: [173x170 double]
%        sshAnom: [173x170 double]
%              U: [173x170 double]
%              V: [173x170 double]
%          absUV: [173x170 double]
%     OkuboWeiss: [173x170 double]
%
%
% where XXX is the name of the current folder.
% The necessary field is exampleCut.fields.sshAnom which is (in [SI]) the SSH anomaly built by subtracting the time-mean of SSH from SSH.
%
% ------------------------------------
%
% Also necessary is the file
%
% w = load('../dataXXX/window.mat')
%
% w.window
%
% ans =
%
%         flag: [2400x3600 logical]
%     fullsize: [1x1 struct]
%          dim: [1x1 struct]
%       limits: [1x1 struct]
%          idx: [173x170 double]
%         type: 'normal'
%           iy: [173x170 double]
%           ix: [173x170 double]
%         seam: 0
%      dimPlus: [1x1 struct]
%          geo: [1x1 struct]
%          lat: [173x170 double]
%          lon: [173x170 double]
%           dy: [173x170 double]
%           dx: [173x170 double]
%
%
% (See constructGeoFile.m for details.)
%
% ------------------------------------
%
% Also needed are maps of Rossby wave phase speed (1st baroclinic) and Rossby radius in the same format and geometry as everything else.
% The files need to be here:
%
% c = load('../dataXXX/ROSSBY/RossbyPhaseSpeed.mat')
% c =
%
%     data: [YYYxXXX double]
%      lat: [YYYxXXX single]
%      lon: [YYYxXXX single]
%
% and
%
% L = load('../dataXXX/ROSSBY/RossbyRadius.mat')
% L =
%
%     data: [YYYxXXX double]
%      lat: [YYYxXXX single]
%      lon: [YYYxXXX single]
%
%
% All input parameters are to be set in INPUT.m and INPUTx.m, where 'x' is eg 'POP'.
%
% ------------------------------------
%
% In the case of new input data, an edited copy of S00a.. should suffice to get the data into required format.
% It wouldnt hurt to rewrite S00b_rossbyStuff, as its coding is rather opaque..
%
% remember to run addpath(genpath('./')) when starting matlab

%% data preparation
% S00a_prep_raw_data
% S00b_rossbyStuff
%% SSH 2 SSH-anomaly
S00c_buildMeanSsh
S00d_buildSshAnomaly
%% main steps
% S01_calc_fields     % redundant by now
S02_contours        % calc all contours of sshAnom
S03_filterContours  % main bottleneck! filter all contours to test for eddy
S04_trackEddies     % track found eddies through time dim
%% post process
P01_analyzeTracks
P02_analyzedTracks2maps
%% plotting
P03_plotting
