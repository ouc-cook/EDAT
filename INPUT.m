% templates :
% 'pop' - template for POP SSH data
% 'aviso' - template for AVISO SSH data
function DD=INPUT
    %DD.template = 'aviso';
    DD.template = 'pop';
%     DD.template = 'pop2avi';

    %% threads / debug
    DD.threads.num = 4;

    %% overwrite data
    DD.overwrite = false;

    %% time
    DD.time.from.str  = '19990101'; %first pop/avi
    DD.time.till.str  = '19991001';
    DD.time.delta_t   = 7; % [days]!
    threshlife        = 35;

    %% window on globe (0:360° system)
    DD.map.in.west  =  0;
    DD.map.in.east  =  30;
    DD.map.in.south = -50;
    DD.map.in.north = -30;

    %% thresholds
    DD.contour.step                = 0.01; % [SI]
    DD.thresh.maxRadiusOverRossbyL = 4; %[ ]
    DD.thresh.minRossbyRadius      = 20e3; %[SI]
    DD.thresh.amp                  = DD.contour.step; % [SI]
    DD.thresh.shape.iq             = 0.55; % isoperimetric quotient [ ]
    DD.thresh.corners.min          = 10; % min number of data points for the perimeter of an eddy[ ]
    DD.thresh.corners.max          = 500; % dont make too small! [ ]
    DD.thresh.life                 = threshlife; % min num of living days for saving [days]
    DD.thresh.IdentityCheck        = 2; % 1: perfect fit, 2: 100% change ie factor 2 in either sigma or amp
    DD.thresh.phase                = 42; % max(abs(rossby phase speed)) (upper lim to c-field) [SI]

    %% parameters
    DD.parameters.fourierOrder	   = 4;
    DD.parameters.zoomIncreaseFac  = 6;
    DD.parameters.minProjecDist    = 350e3; % (per week)  minimum linear_eccentricity*2 of ellipse (see chelton 2011)
    DD.parameters.trackingRef      = 'CenterOfVolume'; % choices: 'centroid', 'CenterOfVolume', 'Peak'
    DD.parameters.rossbySpeedFactor= 1.75; % eddy translation speed assumed factor*rossbyWavePhaseSpeed for tracking projections

end
