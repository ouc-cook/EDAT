% HOWTO for applying algorithm to depth:

% first we build 3d density .nc's via (set dirs in main function)
makeDensity;

% then we build 2d pressure .nc's via (set depth level in function)
makePressureAtZ;

% with those we build "pseudo"-SSH .nc's akin to those from POP output (set outputdir in function and set depth level to that of the previous step!)
makePseudoSshFromP;

% now choose
% DD.template = 'depth';
% in INPUT.m

% and set depth level (same as above) and corresponding input dir (DD.path.raw.name) in INPUTdepth.m
% now run Sall.m as usual
