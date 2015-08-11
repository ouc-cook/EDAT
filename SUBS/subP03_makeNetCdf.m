function subP03_makeNetCdf(DD,window,meanMaps)
    
    [Y,X] = size(meanMaps.meanMap.lon);
    ncF   = [DD.path.root 'binnedMeanMaps.nc'];
    system(sprintf('rm %s',ncF))
    
    nccreate(ncF,'u','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'v','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'long','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'lat','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'radius','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'absU','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'angleU','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'births','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'deaths','Dimensions',{'x',X,'y',Y});
     nccreate(ncF,'birthsMinusDeaths','Dimensions',{'x',X,'y',Y});
    
    ncwrite(ncF,'u',permute(meanMaps.meanMap.u,[2 1]));
    ncwrite(ncF,'v',permute(meanMaps.meanMap.v,[2 1]));
    ncwrite(ncF,'long',permute(meanMaps.meanMap.lon,[2 1]));
    ncwrite(ncF,'lat',permute(meanMaps.meanMap.lat,[2 1]));
    ncwrite(ncF,'radius',permute(meanMaps.meanMap.scale,[2 1]));
    ncwrite(ncF,'absU',permute(meanMaps.meanMap.absUV,[2 1]));
    ncwrite(ncF,'angleU',permute(meanMaps.meanMap.angleUV,[2 1]));
      ncwrite(ncF,'births',permute(meanMaps.birth.map,[2 1]));
    ncwrite(ncF,'deaths',permute(meanMaps.death.map,[2 1]));
    ncwrite(ncF,'birthsMinusDeaths',permute(meanMaps.birth.map-meanMaps.death.map,[2 1]));
    
    system(sprintf('ncview %s',ncF))
end