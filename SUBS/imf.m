function imf(X,a,b)
    if nargin<3
        a = nanmin(X(:))/2;
        b = nanmax(X(:))/2;
    end
    X(isnan(X) | X==0) = -1e42;
    imagesc(flipud(squeeze(X)));
    caxis([a b])
    CM = parula(100);
    CM(1,:) = [1 1 1];
    colormap(CM);
    colorbar;
    set(gcf,'windowstyle','docked')
    
    
end