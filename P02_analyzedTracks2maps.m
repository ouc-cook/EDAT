DD     = initialise;
window = getfieldload(DD.path.windowFile,'window');
%% daily (u v etc)
subP02_daily(DD,window);
%% original time-step
subP02_dt(DD,window);
%%
subP02_buildBirthDeathMaps(DD,window);
%%
subP02_distTillDeath(DD,window);
