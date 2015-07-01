%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function longesttracks(basedir,dout,threshampArea,ii)
    minlen=70;
%      if ~exist(dout.LTfile,'file')
        copyaction(basedir,dout,minlen)
%      end
    cm=jet;
    AOplots(cm,dout,threshampArea,20);
    savestuff(dout,ii);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function AOplots(cm,outfile,thresh,flen)
    nrm=@(x) (x-min(x))/max(x-min(x));
    fulltrck=getfield(load(outfile.LTfile),'trck');
    
    if numel(fulltrck)>flen
        len=numel(fulltrck);
        im=round(len/2);
        ima=im-flen/2+1;
        imb=im+flen/2;
        trck=fulltrck(ima:imb);
    else
        trck=fulltrck;
    end
    
    
    %%
    AR=cell2mat(extractfield(trck,'area'));
    ar=extractfield(AR,'intrp');
    RaoRo=extractfield(AR,'RadiusOverRossbyL');
    % TEMPFIX!!!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    RaoRo(RaoRo<1e-10)=median(RaoRo);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    ra=sqrt(ar/pi); %#ok<*NASGU>
    amp=extractfield(cell2mat(extractfield(cell2mat(extractfield(trck,'peak')),'amp')),'to_contour');
     age=cat(2,trck.age);
    iq=cat(2,trck.isoper);
    vol=    extractdeepfield(trck,'volume.total') ;
    %   VoA=(extractdeepfield(trck,'VoA') )
    amp2ellip=(extractdeepfield(trck,'peak.amp.to_ellipse') );
    dynRad=(extractdeepfield(trck,'radius.mean') );
   
    RAL=@(M) (abs(log(M)));  
    quoA=([1 amp2ellip(2:end)./amp2ellip(1:end-1)]);
    quoB=([1 dynRad(2:end)./dynRad(1:end-1)]);
    quo=(max([RAL(quoA); RAL(quoB)],[],1));
    
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
    XTCK=nan(size(trck));
    XTCKL=num2cell(nan(size(trck)));
    set(gca,'ytick',[]);
    cb=colorbar('location','southOutside');
    
    axpos = get(gca,'Position');
    cpos = get(cb,'Position');
    cpos(4) = 0.35*cpos(4);
    cpos(2) = 1.06*cpos(2);
    set(cb,'Position',cpos)
    set(gca,'Position',axpos)
    
    %%
    
    
    
    
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
    
    
    fxs=@(in) max(in(:))-min(in(:)) ;
    for ii=1:numel(trck)
        xtmp(ii)=fxs(extractdeepfield(trck(ii),'coordinates.exact.x'));
        ytmp(ii)=fxs(extractdeepfield(trck(ii),'coordinates.exact.y'));
    end
     xshift=sum(xtmp);
%     xshift=sum(max([xtmp; ytmp],[],1));
    
    x=0;yreal=0;
    quiv=nan(numel(trck),4);
    for ii=1:numel(trck)
        xold=nanmean(x);
        yold=nanmean(yreal);
        
        yreal=extractdeepfield(trck(ii),'coordinates.exact.y');
        y=yreal-nanmean(yreal);
        xreal=extractdeepfield(trck(ii),'coordinates.exact.x');
        x=xreal-nanmean(xreal) -ii/numel(trck)*xshift;
        switch mod(ii,2)
            case 1
                plot(x,y,'--','color',col(cblvPos(ii),:))
            case 0
                plot(x,y,'color',col(cblvPos(ii),:))
        end
        drawnow
        XTCK(ii) = mean(x);
        XTCKL(ii) = {num2str(age(ii))};
        
        if ii>1
            quiv(ii,:)=[ XTCK(ii-1), 0,diff([xold,nanmean(x)]), diff([yold,nanmean(yreal)])];
        end
    end
    
    axis tight
    xlim1=get(gca,'xlim');
    ylim1=get(gca,'ylim');  
 
   qu= quiver(quiv(:,1),quiv(:,2),quiv(:,3),quiv(:,4),.5,'MaxHeadSize',.02,'color','black');
 set(get(qu,'children'),'Clipping','off');
    
    
    axis([xlim1 ylim1])
   
    
    
    
    
    %% TEMP SOL % TODO
    Yn=extractdeepfield(trck,'radius.coor.Ynorth')
    try
    Yn=cellfun(@(c) double(c),Yn);
    end
    Ys=extractdeepfield(trck,'radius.coor.Ysouth')
    try
    Ys=cellfun(@(c) double(c),Ys);
    end
    %%
    Yspans=(abs(diff([Yn;Ys],1,1)));
   
    
    radMerid=(extractdeepfield(trck,'radius.meridional'));
    dysKm=2*radMerid./double(Yspans)/1000;
    MeandyInKm=mean(2*radMerid./double(Yspans))/1000;
    set(gca,'yaxislocation','right')
    yl=get(gca,'ylim');
    ylabel(sprintf('<- %3dkm  ->',round(diff([yl])*MeandyInKm)))
    set(get(gca, 'YLabel' ), 'Rotation' ,90 )
    set(gca,'xtick',[],'ytick',[])
    
    II=unique(round(linspace(1,numel(XTCK),min([30,flen]))));
    
    
    
    xtck=XTCK(II);
    [xtck,origXorder]=sort(xtck);
    set(gca,'xtick',xtck)
    set(gca,'xaxisLocation','top')
    xtcklRaoRo=cellfun(@(c) {sprintf('%d',round(c))},num2cell(RaoRo(origXorder)));
    set(gca,'xticklabel',xtcklRaoRo)
    
    
    %%
    
    subplot(2,1,2,'align')
    
    
    hold on
    
    IQ=log(iq(2:end))-mean(log(iq(2:end)));
    difabs= @(a) (log([a(2:end)./a(1:end-1)]))';
    A= [difabs(vol.^(2/3)),difabs(ar) , difabs(dynRad),difabs(amp),difabs(amp2ellip) ];
    [AX,H1,H2] = plotyy(XTCK(2:end),A,XTCK(2:end),IQ,'bar','plot');
    %     [AX,H1,H2] = plotyy(xAX,A,xAX,IQ,'bar','plot');
    legend('volume^{(2/3)}','area','dyn. radius','amp','dyn. amp','IQ','location','SouthEast');
    
    alld=A(2:end-1,:);
    if size(A,2)<10
        alld=A;
    end
    
    my=[ceil(10*min((alld(:))))/10-.1 floor(10*max((alld(:))))/10+.1];
    yt=linspace(my(1),my(2),5);
    set(AX(:),'xlim',xlim1)
    set(AX(1),'ylim',my)
    ylab = cellfun(@(cc) sprintf('% .1f', cc) , num2cell((exp(yt))), 'uniformoutput', false);
    set(AX(1),'ytick',yt)
    set(AX(1),'yticklabel',ylab)
    set(AX(1),'xtick',sort(XTCK(II(1:3:end))))
    set(AX(2),'xtick',[])
    set(AX(1),'xticklabel',XTCKL(origXorder(1:3:end)))
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
    
    
    %%
    
    THR=log(repmat(thresh,length(xlim),1));
    plot(xlim,THR,'color','red')
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function savestuff(dout,ii)
    set(gcf,'position',[5 40 1912 437]);
    xlabel({'';dout.name}  )
    tmp=sprintf('tmp_%d.pdf',ii);
    crpd=sprintf('crpd_%d.pdf',ii);
    savefig('./',80,1600,500,tmp);
    system(sprintf('pdfcrop --margins "1 3 1 1" %s %s',tmp,crpd))
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function copyaction(basedir,dout,minlen)
    fs=dir([basedir 'data' dout.name '/TRACKS/*.mat']);
    days=0;
    %     h =  waitbar(0,dout.name);
    
    h = disp_progress('init',dout.name);
    for ff=1:numel(fs)
        %         waitbar(ff/numel(fs))
        h = disp_progress('show',h,numel(fs));
        try
            file=[basedir 'data' dout.name '/TRACKS/' fs(ff).name];
            days=max([days (size(matfile(file),'trck'))]);
        catch me
            disp(me)
        end
        if days>=minlen
            break
        end
    end
    
    %%
    system(['cp ' file ' ' dout.LTfile ]);
end




