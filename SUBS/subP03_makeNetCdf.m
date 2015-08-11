function subP03_makeNetCdf(DD,window,meanMaps)
    
    [Y,X] = size(meanMaps.lon);
    ncF   = [DD.path.root 'binnedMeanMaps.nc'];
    
    nccreate(ncF,'u','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'v','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'long','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'lat','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'radius','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'absU','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'angleU','Dimensions',{'x',X,'y',Y});
    
    ncwrite(ncF,'u',permute(meanMaps.u,[2 1]));
    ncwrite(ncF,'v',permute(meanMaps.v,[2 1]));
    ncwrite(ncF,'long',permute(meanMaps.lon,[2 1]));
    ncwrite(ncF,'lat',permute(meanMaps.lat,[2 1]));
    ncwrite(ncF,'radius',permute(meanMaps.scale,[2 1]));
    ncwrite(ncF,'absU',permute(meanMaps.absUV,[2 1]));
    ncwrite(ncF,'angleU',permute(meanMaps.angleUV,[2 1]));
    
    
    
    
    system(sprintf('ncview %s',ncF))
end