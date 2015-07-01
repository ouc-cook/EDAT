function killevery2ndytl
     ytl=get(gca,'yticklabel'); for yy=2:2:numel(ytl), ytl{yy}='';end; set(gca,'ytickLabel',ytl)