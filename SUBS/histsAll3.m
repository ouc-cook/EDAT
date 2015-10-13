HH.avi=load(['../dataAVI/histStruct.mat'])
HH.pop=load(['../dataFO/histStruct.mat'])
HH.p2a=load(['../dataP2A/histStruct.mat'])


%%
tcks=2:2:200;
figure(1)
set(gcf,'windowstyle','docked')
clf

hpo = histogram(HH.pop.scale/1000,tcks)
hold on
hav = histogram(HH.avi.scale/1000,tcks)
hp2 = histogram(HH.p2a.scale/1000,tcks)

grid minor

legend('pop','avi','p2a')

%%
% title(sprintf('%dvaluesfrom%dtracks.',datacount,numel(tracksFs)))
xlabel(['scale[km]'])
%%
tit=[DD.path.root 'histScaleAll'];
print(tit,'-r400','-depsc')
system(sprintf('epstopdf %s.eps',tit));