% inter-allocate different time steps to determine tracks of eddies
%% init
DD = initialise('eddies');
DD.map.window = getfieldload(DD.path.windowFile,'window');
%% rm old files
if ~isempty(DD.path.tracks.files) && DD.overwrite
    warning('rm''ing old tracks...'); sleep(5)    ;
    system(['rm -r ' DD.path.tracks.name '*.mat']);
end
%%
init_threads(2);
%% main
S04_main(DD);

