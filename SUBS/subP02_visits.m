% unique visits ie one count per grid cell per eddy only
FN = DD.path.analyzed.files;
meanMap.visits = zeros(181,360);

for ff = 1:numel(FN)
    fprintf('%d%% done\n',round(100*ff/numel(FN)))
    lalocmplx = getfield(load(FN(ff).fullname),'visits');
    x = wrapTo360(imag(lalocmplx)) + 1;
    y = real(lalocmplx) + 91;
    lin = drop_2d_to_1d(y,x,size(meanMap.visits,1));
    meanMap.visits(lin) = meanMap.visits(lin) + 1;
end

try
    save([DD.path.root,'meanMaps.mat'],'-struct','meanMap','-append');
catch
    save([DD.path.root,'meanMaps.mat'],'-struct','meanMap');
end

