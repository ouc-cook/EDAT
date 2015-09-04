% build time-mean of SSH
% mean of SSH is saved to ../dataXXX/meanSSH.mat
% is skipped if raw input is anomaly already
%% init
DD = initialise('cuts');
window = getfieldload(DD.path.windowFile,'window');
files = DD.checks.passed;
%% depending on whether anomaly exists already or not...
if DD.switches.isAnomaly
    subS00c_isAnomalyAlready(DD,window,files);
else
    subS00c_needToBuildAnomaly(DD,window,files);
end
