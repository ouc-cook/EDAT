function fns=ncfieldnames(ncfile)
    warning('off','SNCTOOLS:nc_getall:dangerous')
    fns=fieldnames(nc_getall(ncfile));
    warning('on','SNCTOOLS:nc_getall:dangerous')
end