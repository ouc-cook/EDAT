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
	NC=initNC(DD);	 %#ok<NASGU>
	save NC
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function NC=initNC(DD)
	file2dimname=@(f) getfield(nc_getvarinfo(f,'OkuboWeiss'),'Dimension');
	file2dimnum=@(f) getfield(nc_getvarinfo(f,'OkuboWeiss'),'Size');
	%%
	NC.outdir=DD.path.OkuboWeiss.name;
	NC.geo= [DD.path.OkuboWeiss.name 'LatLonDepth.nc'];
	
	geo.depth=nc_varget(NC.geo,'depth');
	geo.lon=nc_varget(NC.geo,'lon');
	geo.lat=nc_varget(NC.geo,'lat');
	
	
	
	
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
	NC.new.minOW.varName     =  'minOkuWeiss';
	NC.new.minOW.fileName    =  [NC.outdir 'minOW.nc'];
	NC.new.minOWzi.varName   =  'zi-ofMinOkuWeiss';
	NC.new.minOWzi.fileName  =  [NC.outdir 'zOfminOW.nc'];
	NC.new.owYref.varName   =  'owAtYref';
	NC.new.owYref.fileName  =  [NC.outdir 'owYref.nc'];
	NC.new.owXYref.varName   =  'owAtXYref';
	NC.new.owXYref.fileName  =  [NC.outdir 'owXYref.nc'];
	
	
	NC.new.OWmean.varName     =  'time-mean-of-OW';
	NC.new.OWmean.fileName    =  [NC.outdir 'OWmean.nc'];
	
	
	%% init
	NC.iniNewNC = @(n,f,D,Dn,geo) initNcFile(n.(f).fileName,n.(f).varName,D,Dn,geo);
	
	NC.iniNewNC(NC.new,'minOWzi',NC.new.dimNum,NC.new.dimName,geo);
	NC.iniNewNC(NC.new,'minOW',  NC.new.dimNum,NC.new.dimName,geo);
	NC.iniNewNC(NC.new,'OWmean' ,[NC.S.Z NC.S.Y NC.S.X],  {'k_index','j_index','i_index' },geo);
	NC.iniNewNC(NC.new,'owYref' ,[NC.S.T NC.S.Z NC.S.X],  {'t_index','k_index','i_index' },geo);
	NC.iniNewNC(NC.new,'owXYref' ,[NC.S.T NC.S.Z NC.S.X],  {'t_index','k_index','i_index'},geo);
	
	NC.funcs=funcs;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function f=funcs
	f.ncvOne = @(A,dim) getLocalPart(codistributed(A,codistributor1d(dim)));
	f.gCat = @(a,dim) gcat(squeeze(a),dim,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function initNcFile(fname,toAdd,WinSize,dimName,geo)
	nc_create_empty(fname,'clobber');
	varstruct.Name = toAdd;
	varstruct.Nctype = 'double';
	for ww=1:numel(WinSize)
		nc_adddim(fname,dimName{ww},WinSize(ww));
	end
	varstruct.Dimension = dimName;
	nc_addvar(fname,varstruct)
	
	if ~isempty(geo)
		try
			try %#ok<*TRYNC>
				nc_adddim(fname,'k_index',numel(geo.depth));
			end
			varstruct.Name = 'depth';
			varstruct.Nctype = 'single';
			varstruct.Dimension = {'k_index'};
			nc_addvar(fname,varstruct)
			nc_varput(fname,'depth',single(geo.depth));
		end
		try
			try
				nc_adddim(fname,'j_index',size(geo.lat,1));
			end
			try
				nc_adddim(fname,'i_index',size(geo.lat,2));
			end
			varstruct.Name = 'lat';
			varstruct.Nctype = 'single';
			varstruct.Dimension = {'j_index','i_index'};
			nc_addvar(fname,varstruct)
			nc_varput(fname,'depth',single(geo.lat))
			
			varstruct.Name = 'lon';
			varstruct.Nctype = 'single';
			varstruct.Dimension = {'j_index','i_index'};
			nc_addvar(fname,varstruct)
			nc_varput(fname,'depth',single(geo.lon))
		end
	end
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


