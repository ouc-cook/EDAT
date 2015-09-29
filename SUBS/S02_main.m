function S02_main(DD,files,lims)
    T = disp_progress('init','getting contours! takes forever..');
    spmd(DD.threads.num)
        for ff = lims(labindex,1):lims(labindex,2)
            T = disp_progress('init',T,diff(lims(labindex,:))+1);
            get_contours(DD,files(ff));
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function get_contours(DD,file)
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
