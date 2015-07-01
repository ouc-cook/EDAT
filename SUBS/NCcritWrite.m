function NCcritWrite(file,varname,data,strt,len)
critdir=[file '_crit']  ;  
critf=[critdir '/' sprintf('%02d',labindex)];
mkdirp(critdir)
    while true
        if isempty(ls(critdir))
            system(['touch ' critf]);
            nc_varput(file,varname,data,strt,len)
            system(['rm ' critf]);
            break
        end
        disp(['waiting - lab ' num2str(labindex)])
        sleep(.1*rand*labindex)
    end   
end



