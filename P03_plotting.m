DD = initialise;
window = getfieldload(DD.path.windowFile,'window');
meanMaps = getfieldload(sprintf('%smeanMaps.mat',DD.path.root),'meanMap');
close all
%%
% fig.means = subP03_meanMaps(DD,window,meanMaps);
fig.birthDeath = subP03_birthDeathMaps(meanMaps);
todo save to root






