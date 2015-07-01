%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 04-Apr-2014 16:53:06
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculates all contours and saves one file per timestep
function S03_contours
    %% init
    DD = initialise('cuts',mfilename);
    %% spmd
    main(DD)
    %% save info
%     conclude(DD);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(DD)
    if DD.debugmode
        spmd_body(DD);
    else
        spmd(DD.threads.num)
            spmd_body(DD);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmd_body(DD)
    %% loop over ssh cuts
    [TT] = SetThreadVar(DD);
    II.T = disp_progress('init',['...']);
    for cc = 1:numel(TT)
        II.T = disp_progress('calc', II.T, numel(TT), 100);
        %% contours
        get_contours(DD,TT(cc));
    end
    disp_progress('conclude');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function get_contours(DD,TT)
    %%
    CONT.filename = [DD.path.conts.name DD.pattern.prefix.conts TT.protos];
    %% check
    if exist(CONT.filename,'file') && ~DD.overwrite
        dispM([CONT.filename ' exists'])
        return
    end
    %% init
    [II] = init_get_contours(DD,TT);
    %% loop over levels
    CONT.all = contourc(II.fields.ssh,II.levels)';
    %% save data
    save(CONT.filename,'-struct','CONT');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [II] = init_get_contours(DD,TT)
    %% load cut
    II.file = TT.files;
    II.fields = getfield(load(II.file),'fields');
    %% calc contours
    dispM('calculating contours... takes long time!',1)
    %% create level vector at chosen interval
    steplim.min = @(step,ssh) ceil(nanmin(ssh(:))/step)*step;
    steplim.max = @(step,ssh) floor(nanmax(ssh(:))/step)*step;
    floorlevel = steplim.min(DD.contour.step,II.fields.ssh);
    ceillevel = steplim.max(DD.contour.step,II.fields.ssh);
    II.levels = floorlevel:DD.contour.step:ceillevel;
end
