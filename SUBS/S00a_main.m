% sub to ../S00a_prep_raw_data
function S00a_main(DD,window,cc)
    parfor_progress;
    %% get file name
    file.in    = DD.checks.passed(cc).filenames;
    timestring = DD.time.timesteps.s(cc,:);
    file.out   = NSWE2nums(DD.path.cuts.name,DD.pattern.fname,DD.map.in,timestring);
    %% cut data
    try
        CUT  = CutMap(DD,file.in,window);
    catch readerr
        warning('cant read %s! skipping!',file.in);
        disp(readerr.message);
        return
    end
    %% write data
    WriteFileOut(file.out,CUT);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [CUT] = CutMap(DD,file,window)
    %% get data
    keys.ssh = DD.map.in.keys.ssh;
    [raw_field] = GetFields(file,keys);
    %% cut
    [CUT.fields] = cutSlice(raw_field,window.idx);
    %% nan out land and make SI
    CUT.fields.ssh = nanLand(CUT.fields.ssh,DD.parameters.ssh_unitFactor);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out=nanLand(in,fac)
    %% nan and SI
    out=in / fac;
    out(out==0)=nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function WriteFileOut(file,CUT) %#ok<INUSD>
    tempfile = [fileparts(file) tempname];
    save(tempfile,'-struct','CUT');
    system(sprintf('mv %s.mat %s',tempfile,file)) ;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

