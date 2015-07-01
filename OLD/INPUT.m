% templates :
% 'udef' - user defined in INPUTuserDef.m
% 'pop' - template for POP SSH data
% 'aviso' - template for AVISO SSH data
% 'mad' - template for Madeleine's data
function DD=INPUT
    %DD.template='depth';
    %DD.template='pop2avi';
%    DD.template='aviso';
    DD.template='pop';
    %% threads / debug
<<<<<<< HEAD
    DD.threads.num = 22;
=======
    DD.threads.num = 4;
>>>>>>> pop7II
    DD.debugmode   = false;
%     DD.debugmode = true;
    DD.overwrite   = false;
<<<<<<< HEAD
    %         DD.overwrite = true;
    %% time
    DD.time.from.str  = '19940105'; %first pop/avi
    %     DD.time.till.str  = '19940305';
    
%     DD.time.till.str  = '19970403';
    
%        DD.time.from.str  = '19970405';
 %           DD.time.till.str  = '20000704';
    
% DD.time.from.str = '20000706'
DD.time.till.str = '20061227'

    %     DD.time.till.str  = '20000701';
    
    %     DD.time.from.str  = '20050103'
    %     DD.time.till.str  = '20061227'; % last pop/avi
    
    
    DD.time.delta_t   = 2; % [days]!
    threshlife        = 30; % TODO
=======
%     DD.overwrite = true;
    %% time
    DD.time.from.str  = '19940105'; %first pop/avi
%     DD.time.till.str  = '20020105'; %first pop/avi
    DD.time.till.str  = '20061227'; % last pop/avi
    DD.time.delta_t   = 7; % [days]!
    threshlife        = 7*8; % TODO
>>>>>>> pop7II
    %% window on globe (0:360° system)
    DD.map.in.west  =  0;
    DD.map.in.east  =  360;
    DD.map.in.south = -80;
    DD.map.in.north =  80;
<<<<<<< HEAD
    
    
=======
>>>>>>> pop7II
    %% thresholds
    
    DD.contour.step                = 0.01; % [SI]
    DD.thresh.radius               = 0; % [SI]
    DD.thresh.maxRadiusOverRossbyL = 4; %[ ]
    DD.thresh.minRossbyRadius      = 20e3; %[SI]
    DD.thresh.amp                  = DD.contour.step; % [SI]
    DD.thresh.shape.iq             = 0.55; % isoperimetric quotient [ ]
    DD.thresh.corners.min          = 10; % min number of data points for the perimeter of an eddy[ ]
    DD.thresh.corners.max          = 500; % dangerous.. [ ]
    DD.thresh.life                 = threshlife; % min num of living days for saving [days]
    DD.thresh.ampArea              = [.25 2.5]; % allowable factor between old and new time step for amplitude and area (1/4 and 5/2 ??? chelton)
    DD.thresh.IdentityCheck        = 2; % 1: perfect fit, 2: 100% change ie factor 2 in either sigma or amp
<<<<<<< HEAD
    DD.thresh.phase                = 1; % max(abs(rossby phase speed)) [SI]
    %% switches
    
=======
    DD.thresh.phase                = 0.2; % max(abs(rossby phase speed)) [SI]
     %% switches

>>>>>>> pop7II
    %% 1 for I    -    0 for II
    DD.switchs.chelt = 0;
    
    DD.switchs.AmpAreaCheck  =  DD.switchs.chelt;
    DD.switchs.IQ            = ~DD.switchs.chelt;
    DD.switchs.IdentityCheck = ~DD.switchs.chelt;
<<<<<<< HEAD
    
=======



>>>>>>> pop7II
    %% TODO
    DD.switchs.netUstuff = 0;
    DD.switchs.meanUviaOW = 0;
    DD.switchs.RossbyStuff = 1;  % TODO no choice
    DD.switchs.distlimit = 1;      % TODO no choice
    DD.switchs.maxRadiusOverRossbyL = 1;  % TODO no choice
    DD.switchs.spaciallyFilterSSH = 0;  % TODO delete
    DD.switchs.filterSSHinTime = 1;
    %%
    DD.parameters.fourierOrder		= 4;
end
