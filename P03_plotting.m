DD = initialise;
window = getfieldload(DD.path.windowFile,'window');
meanMaps = load(sprintf('%smeanMaps.mat',DD.path.root));
%%
subP03_meanMaps(DD,window,meanMaps.meanMap);
%%
subP03_birthDeath(DD,meanMaps.birth,meanMaps.death,meanMaps.meanMap.lon,meanMaps.meanMap.lat);
%%
subP03_makeNetCdf(DD,window,meanMaps);




% save([DD.path.root,'figures.mat'])

% todo save to root






