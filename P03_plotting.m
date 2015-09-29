DD = initialise;
window = getfieldload(DD.path.windowFile,'window');
meanMaps = load(sprintf('%smeanMaps.mat',DD.path.root));
%%
subP03_meanMaps;
% %%
subP03_birthDeath(DD,meanMaps.tillDeath.x,meanMaps.tillDeath.y,meanMaps.birth,meanMaps.death,meanMaps.lon,meanMaps.lat);
% %%
subP03_makeNetCdf(DD,meanMaps);
% %%
subP03_drawTracks(DD,window);
%%
subP03_hists(DD);
%%
subP03_drawTracksAge(DD);
%%
subP03_drawTracksColorSize
%%
subP03_contourSSHwithDetectedContsOverlay(DD,window);