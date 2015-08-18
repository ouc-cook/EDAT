function subP03_makeNetCdf(DD,window,meanMaps)

    [Y,X] = size(meanMaps.lon);
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
     nccreate(ncF,'distTillDeathX','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'distTillDeathY','Dimensions',{'x',X,'y',Y});
    nccreate(ncF,'distTillDeath','Dimensions',{'x',X,'y',Y});
     nccreate(ncF,'amplitude','Dimensions',{'x',X,'y',Y});

    ncwrite(ncF,'distTillDeathX',permute(meanMaps.x,[2 1]));
    ncwrite(ncF,'distTillDeathY',permute(meanMaps.y,[2 1]));
    ncwrite(ncF,'distTillDeath',permute(hypot(meanMaps.x,meanMaps.y),[2 1]));
    ncwrite(ncF,'u',permute(meanMaps.u,[2 1]));
    ncwrite(ncF,'v',permute(meanMaps.v,[2 1]));
    ncwrite(ncF,'long',permute(meanMaps.lon,[2 1]));
    ncwrite(ncF,'lat',permute(meanMaps.lat,[2 1]));
    ncwrite(ncF,'radius',permute(meanMaps.scale,[2 1]));
    ncwrite(ncF,'absU',permute(meanMaps.absUV,[2 1]));
    ncwrite(ncF,'angleU',permute(meanMaps.angleUV,[2 1]));
    ncwrite(ncF,'births',permute(meanMaps.birth.map,[2 1]));
    ncwrite(ncF,'deaths',permute(meanMaps.death.map,[2 1]));
    ncwrite(ncF,'birthsMinusDeaths',permute(meanMaps.birth.map-meanMaps.death.map,[2 1]));
     ncwrite(ncF,'amplitude',permute(meanMaps.amp,[2 1]));

    system(sprintf('ncview %s',ncF))
end
