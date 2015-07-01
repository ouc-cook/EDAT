%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 16-Jul-2014 13:52:44
% Computer:GLNX86
% Matlab:7.9
% Author:NK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function maxOWcalc
	load DD
  
     DD.MD=initbuildRho(DD);
       DD.MD.sMean = initbuildRhoMean(DD.path.TSow); %#ok<NODEF>
	DD=main(DD,DD.MD,funcs,DD.raw);
	save DD
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s] = initbuildRhoMean(TSow); dF
    %% recheck
    s.files=dir2cell(TSow.dir, 'rho_*.nc');
    s.Fout=[TSow.dir 'RHOmean.nc'];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function DD=main(DD,MD,f,raw);dF
	T=disp_progress('init','building okubo weiss netcdfs')  ;
	tFN=OWinit(MD.sMean.Fout,raw,f,DD.Dim.ws);
	toAdd={'OkuboWeiss','log10NegOW'};
	for tt = MD.timesteps;
		T=disp_progress('show',T,numel(MD.timesteps),numel(MD.timesteps));
		if ~exist(MD.OWFout{tt},'file')
			tmpFile=[MD.OWFout{tt} 'tmp'];
			loop(f,toAdd,MD.Fout{tt},tmpFile);
			system(['mv ' tmpFile ' ' MD.OWFout{tt}])
		end
	end
	for tfn=1:numel(tFN)
		delete(tFN{tfn})
	end
end
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [s] = initbuildRho(DD);  dF
    s.timesteps= DD.TSow.lims.timesteps;
    s.keys = DD.TS.keys;
    s.Fin = DD.path.TSow.files;
    s.dirOut=DD.path.full3d.name;
    s.Fout=DD.path.TSow.rho;
    s.OWFout=DD.path.TSow.OW;
    s.geoOut=DD.path.TSow.geo;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function loop(f,tA,currFile,OWFile);dF
	OW=extrOW(f,currFile);
	initOWNcFile(OWFile,tA,size(OW));
	f.ncVP(OWFile,OW,tA{1});
	OW(isinf(OW) | OW>=0 | isnan(OW) )=nan;	
	f.ncVP(OWFile,log10(-OW),tA{2});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  tFN=OWinit(MeanFile,raw,f,dim);dF
	zsplit=diff(round(linspace(0,dim(1),matlabpool('size')+1)));
	spmd(matlabpool('size'))
		threadFname=sprintf('thread%02d.mat',labindex);
		if ~exist(threadFname,'file')
			dumpmatfile(threadFname,MeanFile,raw,f,zsplit);
		end
		tFN=gop(@vertcat,{threadFname},1);
		labBarrier
	end
	tFN=tFN{1};
end
function dumpmatfile(threadFname,MeanFile,raw,f,zsplit)
	[Y,X]=size(raw.lat);
	my = matfile(threadFname,'Writable',true);
	my.threadFname=threadFname;
	my.zsplit=zsplit;
	my.codisp = codistributor1d(1, zsplit);
	my.RhoMean=f.getHP(MeanFile,f,'RhoMean',my.codisp);
	my.Z=size(my.RhoMean,1);
	my.dx=single(raw.dx); %#ok<*NASGU>
	my.dy=single(raw.dy);
	my.GOverF=single(raw.corio.GOverF);
	my.depth=f.locCo(f.repinYX(raw.depth,Y,X),my.codisp);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OW=extrOW(f,cF);dF	
    spmd(matlabpool('size'))
		fname=sprintf('thread%02d.mat',labindex);
		my = matfile(fname,'Writable',true);
		dispM('filtering high pass rho')
		rhoNow=f.getHP(cF,f,'density',my.codisp);
		labBarrier;
		my.rhoHighPass=rhoNow - my.RhoMean;
	end
	clear rhoNow my
	spmd(matlabpool('size'))
		my = matfile(fname,'Writable',true);
		getVels(fname,f);	labBarrier;
		uvg=UVgrads(fname,f.repinZ);
% 		ow = f.vc2mstr(okuweiss(uvg),1);	labBarrier
    end
    
    ow = f.vc2mstr(okuweiss(uvg),1);	labBarrier
    OW=ow{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ow = okuweiss(uvg);dF
%     % technically all the same, assuming 2d
%     defo.vorticity = uvg.dVdx - uvg.dUdy;
%     defo.shear = uvg.dVdx + uvg.dUdy;
%     defo.divergence = 0;
%     defo.stretch = - 2* multiDnansum(uvg.dVdy,uvg.dUdx)/2;
%     defo.divergence = uvg.dUdx + uvg.dVdy;
%     defo.stretch = uvg.dUdx - uvg.dVdy;
%     ow = (-(d.vorticity).^2+d.divergence.^2+d.stretch.^2+d.shear.^2)/2;%
%     ow =  2*(uvg.dVdx.*uvg.dUdy + uvg.dUdx.*uvg.dVdy)  ;  
    ow =  2*(uvg.dVdx.*uvg.dUdy + uvg.dUdx.^2);    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function uvg = UVgrads(fname,repinZ);dF
	m=matfile(fname);
	dd.y= @(in)  diff(in,1,2);
	dd.x= @(in)  diff(in,1,3);
	uvg = getuvg(m.U,m.V,m.dy,m.dx,dd,repinZ,m.Z);
end
function uvg=getuvg(u,v,dy,dx,dd,repinZ,z);dF
	uvg.dUdy = inxOry(dd.y(u),'y',dy,z,repinZ);
	uvg.dUdx = inxOry(dd.x(u),'x',dx,z,repinZ);
	uvg.dVdy = inxOry(dd.y(v),'y',dy,z,repinZ);
	uvg.dVdx = inxOry(dd.x(v),'x',dx,z,repinZ);
end
function out=inxOry(in,inxy,dxy,z,repinZ);dF
	denom=repinZ(dxy,z);
	if     strcmp(inxy,'y')
		out=in( :,[1:end, end], : )./denom;
	elseif strcmp(inxy,'x')
		out= in(:, :,[1:end, end])./denom;
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function getVels(fname,f);dF
	m = matfile(fname,'Writable',true);
	dispM('getting UV')
	rhoNill = 1000;
	dRho = getDrhodx(m.rhoHighPass,m.dx,m.dy,m.Z,f.repinZ);
	gzOverRhoF = (f.repinZ(m.GOverF,m.Z) .* m.depth) / rhoNill;
	m.U = -dRho.dy .* gzOverRhoF;
	m.V = dRho.dx .*  gzOverRhoF;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dRho = getDrhodx(rHP,dx,dy,Z,repinZ);dF
	%% calc density gradients
	drdx = diff(rHP,1,3);
	drdy = diff(rHP,1,2);
	dRho.dx = drdx(:,:,[1,1:end]) ./ repinZ(dx,Z);
	dRho.dy = drdy(:,[1,1:end],:) ./ repinZ(dy,Z);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initOWNcFile(fname,toAdd,WinSize);dF
	nc_create_empty(fname,'clobber');
	nc_adddim(fname,'k_index',WinSize(1));
	nc_adddim(fname,'i_index',WinSize(3));
	nc_adddim(fname,'j_index',WinSize(2));
	%%
	for kk=1:numel(toAdd)
		ta=toAdd{kk};
		varstruct.Name = ta;
		varstruct.Nctype = 'single';
		varstruct.Dimension = {'k_index','j_index','i_index' };
		nc_addvar(fname,varstruct)
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=funcs
	f.ncv=@(d,field) nc_varget(d,field);
	f.repinYX = @(A,Y,X) repmat(reshape(A(:),[],1),[1,Y,X]);
	f.repinZ = @(A,z) repmat(permute(A,[3,1,2]),[z,1,1]);
	f.ncVP = @(file,OW,field)  nc_varput(file,field,single(OW));
	f.vc2mstr=@(ow,dim) gcat(ow,dim,1);
	f.locCo = @(x,cod) getLocalPart(codistributed(x,cod));
	f.getHP = @(cf,f,fi,cod) single(f.locCo(f.ncv(cf,fi),cod));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
