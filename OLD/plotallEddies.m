DD = initialise('',mfilename);
a = load([DD.path.eddies.name DD.path.eddies.files(1).name]);
b = load([DD.path.cuts.name DD.path.cuts.files(1).name]);
%%
LA = b.fields.lat;
LO = wrapTo180(b.fields.lon);
%%
COLS = parula(10);
close all
hold on
% axesm('aitoff','MapLatLimit',[-80 80],'MapLonlimit',[-180 180],'frame','off','grid', 'off')
axesm('aitoff','frame','on','grid', 'on')
load coast
plotm(lat,long,'color','green')
%  axesm('stereo','origin',[-90 0 0],'MapLatLimit',[-90 -10],'frame','on','flinewidth',1,'grid', 'on')
% set(gcf,'windowstyle','docked')
%%

coo.x = extractdeepfield(a.AntiCycs,'coor.exact.x');
coo.y = extractdeepfield(a.AntiCycs,'coor.exact.y');
dd = 1
la = interp2(LA,coo.x,coo.y);
lo = interp2(LO,coo.x,coo.y);
flag = abs(diff(lo))>dd | abs(diff(la))>dd;
la([  false flag])=nan;
lo([false flag ])=nan;
ac=plotm(la,lo,'color','red')
hold on
%%
coo.x = extractdeepfield(a.Cycs,'coor.exact.x');
coo.y = extractdeepfield(a.Cycs,'coor.exact.y');
la = interp2(LA,coo.x,coo.y);
lo = interp2(LO,coo.x,coo.y);
flag = abs(diff(lo))>dd | abs(diff(la))>dd;
la([  false flag])=nan;
lo([false flag ])=nan;
c=plotm(la,lo,'color','black')
%%
axis tight
legend([ac,c],'anti-cyclones','cyclones')
%%
fn = ['allEddies'];
savefig(DD.path.plots,72,600,300,fn,'dpdf');
cpPdfTotexMT(fn) ;
