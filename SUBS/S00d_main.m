function S00d_main(files,sshMean)
    %% sum all SSH
    N = numel(files);
    parfor_progress(N);
    parfor ff = 1:N
        parfor_progress;
        loopOverFiles(ff,files,sshMean)
    end
    parfor_progress(0);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loopOverFiles(ff,files,sshMean)
    currentFile = files(ff).filenames;
    %% load
    cut = load(currentFile);
    %% subtract
    cut.fields.sshAnom = cut.fields.ssh - sshMean;
    %% save
    tmpFN = [fileparts(currentFile) tempname '.mat'];
    save(tmpFN,'-struct','cut');
    system(sprintf('mv %s %s',tmpFN,currentFile));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%