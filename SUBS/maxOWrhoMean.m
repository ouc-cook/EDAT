%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 16-Jul-2014 13:52:44
% Computer:GLNX86
% Matlab:7.9
% Author:NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxOWrhoMean; dF;load DD
    TSow.dir='/scratch/uni/ifmto/u300065/datanetU2/Rossby';
       DD.MD.sMean = initbuildRhoMean(TSow); %#ok<NODEF>
%    DD.MD.sMean = initbuildRhoMean(DD.path.TSow); %#ok<NODEF>
    buildRhoMean(DD.threads.num,DD.MD.sMean,DD.Dim);
    save DD;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s] = initbuildRhoMean(TSow); dF
    %% recheck
    s.files=dir2cell(TSow.dir, 'rho_*.nc');
    s.Fout=[TSow.dir 'RHOmean.nc'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  buildRhoMean(threads,s,Dim); dF
    f=funcs;
    if ~exist(s.Fout,'file')
        rhoMean=buildRhoMeanOperate(threads,s,Dim);
        f.ncvp([s.Fout 'tmp'],'RhoMean',f.mDit(rhoMean,Dim.ws),[0 0 0], [Dim.ws]);
        system(['mv ' s.Fout 'tmp ' s.Fout]);
    else
        kugzfzitf
        disp('rho_mean exists. skipping...');sleep(1);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  rhoMean=buildRhoMeanOperate(threads,s,Dim); dF
    f=funcs;
    if ~exist([s.Fout 'tmp'],'file')
        initNcFile([s.Fout 'tmp'],'RhoMean',Dim.ws);
    end
    %%
    spmd(threads)
        dispM('codstributing')
        rhoMean = f.locCo(nan(Dim.ws),1);
        labBarrier
    end
    %%
    spmd(threads)
        rhoMean=spmdRhoMeanBlock(f,s,rhoMean);
        dispM('vertcatting')
        rhoMean=gop(@vertcat,rhoMean,1);
        labBarrier
    end
    rhoMean=rhoMean{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rhoMean=spmdRhoMeanBlock(f,s,rhoMean); dF
    T=disp_progress('init','building density mean')  ;
    for ff = 1:numel(s.files)
        T=disp_progress('show',T,numel(s.files),100)  ;
        dispM('codstributing')
        rhoMnew=f.locCo(f.ncvg(s.files{ff},'density'),1);
        dispM('summing')
        rhoMean=multiDnansum(rhoMean,rhoMnew);
    end
    dispM('dividing')
    rhoMean=rhoMean./numel(s.files);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=funcs
    f.oneDit = @(md) reshape(md,[],1);
    f.mDit = @(od,ws) reshape(od,[ws(1),ws(2),ws(3)]);
    f.locCo = @(x,dim) getLocalPart(codistributed(x,codistributor1d(dim)));
    f.yx2zyx = @(yx,Z) f.oneDit(repmat(permute(yx,[3,1,2]),[Z,1,1]));
    f.ncvp = @(file,field,array,Ds,De) nc_varput(file,field,array,Ds,De);
    %%
    f.ncvg = @(file,field) nc_varget(file,field);
    f.nansumNcvg = @(A,file,field,dim) nansum([A,f.locCo(f.ncvg(file,field),dim)],2);
    f.ncv=@(d,field) nc_varget(d,field);
    f.ncvOne = @(A) getLocalPart(codistributed(A,codistributor1d(1)));
    f.repinZ = @(A,z) repmat(permute(A,[3,1,2]),[z,1,1]);
    f.ncVP = @(file,OW,field)  nc_varput(file,field,single(OW));
    f.vc2mstr=@(ow,dim) gcat(ow,dim,1);
    f.getHP = @(cf,f) f.ncvOne(f.ncv(cf,'density'));
    f.slMstrPrt = @(p) p{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initNcFile(fname,toAdd,WinSize); dF
    nc_create_empty(fname,'clobber');
    nc_adddim(fname,'k_index',WinSize(1));
    nc_adddim(fname,'i_index',WinSize(3));
    nc_adddim(fname,'j_index',WinSize(2));
    %%
    varstruct.Name = toAdd;
    varstruct.Nctype = 'double';
    varstruct.Dimension = {'k_index','j_index','i_index' };
    nc_addvar(fname,varstruct)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
