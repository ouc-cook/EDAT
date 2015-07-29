DD     = initialise;
window = getfieldload(DD.path.windowFile,'window');
%%
meanMap = P02_main(DD,window);
%%
save([DD.path.root,'meanMaps.mat'],'meanMap','-append');

