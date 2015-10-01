DD     = initialise;
window = getfieldload(DD.path.windowFile,'window');
%%
meanMap = subP02_initMeanMap(window.geo);
%% daily (u v etc)
subP02_daily(DD,meanMap);
%% original time-step
subP02_dt(DD,meanMap);
%% visits
subP02_visits;
%%
subP02_buildBirthDeathMaps(DD,meanMap);
%%
subP02_distTillDeath(DD,meanMap);
