%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 15-Jul-2014 13:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NKkk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxOWpostProc
    geo=nc_getall('../datanetU/Rossby/LatLonDepth.nc');load('allOW.mat','allOW')    ;
    load zi
    load ziItnrp
    load ziWeighted
    plotstuff(ziWeighted,ziIntrp,allOW,ziOW,geo.depth.data) %#ok<*PFBNS>
    saveas(gcf,[datestr(now,'mmdd-HHMM') '.fig']);
    savefig('../PLOTS/',100,1200,800,[datestr(now,'mmdd-HHMM') ]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function histDepOw=histUniqDepths(depz,zi,owLg,owAx)
    histDepOw = histc(owLg( zi == depz ), owAx);
end

function plotstuff(ziWeighted,~,ow,zi,depth)
    zI=squeeze(nanmean(zi,1));
    [yq,xq]=find(isnan(zI));
    [y,x]=find(~isnan(zI));
    v=zI(~isnan(zI));
    vq = griddata(x,y,v,xq,yq,'nearest');
    zI(isnan(zI))=vq;
    figure
    
    a=flipud(zI);
    cm=[[1 1 1];jet];
    imagesc(a)
    colormap(cm) ;
    colorbar
    %%
    zI=squeeze(nanmean(ziWeighted,1));
    [yq,xq]=find(isnan(zI));
    [y,x]=find(~isnan(zI));
    v=zI(~isnan(zI));
    vq = griddata(x,y,v,xq,yq,'nearest');
    zI(isnan(zI))=vq;
    figure
    
    a=flipud(zI);
    cm=[[1 1 1];jet];
    imagesc(a)
    colormap(cm) ;
    colorbar
    %%
    fuz=reshape(zi(~isnan(zi)),1,[]);
    uniDepths=unique(fuz);
    %     hist(zi(:), uniDepths)  ;
    set(0,'defaulttextinterpreter','latex')
    owLg=-ow;
    owAx=[0 logspace(log10(nanmean(owLg(:))),log10(nanmax(owLg(:))),40)];
    histDepOw=nan(numel(uniDepths),numel(owAx));
    
    parfor ud=1:numel(uniDepths)
        histDepOw(ud,:)=histUniqDepths(uniDepths(ud),fuz,owLg,owAx)
    end
    histDepOw(histDepOw==0)=nan;
    bar3(log10(histDepOw));
    view(60.5,28)
    axis tight
    %%
    nyt=ceil(linspace(find(~isnan(depth),1),numel(depth),7));
    nytl =cellfun( @(tk) sprintf('%3.2f',tk), num2cell(depth(nyt)/1000), 'uniformoutput',false)  ;
    set(gca,'ytick',nyt)
    set(gca,'yticklabel',nytl)
    ylabel(['depth [$km$]'])
    %%
    nxt=[round(linspace(1,numel(owAx),5))];
    nxtl=cellfun(@(x) sprintf('%5d',round(x)), num2cell(owAx(nxt)/1e-5),'uniformoutput',false);
    %     nxt=find(diff(round(owAx(2:end)/1e-6))) +1;
    %     nxtl=round(owAx(nxt)/1e-6);
    %     nxtl = cellfun( @(tk) sprintf('%d',tk), num2cell(nxtl), 'uniformoutput',false)  ;
    xlabel(['$-10^5$ Okubo-Weiss Parameter [$1/m^{2}$]'])
    set(gca,'xtick',nxt)
    set(gca,'xticklabel',nxtl)
    %%
    zt=get(gca,'ztick')  ;
    nzt=zt;
    nztl=cellfun( @(tk) sprintf('%0.0g',tk), num2cell(nzt), 'uniformoutput',false)  ;
    zlabel(['log10(count)']);
    set(gca,'ztick',nzt)
    set(gca,'zticklabel',nztl);
    axis tight
    
    
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
