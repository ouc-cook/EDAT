function avi2pop
    init_threads(12)
    dbstop if error
    ncfile.avi='../avidim.nc';
    ncfile.pop='../popdim.nc';
    path.in='/scratch/uni/ifmto/u241194/DAILY/EULERIAN/SSH/';
    path.out='/scratch/uni/ifmto/u300065/FINAL/POP2AVIssh/';
    files.in=dir2([path.in 'SSH_GLB_t.t0.1_42l_CORE.*.nc']);
    keys.lat='lat';
    keys.lon='lon';
    keys.ssh='msla';
    keys.time='time';
    %%
    [lat,lon]=inits(ncfile);
    %
    [idx]=CrossRef2Closest(lon,lat);
    %%
    ref=makeXref(idx);
    %%
    remapSSH(ref,files,path,lon)
    %
    appendLoLaTi(keys,path,lat,lon);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function appendLoLaTi(keys,path,latIn,lonIn)
    files=dir(path.out);
    parfor ii=3:numel(files)
        appendOpp(keys,path,latIn,lonIn,[path.out files(ii).name]);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function appendOpp(keys,path,latIn,lonIn,file) %#ok<*INUSL>
    if ~all(isfield(load(file),{keys.ssh,keys.lat}))
        eval([keys.ssh '=struct2array(load(file));'])
        eval([keys.lat '=latIn.avi;'])
        eval([keys.lon '=lonIn.avi;'])
        ti=datenum(file(end-11:end-4), 'yyyymmdd'); %#ok<NASGU>
        eval([keys.time '=ti;'])
        save(file,'-append',keys.ssh,keys.lat,keys.lon,keys.time);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function remapSSH(ref,files,path,lon)
    sshAvi=nan*lon.avi;
    Tf=disp_progress('init','files');
    FF=thread_distro(12,numel(files.in));
    spmd(12)
        ff=FF(labindex,1):FF(labindex,2) ;
        for f=ff
            Tf=disp_progress('c',Tf,numel(ff));
            opSSHfile(files.in(f).name,path,ref,sshAvi);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function opSSHfile(file,path,ref,sshPOP2AVI)
    outfile=[path.out file(1:end-3) '.mat'];
    if exist(outfile,'file'), return,end
    try
        ssh=ncreadOrNc_varget([path.in file],'SSH');
    catch  me
        disp(me.message)
        return
    end
    Tp=disp_progress('init','averaging');
    for ii=1:numel(ref)
        Tp=disp_progress('c',Tp,numel(ref),3);
        sshPOP2AVI(ii)=nanmean(ssh(ref{ii}));
    end
    save(outfile,'sshPOP2AVI')
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [lat,lon]=inits(ncfile)
    %%
    lat.avi=ncreadOrNc_varget(ncfile.avi,'lat');
    lon.avi=ncreadOrNc_varget(ncfile.avi,'lon');
    [lon.avi,lat.avi]=meshgrid(lon.avi,lat.avi);
    %%
    lat.pop=ncreadOrNc_varget(ncfile.pop,'U_LAT_2D');
    lon.pop=ncreadOrNc_varget(ncfile.pop,'U_LON_2D');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ref]=makeXref(idx)
    if ~exist('avi2pop.mat','file')
        ref=makeXrefCalc(idx);
    else
        load avi2pop;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ref=makeXrefCalc(idx)
%     ref=repmat({[]},Ya*Xa,1); % crossref cell arr
    [idxS,idxO]=sort(idx); %
    UN=unique(idxS); %
    [~,bin]=histc(idxS,UN); %
    fbin=find(diff(bin)); % find bin bndries
    lims =[ [1; fbin+1] [fbin; numel(bin)] ]; % from:till lims (with respect to sorted idx vec from pop)
    Tp=disp_progress('init','gffcztc');
    for ii=1:numel(UN)
        Tp=disp_progress('c',Tp,numel(UN),100);
        popx=idxO(lims(ii,1):lims(ii,2));
        avix=UN(ii);
        ref{avix}=popx;
    end
    save avi2pop ref
    system('cp avi2pop.mat /scratch/uni/ifmto/u300065/FINAL/avi2popRef.mat')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [idx]=CrossRef2Closest(lon,lat)
    if exist('idx.mat','file')
        load idx
    else
        azi=deg2rad(lon.pop(:));
        elev=deg2rad(lat.pop(:));
        [x,y,z] = sph2cart(azi,elev,1);
        qazi= deg2rad(lon.avi(:));
        qelev= deg2rad(lat.avi(:));
        [qx,qy,qz] = sph2cart(qazi,qelev,1);
        popxyz=[x,y,z];
        avixyz=[qx,qy,qz];
        JJ=thread_distro(12,numel(azi));
        
        spmd
            myII=JJ(labindex,1):JJ(labindex,2);
            fprintf('lab %d dsearchn\n',labindex);
            idx = dsearchn(avixyz,popxyz(myII,:));
            fprintf('lab %d gcat\n',labindex);
            idx = gcat(idx,1,1);
        end
        idx=idx{1};
        save idx idx
        system('cp idx.mat /scratch/uni/ifmto/u300065/FINAL/pop2aviIdx.mat')
    end
end
