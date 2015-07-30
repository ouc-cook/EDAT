% build time-mean of SSH
% mean of SSH is saved to ../dataXXX/meanSSH.mat
% skip this and S00d_buildSshAnomaly if input data is SSH anomaly already
% (eg aviso)
% TODO implement skipping (see above) ie .ssh must be called .sshAnom a
% priori somehow
%% init
DD = initialise('cuts');
window = getfieldload(DD.path.windowFile,'window');
prmt = @(x) permute(x,[3,1,2]);
files = DD.checks.passed;
%% sum all SSH
sshSum = prmt(nan(window.dimPlus.y,window.dimPlus.x));
h = waitbar(0,'Initializing waitbar...');
for ff = 1:numel(files) % TODO make parallel
    perc=round(ff/numel(files)*100);
    waitbar(perc/100,h,sprintf('%d%% along...',perc))
    %% load
    ssh = prmt(getfield(getfieldload(files(ff).filenames,'fields'),'ssh'));
    %% mean ssh
    sshSum = nansum([sshSum; ssh],1);
end
close(h)
%% build mean
sshMean = squeeze(sshSum)./ numel(files);
%% save
save(DD.path.meanSsh.file,'sshMean');
