%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculates all contours minSSH:increment:maxSSH and saves one file per timestep
function S02_contours
    %% init
    DD = initialise('cuts');
    %% spmd
    main(DD)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    %% init
    files = DD.checks.passed;
    %%
    parfor_progress(numel(files))
    parfor ff = 1:numel(files)
        get_contours(DD,files(ff));
    end
    parfor_progress(0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function get_contours(DD,file)
    parfor_progress;
    CONT.filename = strrep(file.filenames,'CUT',DD.pattern.prefix.conts);
    %% check
    if exist(CONT.filename,'file') && ~DD.overwrite
        disp([CONT.filename ' exists'])
        return
    end
    %% init
    [ssh,levels] = init_get_contours(DD.contour.step,file.filenames);
    %% loop over levels
    CONT.all = contourc(ssh,levels)';
    %% save data
    save(CONT.filename,'-struct','CONT');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ssh,levels] = init_get_contours(increment,file)
    %% load cut
    ssh = getfield(getfield(load(file),'fields'),'sshAnom');
    %% create level vector at chosen interval
    steplim.min = @(step,ssh) ceil(nanmin(ssh(:))/step) *step;
    steplim.max = @(step,ssh) floor(nanmax(ssh(:))/step)*step;
    %%
    floorlevel = steplim.min(increment,ssh);
    ceillevel = steplim.max(increment,ssh);
    levels = floorlevel:increment:ceillevel;
end
