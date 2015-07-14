% calculates geostrophic data from ssh
function S01_calc_fields
    %% init
    DD = initialise('cuts');
    %% read input file
    window = getfieldload(DD.path.windowFile,'window');
    coriolis = coriolisStuff(window.lat);
    %% spmd
    main(DD,coriolis,window)
    %% save coriolis fields
    save(DD.path.coriolisFile,'coriolis');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD,coriolis,window)
    %% init
    files = DD.checks.passed;
    %% loop
    parfor_progress(numel(files));
    parfor ff = 1:numel(files)
        loopOverCuts(coriolis,files,window,ff);
    end
    parfor_progress(0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loopOverCuts(coriolis,files,window,ff)
    parfor_progress;
    currentFile = files(ff).filenames;
    %% load
    cut = load(currentFile);
    %% calc
    fields = geostrophy(window,cut.fields,coriolis); %#ok<NASGU>
    %% write
    save(currentFile,'fields','-append');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fields = geostrophy(window,fields,corio)
    %% ssh gradient
    [sshgrad_x,sshgrad_y] = dsshdxi(fields.sshAnom,window.dx,window.dy);
    %% velocities
    fields.U = -corio.GOverF .* sshgrad_y;
    fields.V =  corio.GOverF .* sshgrad_x;
    fields.absUV = hypot(abs(fields.U),abs(fields.V));
    %% 2d - deformation
    def = deformation(fields,window.dx,window.dy);
    %% okubo weiss in 2d
    fields.OkuboWeiss = 4*(def.dVdx .* def.dUdy + def.dUdx.^2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function def = deformation(fields,dx,dy)
    %% calc U gradients
    dUdy = diff(fields.U,1,1);
    dUdx = diff(fields.U,1,2);
    dVdy = diff(fields.V,1,1);
    dVdx = diff(fields.V,1,2);
    def.dUdy = dUdy([1:end, end], :)  ./ dy;
    def.dUdx = dUdx(:,[1:end, end] )  ./ dx;
    def.dVdy = dVdy([1:end, end], :)  ./ dy;
    def.dVdx = dVdx(:,[1:end, end] )  ./ dx;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [dsshdx,dsshdy] = dsshdxi(ssh,dx,dy)
    %% calc ssh gradients
    dsshx = diff(ssh,1,2);
    dsshy = diff(ssh,1,1);
    dsshdx = dsshx(:,[1:end, end])./ dx;
    dsshdy = dsshy([1:end, end],:)./ dy;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = coriolisStuff(lat)
    %% omega
    out.Omega = angularFreqEarth;
    %% f
    out.f = 2*out.Omega*sind(lat);
    %% beta
    out.beta = 2*out.Omega/earthRadius*cosd(lat);
    %% gravity
    out.g = sw_g(lat,zeros(size(lat)));
    %% g/f
    out.GOverF = out.g./out.f;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
