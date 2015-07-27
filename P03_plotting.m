DD = initialise;
window = getfieldload(DD.path.windowFile,'window');
meanMaps = getfieldload(sprintf('%smeanMaps.mat',DD.path.root),'meanMap');
%%

subP03_meanMaps(DD,window,meanMaps);







