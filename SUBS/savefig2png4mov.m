%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 26-Apr-2014 19:05:25
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savefig2png4mov(outdir,rez,xdim,ydim,tit)
    set(gcf,'renderer','painter')
    % set(gcf,'Visible','off')
    fname=[outdir,tit];
    mkdirp(outdir);
    %% set up figure
    setupfigure(rez,xdim,ydim)
    %% print
    printStuff('djpeg',fname,rez,xdim,ydim)
    close(gcf);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function printStuff(frmt,fname,rez,xdim,ydim)
    fnfull=[fname,'.',frmt(2:end)];
    eval(['print ',fnfull , ' -f -r',num2str(rez),' -',frmt,';']);
    system(['convert -trim ' fnfull ' ' fnfull]);
    system(['convert -resize ' sprintf('%dx%d',xdim,ydim) ' ' fnfull ' ' fnfull]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setupfigure(rez,xdim,ydim)
    
    resolution=get(0,'ScreenPixelsPerInch');
    xdim=xdim*rez/resolution*2;
    ydim=ydim*rez/resolution*2;
    set(gcf,'paperunits','inch','papersize',[xdim ydim]/rez,'paperposition',[0 0 [xdim ydim]/rez]);
    xa4=11.692*resolution;
    fsScaled=round(12/xa4*xdim)		;
    set(gca,'FontSize',fsScaled);
    set(findall(gcf,'type','text'),'FontSize',fsScaled);
    
end
