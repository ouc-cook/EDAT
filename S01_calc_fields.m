% calculates geostrophic data from ssh.
%
% this is the first 'official' step.
% input data MUST be of the form
% ../dataXXX/CUTS/CUT_yyyymmdd_SSS-NNN_WWW-EEE.mat
% with field .sshAnom
%
% also needed is ../dataXXX/window.mat as produced by S00a_prep_raw_data
% note: this step is quasi redundant now (15/08)
%% init
DD = initialise('cuts');
%% read input file
window = getfieldload(DD.path.windowFile,'window');
coriolis = S01_coriolisStuff(window.lat);
files = DD.checks.passed;
%% maibn
S01_main(coriolis,window,files)
%% save coriolis fields
save(DD.path.coriolisFile,'coriolis');

