function maxOWprocCalc
    load NC
    % 	load logOwMean
    NC.Yref=500;
    NC.yxref=[1570, 530];
    main(NC)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(NC)
    %%
    [deepestLin, NC.codi]=preploop(NC);
    %%
    T=disp_progress('init','min OW''s')  ;
    for tt=1:NC.S.T
        T=disp_progress('show',T,NC.S.T);
        %% get min in z
        NC.currFile=NC.files(tt).full;
        %%
        calcMinZi(NC,tt,deepestLin)
        %%
        calcYref(NC,tt)
        %%
        calcXYref(NC,tt)
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=funcs
    f.locNC=@(in,codi) getLocalPart(codistributed(nc_varget(in,'OkuboWeiss'),codi));
    f.locCo=@(in,codi) getLocalPart(codistributed(in,codi));
    f.ncPut=@(n,f,data)  nc_varput(n.(f).fileName ,n.(f).varName,data);
    f.ncPutBig=@(n,f,data,t,s)  nc_varput(n.(f).fileName ,n.(f).varName,data,[t,0,0],[1 s.Y s.X]);
    f.ncPutYref=@(n,f,data,t,s)  nc_varput(n.(f).fileName ,n.(f).varName,data,[t,0,0],[1 s.Z s.X]);
    f.ncPutXYref=@(n,f,data,t,s)  nc_varput(n.(f).fileName ,n.(f).varName,data,[t,0,0],[1 s.Z s.X]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [deepestLin,codi]=preploop(NC)
    codi=codistributor1d(3);
    %% get bathymetry
    [~,deepest]=max(~isnan(nc_varget(NC.files(1).full,'OkuboWeiss')));
    ndgridFromSize=@(in)  ndgrid(1:size(in,1),1:size(in,2));
    [Y,X]=ndgridFromSize(squeeze(deepest));
    deepestLin = sub2ind([NC.S.Z,NC.S.Y,NC.S.X], deepest(:), Y(:), X(:));
    for dd=1:3  %dd'th deepest
        deepest  = deepest -1;
        deepest(deepest==0)=1;
        deepestLin = [reshape(deepestLin,1,[]) reshape(sub2ind([NC.S.Z,NC.S.Y,NC.S.X], deepest(:), Y(:), X(:)),1,[])];
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calcMinZi(NC,tt,deepestLin)
    f=funcs;
    %% kill bottom layer
    data = nc_varget(NC.currFile,'OkuboWeiss');
    data(deepestLin)=nan;
    
    %% kill surface layer
    data(1:5,:,:)=nan;
    
    %%
    spmd
        mydata=log10OW(smooth3(f.locCo(data,NC.codi)),nan);
        [owMin_t,MinZi_t]=nanmax(mydata(:,:,:),[], 1);
        MinZi_t=gcat(squeeze(MinZi_t),2,1);
        owMin_t=gcat(squeeze(owMin_t),2,1);
    end
    MinZi=MinZi_t{1};
    owMin=owMin_t{1};
    
     %% if MinZi==bottom , nan out
    
    MinZi=MinZi + 1;
    MinZi(MinZi==NC.S.Z+1)=NC.S.Z;
    [Y,X]=ndgrid(1:NC.S.Y,1:NC.S.X);
    lowest=sub2ind([NC.S.Z,NC.S.Y,NC.S.X], MinZi(:), Y(:), X(:));
    flag=isnan(data(lowest));    
    flag=  reshape((MinZi==6),NC.S.Y,NC.S.X) |  reshape((MinZiplus==NC.S.Z),NC.S.Y,NC.S.X) | reshape(flag,NC.S.Y,NC.S.X);
    
   
    
   owMin(flag)=nan;
   latMeanOW=repmat(nanmean(owMin,1),NC.S.Y,1); 
   owMin(owMin<lonMeanOW+2)=nan;
   
   owMin(isnan(owMin) | isnan(MinZi) )=nan;
   MinZi(isnan(owMin) | isnan(MinZi) )=nan;
   
   subplot(211)
    ppc(owMin);colorbar;caxis([-10 -7]); colormap([[1 1 1]; jet])
   subplot(212);colorbar
    ppc(MinZi); colormap([[1 1 1]; jet])
    %% put to big files
    f.ncPutBig(NC.new,'minOWzi',MinZi,tt-1,NC.S);
    f.ncPutBig(NC.new,'minOW',owMin,tt-1,NC.S);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calcYref(NC,tt)
    f=funcs;
    spmd
        mydata= 		log10OW(f.locNC(NC.currFile,NC.codi),nan);
        owYref=gcat(squeeze(mydata(:,NC.Yref,:)),2,1);
    end
    owYref=owYref{1};
    %% put to big files
    f.ncPutYref(NC.new,'owYref',owYref,tt-1,NC.S);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function calcXYref(NC,tt)
    f=funcs;
    owXY=log10OW(nc_varget(NC.currFile,'OkuboWeiss',[0 NC.yxref(1)-1 0],[inf 1 inf]),nan);
    f.ncPutXYref(NC.new,'owXYref',squeeze(owXY),tt-1,NC.S);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [OW]=log10OW(OW,dummy)
    tag=isnan(OW) | isinf(OW) | OW>=0;
    OW(tag)=dummy;
    OW=log10(-OW);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%