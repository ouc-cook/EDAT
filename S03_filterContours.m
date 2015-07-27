% walks through all the contours and decides whether they qualify.
% saves per time-step one struct(numel(eddies)) as
% ../dataXXX/EDDYS/EDDY_yyyymmdd_SSS-NNN_WWW-EEE.mat.

%% init
DD = initialise('conts');
DD.map.window = getfieldload(DD.path.windowFile,'window');
fopt = fitoptions('Method','Smooth','SmoothingParam',0.99);
save fopt fopt
rossby = subS03_getRossbyPhaseSpeedAndRadius(DD);
files = DD.checks.passed;
lims  = thread_distro(DD.threads.num,numel(files));
%% main
S03_main(DD,rossby,files,lims);
system('rm fopt.mat'); % TODO

