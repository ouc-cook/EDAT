function sub09_histStuff
    load S09main DD
    
    T(2).files=struct;
    T(1).files = dir2([DD.path.tracks.name '*' DD.FieldKeys.senses{1} '*']);
    T(2).files = dir2([DD.path.tracks.name '*' DD.FieldKeys.senses{2} '*']);
    
    for s=1:2
        N = numel(T(s).files);
        T(s).age=nan(1,N);
        for n=1:N
            T(s).age(n) = str2double(T(s).files(n).name(35:38));
        end
        
        uniO = unique(cat(2,T(:).age));
        uni = min(uniO):DD.time.delta_t*2:600;
        H{s} = histc(T(s).age,uni);
        MM(s).mean = nanmean(T(s).age);
        MM(s).medi = nanmedian(T(s).age);
    end
    %%
    clf
    HI=reshape(cell2mat(H),numel(H{1}),[]);
    CS=cumsum(HI);
    [ax,p1,p2] = plotyy(uni,HI,fliplr(uni),cumsum(flipud(sum(HI,2))),'bar','semilogy');
    set(p1,'BarLayout','stacked');
    axis(ax(:),'tight')
    %     xlabel('age [d]')
    %     ylabel('count [1000]')
    set(ax(1),'xtick',[min(uniO) 100 200 400])
    set(ax(1),'ytick',[  5000 10000 20000 30000])
    set(ax(1),'yticklabel',get(gca,'ytick')/1000)
    set(ax(2),'ytick',logspace(1,4,4))
    hold on
    yl = get(ax(1),'ylim');
    xl = get(ax(1),'xlim');
    cm=colormap(summer(2));
    set(gcf,'windowStyle','docked')
    plot(ax(1),[MM(2).mean; MM(2).mean],yl,'color',cm(2,:))
    plot(ax(1),[MM(2).medi; MM(2).medi],yl,'color',cm(2,:),'linestyle','--')
    plot(ax(1),[MM(1).mean; MM(1).mean],yl,'color',cm(1,:))
    plot(ax(1),[MM(1).medi; MM(1).medi],yl,'color',cm(1,:),'linestyle','--')
    leg1 = plot(ax(1),xl([1 1]),yl([1 1]),'color',[0 0 0],'linestyle','-');
    leg2 = plot(ax(1),xl([1 1]),yl([1 1]),'color',[0 0 0],'linestyle','--');
    legend([p1,p2,leg1,leg2],['anti-cyclones (' num2str(CS(end,1)) ' total)'],['cyclones (' num2str(CS(end,2)) ' total)'],'total cumsum (right2left)',...
        'mean','median');    
    %%
    grid(ax(2),'on')   ;
    ax(2).GridColor = 'blue';
    ax(2).GridLineStyle ='-';
    ax(2).YMinorGrid = 'on';    
    grid(ax(1),'on')
    ax(1).GridColor = 'black';
    ax(1).GridLineStyle ='-';
    ax(1).LineWidth = 2;
    ax(1).YGrid = 'on';
    ax(1).XGrid = 'off';    
    %%
    fn=['histTrackCount'];   
    savefig(DD.path.plots,72,500,400,fn,'dpdf',DD2info(DD));    
    cpPdfTotexMT(fn);
    %%
    save([DD.path.analyzed.name mfilename '.mat'])
end