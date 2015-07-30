% TODO test for global
% TODO test for aviso
% TODO comment
% needs one 3D salt and temperature file each
% integrates over depth to calculate
% -Brunt Väisälä frequency
% -Rossby Radius
% -Rossby wave first baroclinic phase speed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% init
DD = initialise();
%% set up
TS = S00b_rossbyStuff_setUp(DD);
%% main
S00b_main(TS,DD)

