%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Created: 17-Jul-2014 23:52:44
% Computer:  GLNX86
% Matlab:  7.9
% Author:  NKkk

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  maxOWprocessInit
	dbstop if error
	try
		load DD
	catch yo
		disp(yo)
		DD=initialise([],mfilename);
		save DD
	end
	NC=initNC(DD);	
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NC=initNC(DD)
	file2dimname=@(f) getfield(nc_getvarinfo(f,'OkuboWeiss'),'Dimension');
	file2dimnum=@(f) getfield(nc_getvarinfo(f,'OkuboWeiss'),'Size');
	%%
	NC.outdir=DD.path.OkuboWeiss.name;
	NC.geo= [DD.path.OkuboWeiss.name 'LatLonDepth.nc'];
	NC.files=dir([DD.path.OkuboWeiss.name,'OW_*.nc']);
	for cc=1:numel(NC.files)
		NC.files(cc).full= [DD.path.OkuboWeiss.name NC.files(cc).name];
	end
	smple=NC.files(1).full;
	NC.Sname=cell2struct(file2dimname(smple),{'Z','Y','X'},2);
	NC.S=cell2struct(num2cell(file2dimnum(smple)),{'Z','Y','X'},2);
	NC.S.T = numel(NC.files);
	%%
	S=cell2mat(struct2cell(NC.S))';
	NC.new.dimName = {'t_index','j_index','i_index' };
	NC.new.dimNum  = S([4 2 3]);
	NC.new.minOW.varName     =  'log10 of vertical minimum of Okubo-Weiss';
	NC.new.minOW.fileName    =  [NC.outdir 'minOW.nc'];
	NC.new.minOWzi.varName   =  'z(log10(min(Okubo-Weiss,z)))';
	NC.new.minOWzi.fileName  =  [NC.outdir 'zOfminOW.nc'];
	
	NC.new.OWmean.varName     =  'time mean of OW';
	NC.new.OWmean.fileName    =  [NC.outdir 'OWmean.nc'];
	%% init
	NC.iniNewNC = @(n,f,D,Dn) initNcFile(n.(f).fileName,n.(f).varName,D,Dn);
	try NC.iniNewNC(NC.new,'minOWzi',NC.new.dimNum,NC.new.dimName);
	catch NCexist;		disp(NCexist);	end
	try NC.iniNewNC(NC.new,'minOW',  NC.new.dimNum,NC.new.dimName);
	catch NCexist;		disp(NCexist);	end
	
	try NC.iniNewNC(NC.new,'OWmean',  {'k_index','j_index','i_index' } ,[NC.S.Z NC.S.Y NC.S.X]);
	catch NCexist;		disp(NCexist);	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function daily=initDaily(NC,tt)
	daily.minOWzi.varName = NC.new.minOWzi.varName;
	daily.minOW.varName   = NC.new.minOW.varName;
	daily.minOWzi.fileName =  sprintf('%s%s_%04d.nc',NC.outdir,NC.new.minOWzi.fileName,tt);
	daily.minOW.fileName   =  sprintf('%s%s_%04d.nc',NC.outdir, NC.new.minOW.fileName ,tt);
	%%
	NC.iniNewNC(daily,'minOWzi',NC.new.dimNum(2:end),NC.new.dimName(2:end));
	NC.iniNewNC(daily,'minOW',  NC.new.dimNum(2:end),NC.new.dimName(2:end));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function spmdBcalc(NC)
	f=funcs;
	ncPut=@(n,f,data)  nc_varput(n.(f).fileName ,n.(f).varName,data);
	ncPutBig=@(n,f,data,t,s)  nc_varput(n.(f).fileName ,n.(f).varName,data,[t,0,0],[1 s.Y s.X]);
	%% get bathymetry
	bath=getBathym(nc_varget(NC.files(1).full,'OkuboWeiss'));
	%%
	OWmean=makeOWmean(f,NC);
	%%
	T=disp_progress('init','min OW''s')  ;
	for tt=1:NC.S.T
		T=disp_progress('show',T,NC.S.T);
		try daily=initDaily(NC,tt); catch exst; disp(exst); continue; end
		%% get min in z
		
		[owMin,MinZi]=spmdBlck(NC.files(tt).full,bath,f,OWmean);
		%% write daily
		ncPut(daily,'minOWzi',MinZi);
		ncPut(daily,'minOW',owMin);
		%% put to big files too
		ncPutBig(NC.new,'minOWzi',MinZi,tt-1,NC.S);
		ncPutBig(NC.new,'minOW',owMin,tt-1,NC.S);
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function logOwMean=makeOWmean(f,NC)
	T=disp_progress('init','calcing hor means of OW')  ;
	spmd
		logOwSum=f.ncvOne(nan(NC.S.Z,NC.S.Y,NC.S.X),3);
	end
	for tt=1:NC.S.T
		T=disp_progress('show',T,NC.S.T);
		%% get min in z
		spmdmDnansumlog=@(old,new)  multiDnansum(old, log10OW(new,nan));
		spmd
			newOw=f.ncvOne(nc_varget(NC.files(tt).full,'OkuboWeiss'),3);
			logOwSum=spmdmDnansumlog(logOwSum,newOw);
		end
	end
	spmd
		logOwMean=logOwSum/NC.S.T;
		logOwMeanCat=f.gCat(logOwMean);
	end
	nc_varput(NC.new.OWmean.fileName ,NC.new.OWmean.varName,logOwMeanCat{1});
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [bath]=getBathym(OW)
	[Z,Y,X]=size(OW);
	OW2d=reshape(OW,[Z,Y*X]);
	[~,bathUpdown]=min(isnan(flipud(OW2d)),[],1);
	spmd
		bath=f.ncvOne(reshape( Z-bathUpdown + 1, [Y,X]),2);
	end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=funcs
	f.ncvOne = @(A,dim) getLocalPart(codistributed(A,codistributor1d(dim)));
	
	f.gCat = @(a,dim) gcat(squeeze(a),dim,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [OW]=log10OW(OW,dummy)
	tag=isnan(OW) | isinf(OW) | OW>=0;
	OW(tag)=dummy;
	OW=log10(-OW);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [owMin,MinZi]=spmdBlck(currFile,mybath,f,OWmean)
	nanmaxFrom2toFloor = @(OW,bath) nanmax(OW(2:bath-1,:,:),[], 1);
	spmd
		mydata= 	f.ncvOne(log10OW(nc_varget(currFile,'OkuboWeiss'),nan),3);
		[owMin,MinZi]=nanmaxFrom2toFloor(mydata./OWmean,mybath);
		MinZi=f.gCat(MinZi-1,2); % correct for (2: ...)
		owMin=f.gCat(owMin,2);
	end
	MinZi=MinZi{1};
	owMin=owMin{1};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initNcFile(fname,toAdd,WinSize,dimName)
	nc_create_empty(fname,'noclobber');
	varstruct.Name = toAdd;
	varstruct.Nctype = 'double';
	for ww=1:numel(WinSize)
		nc_adddim(fname,dimName{ww},WinSize(ww));
	end
	varstruct.Dimension = dimName;
	nc_addvar(fname,varstruct)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%







%
%
%     %% focus on strong neg. okubo weiss
%     clean=OWall.ow < 5*nanmean(OWall.ow(:));
%     OWall.ow(~clean) = nan;
%     OWall.zi(~clean) = nan;
%     %% ow weighted mean of zi
%     OWall.owSum      = repmat(nansum(OWall.ow,1),[NC.S.T,1,1]);
%     OWall.ziWeighted = OWall.ow.*OWall.zi./OWall.owSum;
%     OWall.meaned.z           = squeeze(nansum(OWall.ziWeighted, 1));
%     OWall.meaned.ow          = squeeze(nanmean(OWall.ow, 1));
%     flgd=~squeeze(nansum(clean,1));
%     [y,x]=size(OWall.meaned.z);
%     [Xq,Yq]=meshgrid(1:x,1:y);
%     Xfl=Xq;Yfl=Yq;
%     Xfl(flgd)=[];
%     Yfl(flgd)=[];
%     vq = griddata(Xfl,Yfl,OWall.meaned.z(~flgd),Xq,Yq);
%     OWall.ziIntrl=round(smooth2a(NeighbourValue(isnan(vq),vq),10));
%     %    pcolor(vqn);
%     %    colorbar;
%
%     allOW=OWall.ow;
%     depthOW=OWall.depth;
%     ziOW=OWall.zi;
%     ziIntrp=OWall.ziIntrl;
%     ziWeighted=OWall.ziWeighted;
%
%
%     save('allOW.mat','allOW','-v7.3')
%     save('zi.mat','ziOW','-v7.3')
%     save('ziItnrp.mat','ziIntrp','-v7.3')
%     save('ziWeighted.mat','ziWeighted','-v7.3')
%
%
%
%


