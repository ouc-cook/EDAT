function maxOWprocMeanOW
    load NC
    main(NC);
    %     save OwMean
    %     nc_varput(NC.new.OWmean.fileName ,NC.new.OWmean.varName,OwMean);
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function main(NC)
%     owatzz=nan(NC.S.T,2400,3600);
%     files=NC.files;
%     T=NC.S.T;
%     parfor zz=1:NC.S.Z
%         flipZtoT(zz,files,T,owatzz)
%         labBarrier
%     end
%     toc
    
    
    %%
    for zz=1:NC.S.Z
        zfile=sprintf('OWat%02d.mat',zz);
        load(zfile)
        AMEAN(zz,:,:)=MEAN;
        AMED(zz,:,:)=MEDIAN;
        ASTD(zz,:,:)=STD;
        %         AMEAN(zz,:,:)=smooth2a(MEAN,3);
        %         AMED(zz,:,:)=smooth2a(MEDIAN,3);
        %         ASTD(zz,:,:)=smooth2a(STD,3);
    end
    
    save('MEAN.mat','AMEAN','-v7.3')
    save('MEDIAN.mat','AMED','-v7.3')
    save('STD.mat','ASTD','-v7.3')
    AMEANoMED=AMEAN./AMED;
    save('MEAoMED.mat','AMEANoMED','-v7.3')
    
    depth=nc_varget('/scratch/uni/ifmto/u300065/FINAL/okuboWeiss/LatLonDepth.nc','depth');
    
    cm=[[1 1 1]; jet];
    load MEAoMED
    
    AMEANoMED(1:9,:,:)=nan;
    
    allmeanAMEANoMED=nanmean(AMEANoMED(:))
    
    for zz=10:NC.S.Z
        ppc(AMEANoMED(zz,:,:))
        colormap(cm)
        caxis([1 10]);
        title(sprintf('depth: %04dm',round(depth(zz))))
        colorbar('off')
        if zz==10
            colorbar('westOutside')
        end
        axis tight off
        saveas(gcf,'a.png')
        system(sprintf('convert -trim a.png OWmeanOmedScale0-10_frame%02d.png',zz))
    end
    
    
    
    
    [AMEANoMEDmax,AMEANoMEDmaxZi]=nanmax(AMEANoMED,[],1);
    ppc(AMEANoMEDmaxZi)
    cm2=[[.5 .5 .5]; hsv];colormap(cm2)
    caxis([10 42])
    AMEANoMEDmaxZi(AMEANoMEDmax<5)=nan;
    
    
    
    AMEANoMEDmaxZi=squeeze(AMEANoMEDmaxZi);
    [yq,xq]=find(isnan(AMEANoMEDmaxZi));
    [yk,xk]=find(~isnan(AMEANoMEDmaxZi));
    
    [Y,X]=ndgrid(1:NC.S.Y,1:NC.S.X);
    
    ziIntrp = griddata(xk,yk,AMEANoMEDmaxZi(~isnan(AMEANoMEDmaxZi)),xq,yq);
    
    
    AMEANoMEDmaxZi(isnan(AMEANoMEDmaxZi))=ziIntrp;
    
    ppc(smooth2a(AMEANoMEDmaxZi,10))
    
    ziIntrp=reshape(ziIntrp,size(Y));
    ppc(ziIntrp)
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function flipZtoT(zz,files,T,owatzz)
    if ~exist(sprintf('OWat%02d.mat',zz),'file')
        
        for tt=1:T
            if labindex==1,            fprintf('%2.2f%%\n',((zz/41-1)+tt/T)*100),end
            owatzz(tt,:,:)=  nc_varget(files(tt).full,'OkuboWeiss',[zz-1 0 0],[1 2400 3600]);
        end
        dispM('skew')
        out.SKEW=squeeze(skewness(owatzz,0));
        owatzz(owatzz>=0 | isnan(owatzz)  | isinf(owatzz) ) = nan;
        dispM('median')
        out.MEDIAN=squeeze(nanmedian(owatzz,1));
        dispM('mean')
        out.MEAN=squeeze(nanmean(owatzz,1));
        dispM('std')
        out.STD=squeeze(nanstd(owatzz,1));
        save(sprintf('OWat%02d.mat',zz),'-struct','out')
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%