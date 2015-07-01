load CUT_19091231_+10s+47n+00w+28e
%%
ssh=grids.ssh(20:90,70:130)*30
%%
zz=7;
slice=ones(size(ssh))*zz;
%%
%  set(gcf,'Renderer','painter')
clf
surf(ssh,'FaceColor','interp','FaceLighting','phong')
% alpha(.5)
axis tight equal
% 

grid on
  view(3)
    camlight left
      set(gcf,'Renderer','zbuffer')
         set(gcf,'Renderer','opengl')
    
    
    hold on
  
    
  %%
sl=surf(slice,'EdgeColor','none')
alpha(sl,.6)
%%
hold on
cont=contourc(ssh,[zz zz])

ll=1
while true
   try
    len=cont(2,ll)
  
   x=cont(1,ll+1:ll+len)
   y=cont(2,ll+1:ll+len)
 
   plot3(x,y,ones(size(x))*zz,'linewidth',3)
   ll=ll+len+1
  catch
      break
  end
   
end
%%
set(gca,'zticklabel','','xticklabel','','yticklabel','')
set(gca,'ztick',zz)
set(gca,'zticklabel',sprintf('z= %+2.1f',zz))
% 
% 
% 
% fname=sprintf('slice%03d',zz)
%  eval(['print ',[fname,'.eps'] , ' -f -r',num2str(72),' -depsc ;'])
%         system(['epstopdf ' fname '.eps']);
%         system(['rm ' fname '.eps']);
% savefig('./',72,800,600, )
% 
% 
% 
% 
% 
% 
% 






















