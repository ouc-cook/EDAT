DD     = initialise;
window = getfieldload(DD.path.windowFile,'window');
%% u v scale direction
P02_main(DD,window);
%% amp
subP02_amp(DD,window)
%%
subP02_
%%
subP02_buildBirthDeathMaps(DD,window);
%%
subP02_distTillDeath(DD,window);