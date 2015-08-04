% TODO test for global (1507)
% TODO test for aviso  (1507)

% needs one 3D salt and temperature file each
% integrates over depth to calculate
% -Brunt Väisälä frequency
% -Rossby Radius
% -Rossby wave first baroclinic phase speed
%
% The idea here is to slice the 3d T/S-files into several chunks in x-dir
% in order to perform vectorized operations without busting the memory.
% The chunks themselves are evenly distributed among the workers.
% Eventually the sliced results get concatted back together into 2d maps of
% required geometry.
% 
%% init
DD = initialise();
%% set up
TS = S00b_rossbyStuff_setUp(DD);
%% main
S00b_main(TS,DD);

