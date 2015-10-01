% simply renaming ssh to sshAnom
function subS00c_isAnomalyAlready(files)
  T = disp_progress('init','renaming ssh to sshAnom');
    for ff = 1:numel(files)
        T = disp_progress('show',T,numel(files));
        %% load
        fields = getfieldload(files(ff).filenames,'fields');
        %% rename
        fields.sshAnom = fields.ssh;
        fields.ssh = [];
        %% save
        save(files(ff).filenames,'fields','-append');
    end   
end