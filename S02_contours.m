% calculates all contours minSSH:increment:maxSSH and saves one file per timestep
% to ../dataXXX/CONTS/CONT_yyyymmdd_SSS-NNN_WWW-EEE.mat
%% init
DD    = initialise('cuts');
files = DD.checks.passed;
lims  = thread_distro(DD.threads.num,numel(files));
%% spmd
S02_main(DD,files,lims)

