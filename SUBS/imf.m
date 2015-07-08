function imf(X,a,b)
    if nargin<3
        a = nanmin(X(:));
        b = nanmax(X(:));
    end
    X(isnan(X) | X==0) = -1e42;
    pcolor(squeeze(X));
    shading flat
    caxis([a b])
    CM = parula(100);
    colormap(CM);
    colorbar;
    set(gcf,'windowstyle','docked')   
end