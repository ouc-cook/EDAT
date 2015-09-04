DD     = initialise;
% window = getfieldload(DD.path.windowFile,'window');
window = constructGeoFile(DD); % if tracks have changed do this (to remove index data)


%% u v scale direction
P02_main(DD,window);
%% amp
subP02_amp(DD,window)
%% amp
subP02_age(DD,window)
%%
subP02_buildBirthDeathMaps(DD,window);
%%
subP02_distTillDeath(DD,window);