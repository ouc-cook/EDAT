function RS = subS03_getRossbyPhaseSpeedAndRadius(DD)
    RS.Lr = getfield(load([DD.path.Rossby.name 'RossbyRadius.mat']),'data');
    RS.c  = getfield(load([DD.path.Rossby.name 'RossbyPhaseSpeed.mat']),'data');
    %% limit c to given threshold
    tooFast = abs(RS.c) > DD.thresh.phase;
    RS.c(tooFast) = sign(RS.c(tooFast)) * abs(DD.thresh.phase);
end