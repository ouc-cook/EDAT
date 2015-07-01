%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function compPlots

    dirs={'iq2';'iq6';'iq6dl';'iq6dlMr';'iq6dlMrIc';'iq8';'iq4';'ch'};
%         dirs={'iq6dlMrIc'};
    D=inIt(dirs);
    
    
    %     L=numel(dirs)
    %     spmd(L)
    %         ii=labindex
    %           longesttracks(D.basedir,D.out(ii),D.thresh.ampArea,ii);
    %     end
%     
%     ii=1
% %     longesttracks(D.basedir,D.out(ii),D.thresh.ampArea,ii);
% %     LTscatter(D.basedir,D.out(1),D.thresh.ampArea,1)
% %     
    for ii=1:numel(D.out)
                longesttracks(D.basedir,D.out(ii),D.thresh.ampArea,ii);
%          LTscatter(D.basedir,D.out(ii),D.thresh.ampArea,ii)
    end
    printoutsLT(D);
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LTscatter(basedir,dout,threshampArea,ii)
    
    OUT=collectScatD(basedir,dout);
    
    for tt=1:numel(OUT)
       OUT(tt).id=tt*ones(size(OUT(tt).lat)); 
    end
    
    
    
    FN=fieldnames(OUT)
    for fn=FN';fn=fn{1};
       OUTcat.(fn)=cat(2,OUT.(fn)) ;
      
    end
    
    strtsFlag=OUTcat.IDquo==0;
    
     for fn=FN';fn=fn{1};
       OUTcat.(fn)(strtsFlag)=nan ;
     end
    
     
     save LTsc
     
     %%
     xax=log10(abs(OUTcat.dist));
     xax(xax<-2)=-2;
     yax=log10(exp(OUTcat.IDquo));
     sax=OUTcat.aol.^2;
     cax=OUTcat.iq;
     
     xth=1.75;
     yth=2.5;
     xthresh=repmat(log10(xth),2,1);
     ythresh=repmat(log10(yth),2,1);
     
     clf
      scatter(xax,yax,sax,cax,'linewidth',0.1)%,cat(2,OUT.lat),cat(2,OUT.lat))
    axis tight
     cb=colorbar;
        
     hold on
     plot(xthresh,get(gca,'ylim'))
     plot(get(gca,'xlim'),ythresh)
%      axis([-2 1 0 1])
   axis([-2 log10(xth) 0 log10(yth)])
    xtck=get(gca,'xtick');
    ytck=get(gca,'ytick');
    ytck=linspace( log10(yth),max(ytck),4);
    ytck=linspace( 0,max(ytck),4);
    
     xtck=linspace( min(xtck),max(xtck),4);
   
%      xtck=sort([xtck log10(xth)]);
xtck=log10([.01 .1 .5  1 xth 10 ])  ;

    
    set(gca,'xtick',xtck);
    set(gca,'ytick',ytck);
    xtckl=cellfun(@(c) sprintf('%2.2f',10.^c),num2cell(xtck),'uniformoutput',0) ;
    ytckl=cellfun(@(c) sprintf('%2.1f',10.^c),num2cell(ytck),'uniformoutput',0) ;
    
    set(gca,'xticklabel',xtckl);
    set(gca,'yticklabel',ytckl);
    
    %%
    savefig('./',80,800,500,sprintf('scat%1d_unlabelled',ii));
     
     
     
      xlabel('distance') 
     ylabel('Character Ratio') 
     title(['size <=> radius/Lr - [max=10]']) 
     ylabel(cb,'IQ') 
     
     savefig('./',80,800,500,sprintf('scat%1d',ii));
        
     
     %%
     
    subplot(2,1,1)
    xax=OUTcat.aol;
     yax=OUTcat.lat;
     cax=OUTcat.iq;
     sax=OUTcat.amp2ellip.^2;
       scatter(xax,yax,abs(sax)*500,cax)%,cat(2,OUT.lat),cat(2,OUT.lat))
    axis tight
      set(gca,'yticklabel','')
      set(gca,'xticklabel','')
    axis([0 10 0 65])
      title('radius from contour / Lr')
      ylabel('lat')
%      cb=colorbar;      
subplot(2,1,2)     
     xax=OUTcat.dynAOL;
     yax=OUTcat.lat;
     cax=OUTcat.iq;
     sax=OUTcat.amp2ellip.^2;
     scatter(xax,yax,abs(sax)*500,cax)%,cat(2,OUT.lat),cat(2,OUT.lat))
     axis tight
%      cb=colorbar('yticklabel',[],'location' ,'east');  
    axis([0 10 0 65])   
      xx=get(gca,'position');
        set(gca,'position',xx+[0 .12 0 0]);
     xlabel('dyn. radius / Lr');
     text(8,10,'size <=> eddy amplitude')
     text(8,5,'color <=> IQ')
     
    savefig('./',80,800,1200,'scatRadOLrComp');
     
     
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OUT=collectScatD(basedir,dout)
    fs=dir([basedir 'data' dout.name '/TRACKS/*.mat']);
    RAL=@(M) (abs(log(M)));  
 
     LrFile=[basedir 'data' dout.name '/Rossby/RossbyRadius.mat' ];     
     Lr=getfield(load(LrFile,'out'),'out');
    
    ff=1
    dd=0
    ddLim=10000
    while dd<ddLim%numel(fs)
%          fprintf('%2d%%\n',round(ff/numel(fs)*100))
         fprintf('%2d%%\n',round(dd/ddLim*100))
        file=[basedir 'data' dout.name '/TRACKS/' fs(ff).name];        
%         if str2double(file(end-7:end-4))>120            
            try                
                MF=matfile(file);
                trck=MF.trck;
                dd=dd+numel(trck);
                
                
                OUT(ff).lat=extractdeepfield(trck,'geo.lat');
                OUT(ff).aol=extractdeepfield(trck,'area.RadiusOverRossbyL');
                OUT(ff).dynRad=extractdeepfield(trck,'radius.mean');
                OUT(ff).iq=extractdeepfield(trck,'isoper');
%                 OUT(ff).amp2contour=extractdeepfield(trck,'peak.amp.to_contour');
                OUT(ff).amp2mean=extractdeepfield(trck,'peak.amp.to_mean');
                OUT(ff).amp2ellip=extractdeepfield(trck,'peak.amp.to_ellipse');
                
               latM= nanmean(OUT(ff).lat);
               linXY=extractdeepfield(trck,'peak.lin');
              LrAtLin=Lr(linXY);
               LrAtLin(LrAtLin==0)=nan;
               LrAtLin=nanmean(LrAtLin);
               
               dist=  [nan,diff(deg2rad(abs(extractdeepfield(trck,'geo.lon'))))*earthRadius*cosd(latM)];
              
               OUT(ff).dist=dist/LrAtLin;
               
               
               
                  OUT(ff).dynAOL= OUT(ff).dynRad./LrAtLin;
               
               
    
    quoA=([1 OUT(ff).amp2ellip(2:end)./OUT(ff).amp2ellip(1:end-1)]);
    quoB=([1 OUT(ff).dynRad(2:end)./OUT(ff).dynRad(1:end-1)]);
     OUT(ff).IDquo=(max([RAL(quoA); RAL(quoB)],[],1));
              
                
                 OUT(ff).age=  abs(extractdeepfield(trck,'age'));
                
                
                
            catch me
                disp(me)
                continue
            end
              ff=ff+1;
%         end
       
    end
    
    
    
    
    
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
    D.basedir=['/scratch/uni/ifmto/u300065/FINAL/smAor/'];
    D.out(numel(dirs))=struct;
    [D.out(:).name]=flsh(dirs);
    [D.out(:).LTfile]=  flsh(cellfun(@(c) [D.basedir 'LT_' c '.mat'],dirs,'uniformoutput',false));
    %     [D.out(:).file]=  flsh(cellfun(@(c) [D.basedir 'tracks_' c '.mat'],dirs,'uniformoutput',false));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function printoutsLT(D)
    system(sprintf('pdfjam -o tmp.pdf crpd*pdf'))
    outtit=[cat(2,D.out(:).name),'.pdf'];
    system(['pdfcrop  --margins "1 3 1 1" tmp.pdf ' outtit])
    delete('crpd*pdf')
    delete('tmp.pdf')
end
