DD = initialise;
window = getfieldload(DD.path.windowFile,'window');
meanMaps = getfieldload(sprintf('%smeanMaps.mat',DD.path.root),'meanMap');
%%
% subP03_meanMaps(DD,window,meanMaps);
%%
subP03_makeNetCdf(DD,window,meanMaps);




% save([DD.path.root,'figures.mat'])

% todo save to root






