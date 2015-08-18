DD     = initialise;
window = getfieldload(DD.path.windowFile,'window');
%%
P02_main(DD,window);
%%
subP02_buildBirthDeathMaps(DD,window);
%%
subP02_distTillDeath(DD,window);