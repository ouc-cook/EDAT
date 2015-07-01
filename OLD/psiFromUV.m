
function psiFromUV
    DD=initialise([],mfilename);
    uvPath= '/scratch/uni/ifmto/u300065/PUBLIC/STrhoP9495/';
   uvmPath= '/scratch/uni/ifmto/u241194/DAILY/EULERIAN/MEANS/';
    
    Fs.v=dir([uvPath 'VVEL*.nc']);
    Fs.u=dir([uvPath 'UVEL*.nc']);
   Me.u=dir([uvmPath 'UVEL*94*.nc']);
      Me.v=dir([uvmPath 'VVEL*94*.nc']);
    
    W.x=500:600;
    W.y=500:600;
    gW=@(M,W) M(W.y,W.x);
    ii=1;
    V.fname=[uvPath Fs.v(ii).name];
    U.fname=[uvPath Fs.u(ii).name];
    
    lat=gW(nc_varget(V.fname,'U_LAT_2D'),W);
    lon=gW(nc_varget(V.fname,'U_LON_2D'),W);
   
    
   
    
    
    
    
    [Y,X]=size(lat);
    dx=deg2km(diff(lon,1,2))*1000.*cosd(lat(:,2:end));
    distX=[zeros(Y,1) ,cumsum(dx,2)];
    dy=deg2km(diff(lat,1,1))*1000;
    distY=cumsum([zeros(1,X) ;dy],1);
    
    [Xn,Yn]=meshgrid(0:10000:max(distX(:)),0:10000:max(distY(:)));
  
    
    pmr=@(m) permute(m,[3,1,2])
    cen=@(M) (M(2:end-1,2:end-1));
    lef=@(M) pmr(M(2:end-1,1:end-2));
    rig=@(M) pmr(M(2:end-1,3:end  ));
    top=@(M) pmr(M(3:end  ,2:end-1));
    bot=@(M) pmr(M(1:end-2,2:end-1));
    
    detr=@(m) detrend(detrend(m)')';
     gWz=@(M,W,z) permute(M(z,W.y,W.x),[2,3,1]) ;
   
       mV.fname=[uvmPath Me.v(1).name];
        mU.fname=[uvmPath Me.u(1).name];
       nc_dump(mV.fname)
        MVd=gWz(nc_varget(mV.fname,'VVEL'),W,zz);
       MUd=gWz(nc_varget(mU.fname,'UVEL'),W,zz);
        
    for ii=1:numel(Fs.v)
        V.fname=[uvPath Fs.v(ii).name];
        U.fname=[uvPath Fs.u(ii).name];
      
        
      
        
        mhx=@(M) M(:,[1 1:end]);
        mhy=@(M) M([1 1:end],:);
        psi=zeros(size(Yn));
        for zz=1:1%size(V.data,1)
            Vd=gWz(nc_varget(V.fname,'VVEL'),W,zz)-MVd;
            Ud=gWz(nc_varget(U.fname,'UVEL'),W,zz)-MUd; 
%          om=mhx(diff(detr(Vd),1,2)./dx) - mhy(diff(detr(Ud),1,1)./dy);
            om=mhx(diff((Vd),1,2)./dx) - mhy(diff((Ud),1,1)./dy);
           
    
            ow=-om.^2 + mhx(diff((Ud),1,2)./dx)
            
            ows=ow/std(ow(:));
            
            
            
            
            
            omN=griddata(double(distX(:)),double(distY(:)),double(om(:)),double(Xn(:)),double(Yn(:)));
%             ppc(reshape(omN,size(Xn)))
            omN=reshape(omN,size(Xn));
            
          psi(2:end-1,2:end-1)=  cen(omN) + permute(nansum([lef(psi);rig(psi);bot(psi);top(psi)]),[2,3,1]);
            ppc(psi)
        end
    end
end