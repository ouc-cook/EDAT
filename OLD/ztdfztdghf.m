D=dir('./')

for d=3:numel(D)-2
   t=load(D(d).name) 
%    x{d-2}=extractfield(cat(1,t.track.trackref),'x');
%    y{d-2}=extractfield(cat(1,t.track.trackref),'y'); 
   
   lo{d-2}=extractfield(cat(1,t.track.geo),'lon');
    la{d-2}=extractfield(cat(1,t.track.geo),'lat');
   
 
end


for d=1:numel(D)-2
%     plot(x{d},y{d});
%     hold on
%     
      plot(wrapTo180( lo{d}),la{d},'*');
    hold on
end


%%


D=dir('./')

for d=3:numel(D)-2
   t=load(D(d).name) 
%    x{d-2}=extractfield(cat(1,t.AntiCycs.trackref),'x');
%    y{d-2}=extractfield(cat(1,t.AntiCycs.trackref),'y');
   
   
   x{d-2}=extractfield(cat(1,t.AntiCycs.geo),'lon');
   y{d-2}=extractfield(cat(1,t.AntiCycs.geo),'lat');

end

close all
for d=1:numel(x)
    plot(wrapTo180( x{d}),y{d},'*');
    hold on    
end
















