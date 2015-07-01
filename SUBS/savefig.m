%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 26-Apr-2014 19:05:25
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savefig(outdir,resOut,xdim,ydim,tit,frmt,info,fs)  
%    set(0,'defaultTextInterpreter','LaTeX')
 set(gcf,'renderer','painter','windowstyle','normal','Visible','off')
    if nargin < 8,	fs=12;	end
    if nargin < 6,	frmt='dpdf';	end
    if nargin < 7,	info=[]    ;	end
    fname=[outdir,tit];
    mkdirp(outdir);
    %% set up gcfure
    [resHere,posOld]=setupfigure(resOut,xdim,ydim,fs);
    sleep(1)
    %% print
    fnamepdf=printStuff(frmt,fname,resOut,xdim,ydim,resHere);
    if nargin == 7,
        appendPdfMetaInfo(info,fnamepdf);
    end
    set(gcf,'Visible','on');
    set(gcf,'position',posOld);
%     sleep(2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function appendPdfMetaInfo(info,fnamepdf) %#ok<INUSL>
    structfn=sprintf('%03d_pdfinfo.mat',labindex);
    save(structfn,'info')
    system(sprintf('pdftk %s attach_files %s output %s.tmp.pdf',fnamepdf,structfn,fnamepdf));
    system(sprintf('mv %s.tmp.pdf %s',fnamepdf,fnamepdf));
    system(['rm ' structfn]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fnamepdf=printStuff(frmt,fname,resOut,xdim,ydim,resHere)
    if strcmp(frmt,'dpdf')
%         eval(['print ',[fname,'.pdf'] , ' -f -r',num2str(resOut),' -dpdf ']) % shithouse!
%         system(['pdfcrop --margins "1 1 1 1" ' fname '.pdf ' fname '.pdf']);

        eval(['print ',[fname,'.eps'] , ' -f -r',num2str(resOut),' -depsc '])
        system(['epstopdf --exact ' fname '.eps']);
        system(['pdfcrop --margins "1 1 1 1" ' fname '.pdf ' fname '.pdf']);
        system(['rm ' fname '.eps']);
    else
        if strcmp(fname(end-length(frmt)+1),frmt )
            fnfull=fname;
        else
            fnfull=[fname,'.',frmt(2:end)];
        end
        todo=['print ',fnfull , ' -f -r',num2str(resOut),' -',frmt,';'];
        disp(todo)
        eval(todo)
        resHere=resHere*3;
        xdim=xdim*3;
        ydim=ydim*3;
        system(['convert -density ' num2str(resHere) 'x' num2str(resHere) ' -resize ' num2str(xdim) 'x' num2str(ydim) ' -quality 100 +repage ' fnfull ' ' fname '.pdf' ]);
%    convert -density 300x300 -resize ${resX}x -quality 100 +repage $1  "${1%.*}.pdf"
   end
    fnamepdf=[fname '.pdf'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [resHere,posNow]=setupfigure(resOut,xdim,ydim,fs)
    resHere=get(0,'ScreenPixelsPerInch');  
    ratioRes=1;
    posNow=get(gcf,'position');
   set(gcf,'position',[0 0 [xdim ydim]/ratioRes]);
   
    set(gcf,'paperunits','inch','papersize',[xdim ydim]/resOut,'paperposition',[0 0 [xdim ydim]/resOut]);
%     set(findall(gcf,'type','text'),'FontSize',fs)
   set(findall(gcf,'type','text'),'FontSize',fs,'interpreter','latex','FontName','SansSerif')  
   set(findall(gcf,'type','Legend'),'FontSize',fs)
%     set(gca,'FontSize',fs)
end
