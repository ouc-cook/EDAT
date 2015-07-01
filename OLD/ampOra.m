%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ampOra
    %      dirs= {'iq2'; 'iq4'; 'iq6'; 'iq8'; 'ch400amparea';
    %      'ch400';'iq5-1d';'iq5'}; dirs= {'All'};
    %     dirs= {'iq2fortnight';'iq2';'iq4';'iq6';'iq8';'iq5';'iq5nonVoA';'ch400amparea'};
    dirs= {'iq5fortnight';'iq2';'iq4';'iq6';'iq8';'iq5';'iq5nonVoA';'ch400amparea'};
    
    D=inIt(dirs);
    D=spmdloop(D);
    printouts(D);
    close all
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function printouts(D)
    system(sprintf('pdfjam -o tmp.pdf crpd*pdf'))
    outtit=[cat(2,D.out(:).name),'.pdf'];
    system(['pdfcrop  --margins "1 3 1 1" tmp.pdf ' outtit])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function D=inIt(dirs)
    addpath(genpath('./'))
    flsh= @(x) deal(x{:});
    dbstop if error
    dbstop if warning
    D=INPUT;
    D.threads.num=init_threads(12);
    D.here=pwd;
    D.basedir=['/scratch/uni/ifmto/u300065/FINAL/aorStuff/'];
    D.out(numel(dirs))=struct;
    [D.out(:).name]=flsh(dirs);
    [D.out(:).file]=  flsh(cellfun(@(c) [D.basedir 'tracks_' c '.mat'],dirs,'uniformoutput',false));
    
%     copyaction(D)
      
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function copyaction(D)
    %     for labindex=1:numel(D.out)
    spmd(numel(D.out))
        %         if exist( D.out(labindex).file,'file')
        %             sec=1;
        %             while sec>0
        %                 disp([ D.out(labindex).file ' exists ']);
        %                 fprintf('%d secs remaining. going to overwrite\n\n',sec);
        %                 sec=sec-1;
        %                 sleep(1)
        %             end
        %         end
        
        %%
        fs=dir([D.basedir 'data' D.out(labindex).name '/TRACKS/*.mat']);
        
        days=0;
        for ff=1:numel(fs)
            dateA=datenum(fs(ff).name(6:6+7),'yyyymmdd');
            dateB=datenum(fs(ff).name(6+9:6+7+9),'yyyymmdd');
            if dateB-dateA+1 > days
                days=dateB-dateA+1;
                longest=fs(ff);
            end
        end
        file=[D.basedir 'data' D.out(labindex).name '/TRACKS/' longest.name];
        system(['cp ' file ' ' D.out(labindex).file ]);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function D=spmdloop(D)
    cm=jet;
    %     spmd(numel(D.out))
    %         fig=gop(@vertcat,{AOplots(cm,D.out(labindex),D.thresh.ampArea,labindex)},1);
    %     end
    %      D=savestuff(D,fig{1});
    ii=0;
    for dout=D.out
        ii=ii+1;
        fig{ii}=AOplots(cm,dout,D.thresh.ampArea,ii);
    end
    D=savestuff(D,fig);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function D=savestuff(D,figs)
    for ff=1:numel(figs)
        fig=hgload(figs{ff});
        set(gcf,'position',[5 40 1912 437]);
        xlabel({'';D.out(ff).name}  )
        D.out(ff).tmp=sprintf('tmp_%d.pdf',ff);
        D.out(ff).crpd=sprintf('crpd_%d.pdf',ff);
        savefig('./',80,1600,500,D.out(ff).tmp);
        system(sprintf('pdfcrop --margins "1 3 1 1" %s %s',D.out(ff).tmp,D.out(ff).crpd))
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fig=AOplots(cm,outfile,thresh,id)
    nrm=@(x) (x-min(x))/max(x-min(x));
    trck=getfield(load(outfile.file),'trck');
    try
        trck=trck(end-25:end);
    end
    
    AR=cell2mat(extractfield(trck,'area'));
    ar=extractfield(AR,'intrp');
    RaoRo=extractfield(AR,'RadiusOverRossbyL');
    ra=sqrt(ar/pi); %#ok<*NASGU>
    amp=extractfield(cell2mat(extractfield(cell2mat(extractfield(trck,'peak')),'amp')),'to_contour');
    age=cat(2,trck.age);
    iq=cat(2,trck.isoper);
    vol=    extractdeepfield(trck,'volume.total') ;
    %   VoA=(extractdeepfield(trck,'VoA') )
    peak2cont=(extractdeepfield(trck,'peak.amp.to_ellipse') );
    dynRad=(extractdeepfield(trck,'radius.mean') );
    
    quoA=([1 peak2cont(2:end)./peak2cont(1:end-1)]);
    quoB=([1 dynRad(2:end)./dynRad(1:end-1)]);
    quo=(abs(log(quoA)) + abs(log(quoB)))/2;
    %      quo=log(quoA.*quoB)/2;
    
    % for ii=1:21
    %     hold on
    %    pro=trck(ii).profiles
    %     plot(pro.x.ssh+.1*ii,'color',rainbow(1,1,1,ii,21))
    % end
    
    
    [R]=cm(:,1);
    [G]=cm(:,2) ;
    [B]= cm(:,3);
    
    col=[R,.8*G,B*.6];
    %     cm1=cm;
    %     cm2=cm(:,[2 1 3]);
    %     col=doublemap([-1,0,1],cm1,cm2,[.3 .3 1],4);
    %     col(1:3,:)  =repmat([1 .6 .5],3,1);
    %   col(end-2:end,:)=repmat([.6 1 .5],3,1);
    %   colormap(col);
    colormap(col);
    
    
    
    %%
    clf
    subplot(2,1,1,'align')
    hold on
    
    xtck=nan(size(trck));
    xtckl=num2cell(nan(size(trck)));
    set(gca,'ytick',[]);
    cb=colorbar('location','southOutside');
    
    axpos = get(gca,'Position');
    cpos = get(cb,'Position');
    cpos(4) = 0.35*cpos(4);
    cpos(2) = 1.06*cpos(2);
    set(cb,'Position',cpos)
    set(gca,'Position',axpos)
    
    mq=max(abs(quo));
    %     caxis([-mq mq]);
    caxis([0 mq]);
    mqs=floor(10*mq)/10;
    ct=-mqs:2*mqs/4:mqs;
    set(cb,'xtick',ct)
    
    cbtckl=cellfun(@(cc) sprintf('% d%%', cc) ,num2cell(round((exp(ct)-1)*100)),'uniformoutput',false);
    cbtckl{3}='0%';
    set(cb,'xticklabel',cbtckl)
    cblv=linspace(-mq, mq, size(col,1));
    [QUO,CBLV]=meshgrid(quo,cblv);
    [~,cblvPos]=min(abs(QUO-CBLV),[],1);
    
    for ii=1:1:numel(trck)
        trck(ii).coordinates
        y=extractdeepfield(trck(ii),'coordinates.exact.y');
        x=extractdeepfield(trck(ii),'coordinates.exact.x')-ii/numel(trck)*1000;
        switch mod(ii,2)
            case 1
                plot(x,y,'--','color',col(cblvPos(ii),:))
            case 0
                plot(x,y,'color',col(cblvPos(ii),:))
        end
        drawnow
        axis  tight
        xtck(ii) = mean(x);
        xtckl(ii) = {num2str(age(ii))};
    end
    
    Yspans=(abs(diff([extractdeepfield(trck,'radius.coor.Ynorth');extractdeepfield(trck,'radius.coor.Ysouth')],1,1)));
    radMerid=(extractdeepfield(trck,'radius.meridional'));
    dysKm=2*radMerid./double(Yspans)/1000;
    set(gca,'yaxislocation','right')
    yl=get(gca,'ylim');
    ylabel(sprintf('<- %3dkm  ->',round(diff([yl])*max(dysKm))))
    set(get(gca, 'YLabel' ), 'Rotation' ,90 )
    set(gca,'xtick',[],'ytick',[])
    
    a=axis;
    xAX=linspace(a(1),a(2),numel(age));
    [~,xr]=sort(xtck);
    if numel(xr)>20
        ii=round(linspace(1,numel(xr),20));
        xr=xr(ii);
    end
    set(gca,'xtick',xtck(xr))
    set(gca,'xaxisLocation','top')
    xtcklRaoRo=cellfun(@(c) {sprintf('%d',round(c))},num2cell(RaoRo(xr)));
    set(gca,'xticklabel',xtcklRaoRo)
    
    
    %%
    subplot(2,1,2,'align')
    THR=log(repmat(thresh,length(xAX),1));
    xAXdouble=repmat(xAX',1,2);
    hold on
    
    IQ=log(iq(2:end))-mean(log(iq(2:end)));
    difabs= @(a) (log([a(2:end)./a(1:end-1)]))';
    A= [difabs(vol.^(2/3)),difabs(ar) , difabs(dynRad),difabs(amp)];
    [AX,H1,H2] = plotyy(xtck(2:end),A,xtck(2:end),IQ,'bar','plot');
    %     [AX,H1,H2] = plotyy(xAX,A,xAX,IQ,'bar','plot');
    legend('volume^{(2/3)}','area','dyn. radius','amp','IQ','location','SouthEast');
    alld=A(2:end-1,:);
    my=[ceil(10*min((alld(:))))/10-.1 floor(10*max((alld(:))))/10+.1];
    yt=linspace(my(1),my(2),5);
    set(AX(:),'xlim',[xAX(1) xAX(end)])
    set(AX(1),'ylim',my)
    ylab = cellfun(@(cc) sprintf('% .1f', cc) , num2cell((exp(yt))), 'uniformoutput', false);
    set(AX(1),'ytick',yt)
    set(AX(1),'yticklabel',ylab)
    set(AX(1),'xtick',xtck(xr))
    set(AX(2),'xtick',[])
    set(AX(1),'xticklabel',xtckl(xr))
    set(get(H2,'children'),'clipping','off')
    set(get(H1(1),'children'),'clipping','off')
    set(get(H1(2),'children'),'clipping','off')
    set(get(H1(3),'children'),'clipping','off')
    set(AX(2),'ylim',[min(IQ) max(IQ)]);
    iqYt=linspace(min(IQ), max(IQ) ,5);
    iqYtL=cellfun(@(c) sprintf('%1.1f',(exp(c))),num2cell(iqYt+mean(log(iq))),'UniformOutput' ,false);
    set(AX(2),'ytick',iqYt) ;
    set(AX(2),'yticklabel',iqYtL);
    set(H2,'Clipping','off');
    xx=get(gca,'position');
    set(gca,'position',xx+[0 .16 0 0]);
    plot(xAXdouble,THR,'color','red')
    fig=sprintf('fig%02d.fig',id);
    saveas(gcf,fig)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [OUT]=extractdeepfield(IN,fieldnameToAccess)
    field = textscan(fieldnameToAccess,'%s','Delimiter','.');
    fieldSize=size(field{1},1);
    switch fieldSize
        case 1
            OUT=extractfield(IN,fieldnameToAccess);
        case 2
            OUT=extractfield(cell2mat(extractfield(IN,field{1}{1})),field{1}{2} );
        case 3
            OUT=extractfield(cell2mat(extractfield(cell2mat(extractfield(IN,field{1}{1})),field{1}{2} )),field{1}{3});
        case 4
            OUT=extractfield(cell2mat(extractfield(cell2mat(extractfield( cell2mat(extractfield(IN,field{1}{1})),field{1}{2} )),field{1}{3})),field{1}{4});
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

