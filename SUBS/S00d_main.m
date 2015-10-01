function S00d_main(files,sshMean)
    %% sum all SSH
    N = numel(files);
    parfor_progress(N);
    parfor ff = 1:N
        parfor_progress;
        treatFile(ff,files,sshMean)
    end
    parfor_progress(0);
end
% subtract mean from each file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function treatFile(ff,files,sshMean)
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