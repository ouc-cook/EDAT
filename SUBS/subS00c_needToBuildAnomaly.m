% build time-mean over all SSH of given time span.
function subS00c_needToBuildAnomaly(DD,window,files)
    prmt = @(x) permute(x,[3,1,2]);
    %% sum all SSH
    sshSum = prmt(nan(window.dimPlus.y,window.dimPlus.x)); % init
    lims = thread_distro(DD.threads.num,numel(files));
    spmd(DD.threads.num)
        T = disp_progress('init','building temporal mean over all ssh');
        for ff = lims(labindex,1):lims(labindex,2)
            T = disp_progress('show',T,diff(lims(labindex,:))+1);
            %% load
            ssh = prmt(getfield(getfieldload(files(ff).filenames,'fields'),'ssh'));
            %% sum ssh
            sshSum = nansum([sshSum; ssh],1);
        end
        %% vertstack partial sums from workers
        sshSumGopped = gop(@vertcat,sshSum,1);
    end
    %% sum partial sums
    sshSum =  squeeze(nansum(sshSumGopped{1},1));
    %% build mean
    sshMean = sshSum./ numel(files); %#ok<NASGU>
    %% save
    save(DD.path.meanSsh.file,'sshMean');    
end