function [pattern,FieldKeys] = patternsAndKeys  
    %% dir and file formats
    pattern.fname = 'CUT_yyyymmdd_SSS-NNN_WWW-EEE.mat';
    pattern.prefix.cuts = 'CUT';
    pattern.prefix.conts = 'CONT';
    pattern.prefix.eddies = 'EDDIE';
    pattern.prefix.tracks = 'TRACK';
    %% fields that must end with .mean and .std - for output plot maps %
    FieldKeys.MeanStdFields =  { ...
        'age';
        'dist.traj.fromBirth';
        'dist.traj.tillDeath';
        'dist.zonal.fromBirth';
        'dist.zonal.tillDeath';
        'dist.merid.fromBirth';
        'dist.merid.tillDeath';
        'radius.mean';
        'radius.zonal';
        'radius.meridional';
        'vel.traj';
        'vel.zonal';
        'vel.merid';
        'amp.to_contour';
        'amp.to_ellipse';
        'amp.to_mean';
        'iq';
        };  
    FieldKeys.senses =  { ...
        'AntiCycs';
        'Cycs';
        };
    %% Rossby
    FieldKeys.Rossby  =  { ...
        'RossbyPhaseSpeed'   ;
        'RossbyRadius' ;
        };
end