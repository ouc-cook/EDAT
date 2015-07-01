function sub09_scaleStuff
   load S09main II DD T  
    try
        TR=getTR(DD);
    catch me
        disp(me.message)
        sub09_trackinit(DD);
        TR=getTR(DD) ;
    end  
    
    velZonmeans(DD,II,T,TR)
    scaleZonmeans(DD,II,T,TR)
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TR=getTR(DD)
    xlt=@(sen,f) extractfield(load(['TR-' sen '-' f '.mat']),'tmp');
    F={'rad','age','lat','lon'};
    g=@(c) cat(1,c{:});
    for ss=1:2
        for fi=1:numel(F);f=F{fi};
            sen=DD.FieldKeys.senses{ss};
            TR.(sen).(f)=(xlt(sen,f))';
        end
        f='vel';
        TR.(sen).(f)=g(g(xlt(sen,f)));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function scaleZonmeans(DD,II,T,TR)
    %% 
    lw=1.5;
    pp(1)=plot(II.la(:,1),2*II.maps.zonMean.Rossby.small.radius); 	hold on
    pp(2)=plot(II.la(:,1),II.maps.zonMean.AntiCycs.radius.mean.mean,'r');
    pp(3)=plot(II.la(:,1),II.maps.zonMean.Cycs.radius.mean.mean,'black');
    set(pp(:),'linewidth',lw)
    leg=legend('2 x Rossby Radius','anti-cyclones radius','cyclones radius');
    set( get(leg,'children'),'linewidth',lw)
    ylabel('[m]')
    xlabel('[latitude]')
    title(['scale - zonal means'])
    maxr=nanmax(nanmax([II.maps.zonMean.AntiCycs.radius.mean.mean(:) II.maps.zonMean.Cycs.radius.mean.mean(:)]));
    axis([min(II.la(:,1)) max(II.la(:,1)) 0 maxr])
    savefig(DD.path.plots,T.rez,T.width,T.height,['S-scaleZonmean'],'dpdf');
end








