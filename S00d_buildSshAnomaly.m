% subtract time-mean of SSH from SSH to build anomaly (.sshAnom)
%% init
DD = initialise('cuts');
sshMean = getfieldload(DD.path.meanSsh.file,'sshMean');
files = DD.checks.passed;
%% main
S00d_main(files,sshMean);



