% split number of loop iterations into chunks for spmd
% from-to_array=thread_distro(threads,steps)
function lims=thread_distro(threads,steps)
    lims=nan(threads,2);
    distemp=round(linspace(1,steps+1,threads+1));
    lims(:,1)=distemp(1:end-1);
    lims(:,2)=lims(:,1)+diff(distemp)'-1;
    if threads>steps
        lims=thread_distro(steps,steps);
        lims(end+1:threads,:)=repmat([1 0],threads-steps,1);
    end
end