DD = initialise;
% window = getfieldload(DD.path.windowFile,'window');
% meanMaps = load(sprintf('%smeanMaps.mat',DD.path.root));
% %%
% subP03_meanMaps(DD,window,meanMaps);
% %%
% subP03_birthDeath(DD,meanMaps.tillDeath.x,meanMaps.tillDeath.y,meanMaps.birth,meanMaps.death,meanMaps.lon,meanMaps.lat);
% %%
% subP03_makeNetCdf(DD,window,meanMaps);
% %%
% subP03_drawTracks(DD,window);
%%
subP03_hists(DD);
