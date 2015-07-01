function [colors]=rainbow(R, G, B, l, L)
    om=8/10*pi/L;
    shft=1/10*pi;
    red=reshape(   sin(l*om+pi*(0/3)+shft).^2,numel(l),[]);
    green=reshape(   sin(l*om+pi*(2/3)+shft).^2,numel(l),[]);
    blue=reshape(   sin(l*om+pi*(1/3)+shft).^2,numel(l),[]);
    colors=([red green blue]).*repmat([R G B],numel(l),1);   
    colors=colors-min(colors(:));
    colors=colors/max(colors(:));  
end
