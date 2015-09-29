% post-processing I
%%
DD = initialise;
tracks = DD.path.tracks.files;
lims = thread_distro(DD.threads.num,numel(tracks));
%% this step creates one new analysed file in ANALYSED per track file in TRACKS
P01_main(DD,tracks,lims);

