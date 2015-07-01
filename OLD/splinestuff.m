e=load('e.mat')
set(0,'DefaultTextInterpreter', 'latex')
cut=load('../datapop/CUTS/CUT_20011219_-80s+80n-180w+180e.mat')
%%
ed=e.AntiCycs(ceil(rand(1,1)*2219));
%%
ssh=ed.profiles.x.ssh;
ssh=ssh-nanmin(ssh);
ssh=ssh-nanmean(ssh)/2;
%%
centr=ed.centroid.xz
%%
dx=double(cut.grids.DX(ed.centroid.lin));
x=((0:1:numel(ssh)-1)-centr)*dx;
X=linspace(x(1),x(end),numel(x)*10);
SSH=spline(x,normc(ssh'),X) ;
%%
[fs] = fit(x.',ssh','fourier8');
[f,gof,out] = fit(X.',SSH','fourier8');
% dsdxx{1}=diffCentered(2,X,f(X));
%%
clf
hold on
a(1)=plot(x,normc(ssh'),'*','markersize',3)
% axis tight
xl=get(gca,'xlim')
yl=get(gca,'ylim')
grid on
set(gca,'ytick',0,'xtick',0,'yticklabel',[],'xticklabel',[])
legend('ssh')
%%
% savefig('./',100,800,600,'Na','dpdf')
%%
dsdxx{1}=diffCentered(2,x,ssh);
b(1)=plot(x,normc(dsdxx{1}'),'r')
legend('ssh','\partial_{xx}')
set(gca,'ylim',yl,'xlim',xl)
%%
% savefig('./',100,800,600,'Nb','dpdf')
%%
delete(b(1))
% delete(a(1))
% a(3)=plot(X,normc(f(X)),'black.','markersize',1);
% a(3)=plot(X,SSH,'blue-');
a(2)=plot(X,(f(X)),'black-');
dsdxx{2}=diffCentered(2,X,f(X));
b(2)=plot(X,normc(dsdxx{2}'),'r')
legend('ssh','fourierN(spline(ssh))','\partial_{xx}')

%%
% savefig('./',100,800,600,'Nc','dpdf')
%%
delete(a(1))
dsdx{2}=diffCentered(1,x,fs(x));
% c(1)=plot(x,normc(dsdx{2}'),'g')
ca=find(diff(sign(dsdxx{2}))~=0 & X(1:end-1)<0,1,'last');
cb=find(diff(sign(dsdxx{2}))~=0 & X(1:end-1)>0,1,'first')+1;
SSHsig=mean(SSH([ca cb]));
c(2)=plot(xl,[SSHsig SSHsig]);
c([3 4])=plot([X(ca) X(ca)],yl,'magenta',[X(cb) X(cb)],yl,'magenta')
legend('fourierN(spline(ssh))','\partial_{xx}','ssh(peak)-a','\sigma')
%%
% savefig('./',100,800,600,'Nd','dpdf')
%%
sigma=mean(abs(X([ca cb])))
[~,Xc]=min(abs(X))
amp=SSH(Xc)-SSHsig;
A=amp/(1-exp(-.5));
plot([Xc Xc],[SSHsig SSH(Xc)],'color',[.91 .6 .1],'linewidth',2)
plot([0 X(cb)],[SSHsig SSHsig],'color',[ .6 .61  .1],'linewidth',2)
%%
% savefig('./',100,800,600,'Ne','dpdf')
%%
delete(b(2))
delete(c([3 4]))
delete(c([2]))
gaussh=@(X,sigma,A,yoff) A * exp(-.5*(X/sigma).^2) - A + yoff;
d=plot(X,gaussh(X,sigma,A,SSH(Xc)),'linestyle','--','color',[0 .5 0],'linewidth',2)
plot(xl,[(-A +SSH(Xc)) ,(-A +SSH(Xc)) ],'color',[.5 0 0],'linewidth',1)
set(gca,'ylim',[yl(1)*3 yl(2)])
legend('fourierN(spline(ssh))','a','\sigma','A e^{-(x/\sigma)^2/2} -A+ssh(0)')
%%
% savefig('./',100,800,600,'Nf','dpdf')
%%
set(get(gcf,'children'),'linewidth',2)
for ai=a
    try
        set(ai,'linewidth',2)       
    end
end
for bi=b
    try
        set(bi,'linewidth',2)
    end
end

%%
clf
xsi=linspace(0,2*pi,numel(X));
wssh=gaussh(X,sigma*1.5,A,SSH(Xc)) + .01*sin(xsi*2) + .005*sin(xsi*7.7-pi/2);
wf=diffCentered(1,X,wssh)*100000;
wff=diffCentered(2,X,wssh)*1000000000;
d=plot(X,wssh,'linestyle','-','color',[0 .5 0],'linewidth',2);
hold on
plot(X,wf,'linestyle','-','color',[.5 0 0],'linewidth',1);
plot(X,wff,'linestyle','-','color',[ 0 0 .5],'linewidth',1);
grid on
set(gca,'ytick',0,'xtick',0,'yticklabel',[],'xticklabel',[])
axis tight
xl=get(gca,'xlim')
yl=get(gca,'ylim')
[~,mi.f]=min(wf)
[~,ma.f]=max(wf)
plot([X(mi.f) X(mi.f)], yl,'r--' )
plot([X(ma.f) X(ma.f)], yl,'r--' )
ca=find(diff(sign(wff))~=0 & X(1:end-1)<0,1,'last');
cb=find(diff(sign(wff))~=0 & X(1:end-1)>0,1,'first')+1;
plot([X(ca) X(ca)], yl ,'magenta--')
plot([X(cb) X(cb)], yl ,'magenta--')
set(0,'DefaultTextInterpreter', 'LaTeX')
legend('tropical anti-cyclone','$\partial_x$','$\partial_{xx}$')
savefig('./',100,1024,600,'tropicalE','dpdf')
%%
clf
[fs] = fit(X.',wssh','fourier2');

wf=diffCentered(1,X,fs(X))*100000;
wff=diffCentered(2,X,fs(X))*1000000000;
hold on
plot(X,wssh,'linestyle','--','color',[0 .5 0],'linewidth',1);
d=plot(X,fs(X),'linestyle','-','color',[0 .5 0],'linewidth',2);
plot(X,wf,'linestyle','-','color',[.5 0 0],'linewidth',1);
plot(X,wff,'linestyle','-','color',[ 0 0 .5],'linewidth',1);
grid on
set(gca,'ytick',0,'xtick',0,'yticklabel',[],'xticklabel',[])
axis tight
xl=get(gca,'xlim')
yl=get(gca,'ylim')
[~,mi.f]=min(wf)
[~,ma.f]=max(wf)
plot([X(mi.f) X(mi.f)], yl,'r--' )
plot([X(ma.f) X(ma.f)], yl,'r--' )
ca=find(diff(sign(wff))~=0 & X(1:end-1)<0,1,'last');
cb=find(diff(sign(wff))~=0 & X(1:end-1)>0,1,'first')+1;
plot([X(ca) X(ca)], yl ,'magenta--')
plot([X(cb) X(cb)], yl ,'magenta--')
set(0,'DefaultTextInterpreter', 'LaTeX')
legend('tropical anti-cyclone','$a + b\;\cos(x \; w) + c \; \sin(x \; w) + d \; \cos(2 \; x \; w) + e \;\sin(2 \; x \; w) $','$\partial_x$','$\partial_{xx}$','location','southwest')
savefig('./',100,1024,600,'tropicalEalt','dpdf')










%%

sshc=normc(ssh')
clf
hold on
a(1)=plot(x,sshc,'*','markersize',3)
xl=get(gca,'xlim')
yl=get(gca,'ylim')
grid on
set(gca,'ytick',0,'xtick',0)

[~,lmin]=min(sshc' .* (x<0));
Leffy=sshc(lmin);
plot(xl,[Leffy Leffy]);
Cy=max(sshc)
plot([0 0],[Leffy Cy],'r');
Ley=(Cy-Leffy)*.2 + Leffy;
plot(xl,[Ley Ley],'g')
Ly= Ley  +  (Ley-Leffy)/2 ;
plot(xl,[Ly Ly],'magenta')
legend('ssh','L_{eff}')
axis tight





























