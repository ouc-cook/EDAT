J=jet;
%%
load('A.mat','A','cut')
S=cut.grids.ssh;
lat=cut.grids.lat;
%%
clear cut
SS=S-min(S(:));
SS=SS/max(SS(:));
clf;fig=ppc(flipud(SS));
caxis([0 1])
%%

%%
for ee=1:1:numel(A)
	iiqq=A(ee).isoper;
	RR=A(ee).area.RadiusOverRossbyL	;
	x=A(ee).coordinates.exact.x			;
	y=A(ee).coordinates.exact.y			;
	% 	text(x,y,sprintf('%d',round(iiqq*100)))
hold on	
	
	iiqq=(iiqq-.5)*2;
		iiqq(iiqq>1)=1;
		iiqq(iiqq<0)=0;
		iiqq=ceil(iiqq*63);
				
% 		col=rainbow(1,1,0,(iiqq)*64,64);
	

R=ceil(RR/10*63);

		plot(x,y,'color',J(R,:));
	
end
rr=extractdeepfield(A,'area.RadiusOverRossbyL');
XI=extractdeepfield(A,'trackref.lin');
iq=extractdeepfield(A,'isoper');
amp=extractdeepfield(A,'peak.amp.to_ellipse');
clear prof

ar.tot=extractdeepfield(A,'area.total');
ar.intrp=extractdeepfield(A,'area.intrp');
ar.rad=extractdeepfield(A,'radius.mean').^2*pi;



prof.x=cell2mat(extractdeepfield(A,'profiles.x'))
prof.y=cell2mat(extractdeepfield(A,'profiles.y'))

close all
for ee=1:1:numel(A)
diffs=diff(([	prof.x(ee).V prof.y(ee).U' 	prof.y(ee).V' ]));
hold on

diffs(diffs<0)=-1;
diffs(diffs>0)=1;
accChanges(ee)=nansum(abs(diff(diffs)))/2;

% plot(diff(profUV{ee}),'color',rainbow(1,1,1,ee,numel(A)),'linewidth',.001)

end



la=lat(XI);
IQ=(iq-.5)*2;
IQ(IQ>1)=1;
IQ(IQ<0)=0;
close all
%%

scatter(rr,abs(la),10,IQ)
axis tight
colorbar
colormap jet
%%
figure

scatter(rr,amp,10,abs(la))
colorbar
%%
figure

scatter(rr,abs(la),IQ*100,log(amp))
colorbar
figure
%%
clf
amp(amp>.3)=.31;
scatter(rr*100,amp*100,IQ.^2*100,abs(la))
axis tight
colorbar

%%
clf
accChanges(accChanges>500)=550

scatter(accChanges,rr*10)
axis tight
colorbar

%%
clf
ar.rat2=log10(ar.intrp./ar.rad	)
ar.rat=exp(abs(log(ar.intrp./ar.tot)))

scatter(ar.rat2,rr,5,abs(la)	)
axis tight
colorbar







