function subP03_makeNetCdf(DD,window,meanMaps)

    
    
    
    ncF='geostrVelsFromPop.nc';
system(sprintf('rm %s',ncF));
nccreate(ncF,'Ug','Dimensions',{'x',X,'y',Y,'z',Z});
nccreate(ncF,'Vg','Dimensions',{'x',X,'y',Y,'z',Z});
nccreate(ncF,'lat','Dimensions',{'x',X,'y',Y});
nccreate(ncF,'lon','Dimensions',{'x',X,'y',Y});
nccreate(ncF,'depth','Dimensions',{'z',Z});
ncwrite(ncF,'Ug',permute(Ug,[3,2,1]))
ncwrite(ncF,'Vg',permute(Vg,[3,2,1]))
ncwrite(ncF,'lat',permute(lat,[2,1]))
ncwrite(ncF,'lon',permute(lon,[2,1]))
ncwrite(ncF,'depth',depth.inside)

system(sprintf('ncview %s',ncF))
end