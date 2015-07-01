%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 21-May-2012 12:18:18
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function SSA
	close all
	clear all
	%% ##########################INPUT#########################################
	%netcdf data
	nc.file='./sst.mon.anom.nc';
	%variable key
	nc.var='sst';
	%lat/long keys
	nc.lat='lat';
	nc.lon='lon';
	%time key
	nc.time='time';
	%days since 'YYYYMMDD'
	nc.ds='18000101';
	%chosen dimensions file
	input='./input.txt';
	%##########################################################################
	%% begin
	main(input,nc)
end
function main(input,nc)
	dims=dlmread(input);
	%% get data
	D=readData(nc);
	%% get time
	[T]=getTime(D.time,nc.ds,dims);
	%% get space
	[S]=getspace(D,dims);
	%% cut piece
	[D]=cutPiece(D,S,T);
	%% create mean
	[D]=lat_weighted_mean(D);
	%% build lag shifet matrix Y, toeplitz covariance matrix C and get
	%EOFs (rho) and eigenvalues
	[eof]=Toep_cov(detrend(D.cut.sstm)',dims);
	%% build reconstructed components
	[RC]=RCs(eof,dims);
	%%
	plotStuff(eof,RC,D,T)
	printall2eps
end
function [p,freq]=fourierm(sstm,time)
	% perform fft on monthly data
	f = sstm;
	N = length(f); %% number of points
	T = (time(end)-time(1))/(365.25/12); %% define time of interval, days to months
	%t = (0:N-1)/N; %% define time
	%t = t*T; %% define time in seconds
	p = abs(fft(f))/(N/2); %% absolute value of the fft
	warning('off','MATLAB:colon:nonIntegerIndex')
	p = p(1:N/2).^2; %% take the power of positve freq. half
	freq = (0:N/2-1)/T*12; %% find the corresponding frequency in Hz
end
function [RC]=RCs(eof,dims)
	% build RCs
	[pcl,pcn]=size(eof.PC);
	M=pcn;
	rcn=dims(4,2);
	%% build Z
	%Z size of PC times number of eigenvectors
	Z=zeros(pcl,M,rcn);
	%loop over PCs
	for z=1:rcn
		for x=1:M
			Z(1+x-1:end,x,z)=eof.PC(1:end-x+1,M-z+1);  %we need the pcn-lon end part of PC
		end
	end
	%% build RCs
	RC=nan(pcl,rcn);
	for r=1:rcn
		RC(:,r)=squeeze(Z(:,:,r))*eof.rho(:,M-r+1)/M;
	end
end
function [eof]=Toep_cov(in,dims)
	%lag
	M=dims(4,1);
	%autocorrelation
	C=autocorr(in,M-1);
	%toeplitz form
	C=toeplitz(C);
	%EOFs
	[rho,lambda]=eig(C);
	lambda=diag(lambda);
	%Y
	[I,~]=size(in);
	Y=zeros(I,M);
	[~,L]=size(Y);
	for x=1:L
		Y(1:end-x+1,x)=in(x:end);
	end
	%% build principal components
	eof.PC=Y*rho;
	%% pack bag
	eof.Y=Y;
	eof.C=C;
	eof.rho=rho;
	eof.lambda=lambda;
end
function [D]=lat_weighted_mean(D)
	D.cut.sstW=nan(size(D.cut.sst));
	%% create weight
	D.weight=nan(D.dim.cut.y,D.dim.cut.x);
	for y=1:D.dim.cut.y
		D.weight(y,:)=cosd(D.cut.lat(y));
	end
	%% "total number" of values
	N=nansum(D.weight(:));
	for t=1:D.dim.cut.t
		% kill land
		D.weight(isnan(squeeze(D.cut.sst(t,:,:))))=nan;
		% weighted in
		D.cut.sstW(t,:,:)=squeeze(D.cut.sst(t,:,:)).*D.weight;
		% build mean
		D.cut.sstm(t)=nansum(nansum(D.cut.sstW(t,:,:)))/N;
	end
end
function [D]=cutPiece(D,S,T)
	D.cut.sst=D.sst(T.from:T.till,S.s:S.n,S.w:S.e);
	D.cut.lat=D.lat(S.s:S.n);
	D.cut.lon=D.lon(S.w:S.e)- 180;
	[D.dim.cut.t,D.dim.cut.y,D.dim.cut.x]=size(D.cut.sst);
end
function [T]=getTime(timein,ds,dims)
	% get time info, ask time window
	% time(f:t)
	disp('getting time..')
	T.time=timein+datenum(ds,'yyyymmdd');
	disp(['data spans ',datestr(T.time(1)),' through ',datestr(T.time(end))])
	disp('reading time coordinates from input file..')
	from=datenum(num2str(dims(1,1)),'yyyymm');
	till=datenum(num2str(dims(1,2)),'yyyymm');
	disp([datestr(from),' till ',datestr(till)])
	[~,T.from]=min(abs(T.time-from));
	[~,T.till]=min(abs(T.time-till));
	T.time=T.time(T.from:T.till);
end
function D=readData(nc)
	%% read data
	nc.info=nc_info(nc.file);
	D.lon=double(nc_varget(nc.file,nc.lon));
	D.lat=double(nc_varget(nc.file,nc.lat));
	D.time=nc_varget(nc.file,nc.time);
	D.sst=nc_varget(nc.file,nc.var);
	[D.dim.t,D.dim.y,D.dim.x]=size(D.sst);
	%make flag nan
	D.sst=flag2nan(D.sst,max(D.sst(:)));
end
function printall2eps
	%prints all figures into current dir as .eps
	figs = findobj('Type','figure');
	for l=1:length(figs)
		eval(['print -f', num2str(figs(l)),' -r400 -depsc figure_',num2str(figs(l)),'.eps;'])
	end
	close all
	system('evince ./*.eps');
end
function [S]=getspace(D,dims)
	disp('organizing space stuff..')
	D.lon=D.lon-180;
	south=D.lat(1); north=D.lat(end); west=D.lon(1); east=D.lon(end);
	disp(['data spans from ',num2str(south),' south to ',num2str(north),...
		' north and from ',num2str(west),' west to ',num2str(east),' east ',...
		'at a resolution of ', num2str(length(D.lat)), ' x ',num2str(length(D.lon))])
	disp('reading space coordinates from input file..')
	so=dims(2,1);
	no=dims(2,2);
	we=dims(3,1);
	ea=dims(3,2);
	disp('finding best fit..')
	[~,S.s]=min(abs(D.lat-so));
	[~,S.n]=min(abs(D.lat-no));
	[~,S.w]=min(abs(D.lon-we));
	[~,S.e]=min(abs(D.lon-ea));
	%%
	windowlat=[linspace(so,no,100),no*ones(1,100),linspace(no,so,100),so*ones(1,100)];
	windowlon=[we*ones(1,100),linspace(we,ea,100),ea*ones(1,100),linspace(ea,we,100)];
	disp('creating snapshot..')
	fig=figure('Color','white');
	axesm hatano;
	coast = load('coast');
	axis on; framem on; gridm on; hold on;
	plotm(coast.lat,coast.long)
	plotm(windowlat,windowlon,'r')
	title('close this depiction of the window you have chosen')
	tightmap
	waitfor(fig)
end
function plotStuff(eof,RC,D,T)
	figure(1)
	lamnrmd=flipud(eof.lambda./sum(eof.lambda))*100;
	if length(lamnrmd)<30
		semilogy(lamnrmd,'*')
	else
		semilogy(lamnrmd(1:30),'*')
	end
	hold on
	semilogy(lamnrmd(1:4),'*r')
	text(5,4, ['sum over first 4 =',...
		num2str(round(sum(eof.lambda(end-3:end))/sum(eof.lambda)*100)),' %']...
		,'fontsize',12)
	ylabel('%')
	title('\lambda')
	set(gca,'xtick',[]);
	set(gca,'xticklabel',{});
	%%
	pm=0;
	L=9;
	for s=1:L
		figure(10)
		subplot(3,3,s)
		plot(T.time,RC(:,s),'color',rainbow(1,1,1,s,L))
		axis([T.time(1) T.time(end) floor(min(RC(:,s))*100)/100 ceil(max(RC(:,s))*100)/100])
		set(gca,'xtick',[T.time(1) T.time(1)+50*365+1 T.time(1)+100*365+1 T.time(end)])
		if s==1
			set(gca,'xticklabel',{datestr(T.time(1),'mm/yyyy') '+50a' ' '  datestr(T.time(end),'mm/yyyy') })
		else
			set(gca,'xticklabel',{})
		end
		set(gca,'ytick',[round(min(RC(:,s))*100)/100 round(max(RC(:,s))*100)/100 ])
		figure(100)
		plot(T.time,RC(:,s),'color',rainbow(1,1,1,s,L))
		axis([T.time(1) T.time(end) min(RC(:)) max(RC(:))])
		hold on
		figure(4)
		[pf,freq]=fourierm(RC(:,s),T.time);
		loglog(freq,pf,'color',rainbow(1,1,1,s,L)); %% plot on s
		hold on
		if max(pf)>pm
			pm=max(pf);
		end
	end
	figure(4)
	set(gca, 'xtick', [1/50,1/23,1/10,1/5.5 ,1/1])
	set(gca, 'xticklabel', {'1/50a','1/23a','1/10a','1/5.5a','1/1a'})
	axis([freq(1) freq(end) 0 pm])
	ylabel('(K months)^2')
	figure(100)
	ylen=365.25;
	xt=round((T.time(1)+4*ylen:ylen*10:T.time(end)));
	set(gca,'xtick',xt)
	set(gca,'xticklabel',datestr(xt,'yy'))
	set(gca,'ytick',[-.1 0 .1])
	
	%%
	figure(2)
	da=sum(RC(:,1:2),2);
	plot(T.time,detrend(D.cut.sstm),'r');
	hold on
	plot(T.time,da);
	axis([T.time(1) T.time(end) min(D.cut.sstm) max(D.cut.sstm)])
	set(gca,'xtick',xt)
	set(gca,'xticklabel',datestr(xt,'yy'))
	ylabel('K')
	title('sum of first 2 RCs')
	
end
function [colors]=rainbow(R, G, B, l, L)
	om=2*pi/L;
	red=R*sin(l*om-2*pi*(0/3));
	green=G*sin(l*om-2*pi*(1/3));
	blue=B*sin(l*om-2*pi*(2/3));
	colors=[red green blue]/2+.5;
end
function in=flag2nan(in,fl)
	disp('making flags nan..')
	in(in==fl)=nan;
end

